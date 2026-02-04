///|
/// v2.2 API adapter (pure router) for effects plan/execute.

///|
pub(all) struct ApiRequest {
  http_method : String
  path : String
  body : String?
}

///|
pub(all) struct ApiResponse {
  status : Int
  body : String
  content_type : String
}

///|
fn response_json(status : Int, body : String) -> ApiResponse {
  { status, body, content_type: "application/json" }
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
fn reason_from_compile_error(err : @compiler.CompileError) -> @core.Reason {
  match err {
    @compiler.CompileError::ParseFailure(msg) =>
      @core.Reason::new("ParseFailure", msg)
    @compiler.CompileError::ResolveFailure(msg) =>
      if msg.has_prefix("rule name conflicts with builtin: ") {
        @core.Reason::with_context(
          "RESERVED_WORD_CONFLICT",
          msg,
          [
            ("target", "rule"),
            ("hint", "Builtin rule names are reserved"),
          ],
        )
      } else {
        @core.Reason::new("ResolveFailure", msg)
      }
    @compiler.CompileError::ValidationFailure(reason) => reason
  }
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
fn extract_input_field(obj : Map[String, Json]) -> Result[Map[String, Bool], @core.Reason] {
  match obj.get("input") {
    None => Ok(Map::new())
    Some(value) => @hypermedia.parse_rule_results(value.stringify())
  }
}

///|
fn extract_plan_field(obj : Map[String, Json]) -> Result[String, @core.Reason] {
  match obj.get("plan") {
    Some(value) => Ok(value.stringify(indent=2))
    None => Err(missing_field_reason("plan"))
  }
}

///|
fn plan_response(plan : @effects_v2_2.EffectsPlan) -> String {
  @effects_v2_2.effect_plan_json(plan).stringify(indent=2)
}

///|
fn execute_response(result : @effects_v2_2.ExecutionResult) -> String {
  @effects_v2_2.execution_result_json(result).stringify(indent=2)
}

///|
fn handle_plan(req : ApiRequest) -> ApiResponse {
  let body = match req.body {
    Some(value) => value
    None => return response_json(400, error_envelope_json(missing_field_reason("body")))
  }
  let obj = match extract_body_json(body) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let schema_text = match extract_string_field(obj, "schema") {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let entity_id = match extract_string_field(obj, "entityId") {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let state = match extract_string_field(obj, "state") {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let transition_id = match extract_string_field(obj, "transition") {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let input = match extract_input_field(obj) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let ir = match @compiler.compile_yaml(schema_text) {
    Ok(value) => value
    Err(err) => return response_json(400, error_envelope_json(reason_from_compile_error(err)))
  }
  match @runtime.execute_transition(ir, state, transition_id, input) {
    Ok(outcome) => {
      let plan = @effects_v2_2.plan_from_execution(entity_id, outcome)
      response_json(200, plan_response(plan))
    }
    Err(reason) => response_json(400, error_envelope_json(reason))
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
  let plan_text = match extract_plan_field(obj) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let plan = match @effects_v2_2.parse_plan_json(plan_text) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let result = @effects_v2_2.execute_plan_stub(plan)
  response_json(200, execute_response(result))
}

///|
pub fn handle_request(req : ApiRequest) -> ApiResponse {
  if req.http_method == "POST" && req.path == "/v2.2/effects/plan" {
    return handle_plan(req)
  }
  if req.http_method == "POST" && req.path == "/v2.2/effects/execute" {
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
        ("hint", "Use /v2.2/effects"),
      ],
    )),
  )
}
