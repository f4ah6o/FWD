///|
/// v4.2 metrics HTTP adapter (pure router).

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
fn response_html(status : Int, body : String) -> ApiResponse {
  let headers : Map[String, String] = Map::new()
  headers["content-type"] = "text/html"
  { status, headers, body }
}

///|
fn response_json(status : Int, body : String) -> ApiResponse {
  let headers : Map[String, String] = Map::new()
  headers["content-type"] = "application/json"
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

fn parse_format(value : String) -> String? {
  if value == "html" || value == "mx" {
    Some(value)
  } else {
    None
  }
}

fn metrics_view() -> @views.V4MetricsView {
  {
    window: { entity_id: "order-1", from_logical_time: 10, to_logical_time: 12 },
    total: { ok: 1, failed: 1, blocked: 0, denied: 1 },
    by_kind: [
      { kind: "transition", counts: { ok: 1, failed: 0, blocked: 0, denied: 0 } },
      { kind: "policy", counts: { ok: 0, failed: 0, blocked: 0, denied: 1 } },
      { kind: "effect", counts: { ok: 0, failed: 1, blocked: 0, denied: 0 } },
    ],
  }
}

///|
fn handle_metrics(req : ApiRequest) -> ApiResponse {
  let format = match req.query.get("format") {
    None => "html"
    Some(value) => match parse_format(value) {
      Some(kind) => kind
      None => return response_json(400, error_envelope_json(invalid_query_reason("invalid format")))
    }
  }
  if format == "mx" {
    return response_html(200, @views.render_metrics_html_v4_2_mx(metrics_view()))
  }
  response_html(200, @views.render_metrics_html_v4_2(metrics_view()))
}

///|
pub fn handle_request(req : ApiRequest) -> ApiResponse {
  if req.http_method == "GET" && req.path == "/v4.2/metrics" {
    return handle_metrics(req)
  }
  response_json(
    404,
    error_envelope_json(@core.Reason::with_context(
      "ROUTE_NOT_FOUND",
      "route not found",
      [
        ("target", "runtime"),
        ("level", "error"),
        ("hint", "Use /v4.2/metrics"),
      ],
    )),
  )
}
