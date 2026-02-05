///|
/// HTTP adapter v3.7 (pure request/response routing).

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
fn response_jsonl(status : Int, body : String) -> ApiResponse {
  let headers : Map[String, String] = Map::new()
  headers["content-type"] = "application/jsonl"
  { status, headers, body }
}

///|
fn error_envelope_json(reason : @core.Reason) -> String {
  let obj : Map[String, Json] = Map::new()
  obj["error"] = @compiler.reason_json(reason)
  Json::object(obj).stringify(indent=2)
}

///|
fn invalid_query_reason(message : String) -> @core.Reason {
  @core.Reason::with_context(
    "QUERY_INVALID",
    message,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Check query parameters"),
    ],
  )
}

///|
fn missing_query_reason(name : String) -> @core.Reason {
  @core.Reason::with_context(
    "QUERY_MISSING",
    "missing query: " + name,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Provide query '" + name + "'"),
    ],
  )
}

fn parse_int(value : String) -> Int? {
  if value.length() == 0 {
    return None
  }
  let mut acc = 0
  for i in 0..<value.length() {
    let ch = value[i].to_int()
    if ch < 48 || ch > 57 {
      return None
    }
    acc = acc * 10 + (ch - 48)
  }
  Some(acc)
}

fn build_snapshot(entity_id : String, from_time : Int?, to_time : Int?) -> @metrics_v3_6.MetricsSnapshot {
  {
    window: {
      entity_id,
      from_logical_time: from_time,
      to_logical_time: to_time,
    },
    total: {
      ok: 1,
      failed: 1,
      blocked: 0,
      denied: 1,
    },
    by_kind: [
      {
        kind: @metrics_v3_6.MetricKind::Transition,
        counts: { ok: 1, failed: 0, blocked: 0, denied: 0 },
      },
      {
        kind: @metrics_v3_6.MetricKind::Policy,
        counts: { ok: 0, failed: 0, blocked: 0, denied: 1 },
      },
      {
        kind: @metrics_v3_6.MetricKind::Effect,
        counts: { ok: 0, failed: 1, blocked: 0, denied: 0 },
      },
    ],
  }
}

///|
fn handle_export(req : ApiRequest) -> ApiResponse {
  let entity = match req.query.get("entityId") {
    Some(value) => value
    None => return response_json(400, error_envelope_json(missing_query_reason("entityId")))
  }
  let from_time = match req.query.get("fromLogicalTime") {
    Some(value) => match parse_int(value) {
      Some(v) => Some(v)
      None => return response_json(400, error_envelope_json(invalid_query_reason("fromLogicalTime must be integer")))
    }
    None => None
  }
  let to_time = match req.query.get("toLogicalTime") {
    Some(value) => match parse_int(value) {
      Some(v) => Some(v)
      None => return response_json(400, error_envelope_json(invalid_query_reason("toLogicalTime must be integer")))
    }
    None => None
  }
  let snapshot = build_snapshot(entity, from_time, to_time)
  response_jsonl(200, @metrics_export_v3_7.export_jsonl(snapshot))
}

///|
pub fn handle_request(req : ApiRequest) -> ApiResponse {
  if req.http_method == "GET" && req.path == "/v3.7/metrics/export.jsonl" {
    return handle_export(req)
  }
  response_json(
    404,
    error_envelope_json(@core.Reason::with_context(
      "ROUTE_NOT_FOUND",
      "route not found",
      [
        ("target", "runtime"),
        ("level", "error"),
        ("hint", "Use /v3.7/metrics/export.jsonl"),
      ],
    )),
  )
}
