///|
/// HTTP adapter v3.1 (pure request/response routing).

///|
pub(all) struct ApiRequest {
  http_method : String
  path : String
  query : Map[String, String]
  body : String?
}

///|
pub(all) struct ApiResponse {
  status : Int
  headers : Map[String, String]
  body : String
}

///|
fn response_json(status : Int, body : String) -> ApiResponse {
  let headers : Map[String, String] = Map::new()
  headers["content-type"] = "application/json"
  { status, headers, body }
}

///|
fn invalid_body_reason(message : String) -> @core.Reason {
  @core.Reason::with_context(
    "INPUT_JSON_INVALID",
    message,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Provide a JSON object body"),
    ],
  )
}

///|
fn missing_field_reason(name : String) -> @core.Reason {
  @core.Reason::with_context(
    "INPUT_MISSING",
    "missing field: " + name,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Provide field '" + name + "' in JSON body"),
    ],
  )
}

///|
fn error_envelope_json(reason : @core.Reason) -> String {
  let obj : Map[String, Json] = Map::new()
  obj["error"] = @compiler.reason_json(reason)
  Json::object(obj).stringify(indent=2)
}

///|
fn extract_body_json(body : String) -> Result[Map[String, Json], @core.Reason] {
  let parsed : Result[Json, @json.ParseError] = try? @json.parse(body)
  let value = match parsed {
    Ok(v) => v
    Err(err) =>
      return Err(
        invalid_body_reason("input json parse error: " + err.to_string()),
      )
  }
  match value {
    Object(m) => Ok(m)
    _ => Err(invalid_body_reason("input json must be an object"))
  }
}

///|
fn extract_string_field(
  obj : Map[String, Json],
  name : String,
) -> Result[String, @core.Reason] {
  match obj.get(name) {
    Some(String(value)) => Ok(value)
    Some(_) => Err(invalid_body_reason("field must be string: " + name))
    None => Err(missing_field_reason(name))
  }
}

///|
fn extract_int_field(
  obj : Map[String, Json],
  name : String,
) -> Result[Int, @core.Reason] {
  match obj.get(name) {
    Some(Number(value, ..)) => Ok(value.to_int())
    Some(_) => Err(invalid_body_reason("field must be number: " + name))
    None => Err(missing_field_reason(name))
  }
}

///|
fn extract_allowlist(obj : Map[String, Json]) -> Result[Array[String], @core.Reason] {
  match obj.get("allowlist") {
    Some(Array(values)) => {
      let list : Array[String] = []
      for value in values {
        match value {
          String(v) => list.push(v)
          _ => return Err(invalid_body_reason("allowlist must be string array"))
        }
      }
      if list.length() == 0 {
        return Err(invalid_body_reason("allowlist must not be empty"))
      }
      Ok(list)
    }
    Some(_) => Err(invalid_body_reason("allowlist must be array"))
    None => Err(missing_field_reason("allowlist"))
  }
}

///|
fn extract_plan(obj : Map[String, Json]) -> Result[@effects_v2_2.EffectsPlan, @core.Reason] {
  match obj.get("plan") {
    Some(value) => @effects_v2_2.parse_plan_json(value.stringify(indent=2))
    None => Err(missing_field_reason("plan"))
  }
}

///|
fn extract_idempotency(obj : Map[String, Json]) -> Result[@idempotency_v3.Decision, @core.Reason] {
  let key = match extract_string_field(obj, "key") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let kind_str = match extract_string_field(obj, "kind") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let logical_time = match extract_int_field(obj, "logicalTime") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let reserved_at = match extract_int_field(obj, "reservedAt") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let result_ref = match obj.get("resultRef") {
    Some(String(value)) => value
    Some(_) => return Err(invalid_body_reason("resultRef must be string"))
    None => ""
  }
  let kind = match kind_str {
    "reserved" => @idempotency_v3.DecisionKind::Reserved
    "conflict" => @idempotency_v3.DecisionKind::Conflict
    "done" => @idempotency_v3.DecisionKind::Done
    "already_done" => @idempotency_v3.DecisionKind::AlreadyDone
    _ => return Err(invalid_body_reason("unknown idempotency kind"))
  }
  Ok({
    key,
    kind,
    logical_time,
    reserved_at,
    result_ref,
  })
}

///|
fn fixed_retry_policy() -> @retry_policy_v3.RetryPolicy {
  {
    policy_version: @retry_policy_v3.policy_version_v3(),
    max_attempts: 3,
    backoff: {
      kind: @retry_policy_v3.BackoffKind::Fixed,
      delay_ms: 1000,
      factor: 1,
    },
  }
}

///|
fn handle_execute(req : ApiRequest) -> ApiResponse {
  let body = match req.body {
    Some(value) => value
    None => return response_json(400, error_envelope_json(missing_field_reason("body")))
  }
  let obj = match extract_body_json(body) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let plan = match extract_plan(obj) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let allowlist = match extract_allowlist(obj) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let idempotency_obj = match obj.get("idempotency") {
    Some(Object(map)) => map
    Some(_) => return response_json(400, error_envelope_json(invalid_body_reason("idempotency must be object")))
    None => return response_json(400, error_envelope_json(missing_field_reason("idempotency")))
  }
  let idempotency = match extract_idempotency(idempotency_obj) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let logical_time_start = match extract_int_field(obj, "logicalTimeStart") {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let fail_first = match obj.get("failFirst") {
    Some(True) => true
    Some(False) => false
    Some(_) => return response_json(400, error_envelope_json(invalid_body_reason("failFirst must be boolean")))
    None => false
  }
  let mut calls = 0
  fn send(_req : @effects_exec_adapters_v2_2.HttpRequest) -> Result[@effects_exec_adapters_v2_2.HttpResponse, @core.Reason] {
    calls = calls + 1
    if fail_first && calls == 1 {
      Err(@core.Reason::with_context("EFFECT_HTTP_FAILED", "HTTP request failed", [("target", "effect")]))
    } else {
      Ok({ status: 200, body: "" })
    }
  }
  let detail = @executor_v3_1.execute_plan_detail(
    plan,
    idempotency,
    fixed_retry_policy(),
    logical_time_start,
    allowlist,
    send,
  )
  response_json(200, @executor_v3_1.execution_detail_json(detail).stringify(indent=2))
}

///|
pub fn handle_request(req : ApiRequest) -> ApiResponse {
  if req.http_method == "POST" && req.path == "/v3.1/effects/execute" {
    return handle_execute(req)
  }
  response_json(
    404,
    error_envelope_json(@core.Reason::with_context(
      "ROUTE_NOT_FOUND",
      "route not found",
      [
        ("target", "runtime"),
        ("level", "error"),
        ("hint", "Use /v3.1/effects/execute"),
      ],
    )),
  )
}
