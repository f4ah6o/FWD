///|
/// HTTP adapter v3.8 (pure request/response routing).

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

fn parse_kind(value : String) -> String? {
  if value == "transition" || value == "effect" || value == "policy" {
    Some(value)
  } else {
    None
  }
}

fn events_for_entity(entity : String) -> Array[@timeline_v3.TimelineEvent] {
  [
    {
      entity_id: entity,
      logical_time: 10,
      sequence: 1,
      kind: @timeline_v3.TimelineKind::Transition,
      ref_id: "submit",
      status: "executed",
      reasons: [],
    },
    {
      entity_id: entity,
      logical_time: 11,
      sequence: 1,
      kind: @timeline_v3.TimelineKind::Policy,
      ref_id: "policy:submit",
      status: "deny",
      reasons: [
        @core.Reason::with_context(
          "POLICY_DENY",
          "Policy denied execution",
          [("target", "transition")],
        ),
      ],
    },
    {
      entity_id: entity,
      logical_time: 12,
      sequence: 1,
      kind: @timeline_v3.TimelineKind::Effect,
      ref_id: "http:archive",
      status: "failed",
      reasons: [
        @core.Reason::with_context(
          "EFFECT_HTTP_FAILED",
          "HTTP request failed",
          [("target", "effect")],
        ),
      ],
    },
  ]
}

fn apply_filter(
  events : Array[@timeline_v3.TimelineEvent],
  kind : String?,
) -> Array[@timeline_v3.TimelineEvent] {
  let filtered : Array[@timeline_v3.TimelineEvent] = []
  for event in events {
    match kind {
      None => filtered.push(event)
      Some(value) => {
        match (value, event.kind) {
          ("transition", @timeline_v3.TimelineKind::Transition) => filtered.push(event)
          ("effect", @timeline_v3.TimelineKind::Effect) => filtered.push(event)
          ("policy", @timeline_v3.TimelineKind::Policy) => filtered.push(event)
          _ => ()
        }
      }
    }
  }
  filtered
}

///|
fn handle_event_list(req : ApiRequest) -> ApiResponse {
  let entity = match req.query.get("entityId") {
    Some(value) => value
    None => return response_json(400, error_envelope_json(missing_query_reason("entityId")))
  }
  let kind = match req.query.get("kind") {
    Some(value) => match parse_kind(value) {
      Some(kind_value) => Some(kind_value)
      None => return response_json(400, error_envelope_json(invalid_query_reason("invalid kind")))
    }
    None => None
  }
  let limit = match req.query.get("limit") {
    Some(value) => match parse_int(value) {
      Some(v) => if v > 0 { v } else { return response_json(400, error_envelope_json(invalid_query_reason("limit must be positive"))) }
      None => return response_json(400, error_envelope_json(invalid_query_reason("limit must be integer")))
    }
    None => 2
  }
  let cursor_offset = match req.query.get("cursor") {
    Some(value) => match @timeline_event_v3_8.decode_cursor(value) {
      Some(v) => v
      None => return response_json(400, error_envelope_json(invalid_query_reason("invalid cursor")))
    }
    None => 0
  }
  let events = apply_filter(events_for_entity(entity), kind)
  let page : Array[@timeline_v3.TimelineEvent] = []
  let mut idx = 0
  for event in events {
    if idx >= cursor_offset && page.length() < limit {
      page.push(event)
    }
    idx = idx + 1
  }
  let next_cursor = if cursor_offset + limit < events.length() {
    Some(@timeline_event_v3_8.encode_cursor(@timeline_event_v3_8.cursor_from_query({
      entity_id: entity,
      kind,
      from_logical_time: None,
      to_logical_time: None,
      limit,
      cursor: None,
    }, cursor_offset + limit)))
  } else {
    None
  }
  response_html(
    200,
    @views.render_timeline_event_list_v3_8(entity, page, kind, limit, next_cursor),
  )
}

///|
pub fn handle_request(req : ApiRequest) -> ApiResponse {
  if req.http_method == "GET" && req.path == "/v3.8/timeline/events" {
    return handle_event_list(req)
  }
  response_json(
    404,
    error_envelope_json(@core.Reason::with_context(
      "ROUTE_NOT_FOUND",
      "route not found",
      [
        ("target", "runtime"),
        ("level", "error"),
        ("hint", "Use /v3.8/timeline/events"),
      ],
    )),
  )
}
