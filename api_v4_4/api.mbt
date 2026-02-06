///|
/// HTTP adapter v4.4 (metrics drilldown).

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

fn substring_from(value : String, start : Int) -> String {
  let sb = StringBuilder::new()
  for i in start..<value.length() {
    let ch = value[i].to_int()
    sb.write_char(Int::unsafe_to_char(ch))
  }
  sb.to_string()
}

fn metrics_view() -> @views.V4_4MetricsView {
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

fn kind_detail_view(kind : String) -> @views.V4_4MetricsDetailView {
  match kind {
    "transition" => { kind: "transition", counts: { ok: 1, failed: 0, blocked: 0, denied: 0 } }
    "policy" => { kind: "policy", counts: { ok: 0, failed: 0, blocked: 0, denied: 1 } }
    _ => { kind: "effect", counts: { ok: 0, failed: 1, blocked: 0, denied: 0 } }
  }
}

fn is_valid_kind(kind : String) -> Bool {
  kind == "transition" || kind == "policy" || kind == "effect"
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
    return response_html(200, @views.render_metrics_html_v4_4_mx(metrics_view()))
  }
  response_html(200, @views.render_metrics_html_v4_4(metrics_view()))
}

///|
fn handle_metrics_kind(req : ApiRequest, kind : String) -> ApiResponse {
  if !is_valid_kind(kind) {
    return response_json(400, error_envelope_json(invalid_query_reason("invalid kind")))
  }
  match req.query.get("format") {
    None => ()
    Some(value) => match parse_format(value) {
      Some("html") => ()
      Some(_) => return response_json(400, error_envelope_json(invalid_query_reason("invalid format")))
      None => return response_json(400, error_envelope_json(invalid_query_reason("invalid format")))
    }
  }
  response_html(200, @views.render_metrics_detail_html_v4_4(kind_detail_view(kind)))
}

///|
pub fn handle_request(req : ApiRequest) -> ApiResponse {
  if req.http_method == "GET" && req.path == "/v4.4/metrics" {
    return handle_metrics(req)
  }
  let prefix = "/v4.4/metrics/kind/"
  if req.http_method == "GET" && req.path.has_prefix(prefix) {
    let kind = substring_from(req.path, prefix.length())
    if kind.length() == 0 {
      return response_json(400, error_envelope_json(invalid_query_reason("invalid kind")))
    }
    return handle_metrics_kind(req, kind)
  }
  response_json(
    404,
    error_envelope_json(@core.Reason::with_context(
      "ROUTE_NOT_FOUND",
      "route not found",
      [
        ("target", "runtime"),
        ("level", "error"),
        ("hint", "Use /v4.4/metrics"),
      ],
    )),
  )
}
