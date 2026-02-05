///|
/// HTTP adapter v3.9 (pure request/response routing).

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
fn invalid_event_id_reason(message : String) -> @core.Reason {
  @core.Reason::with_context(
    "EVENT_ID_INVALID",
    message,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Use event id in the form entity:logical:sequence:kind"),
    ],
  )
}

///|
fn event_not_found_reason(event_id : String) -> @core.Reason {
  @core.Reason::with_context(
    "EVENT_NOT_FOUND",
    "event not found: " + event_id,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Provide a valid event id"),
    ],
  )
}

fn parse_format(value : String) -> String? {
  if value == "json" || value == "html" {
    Some(value)
  } else {
    None
  }
}

fn compare_string(a : String, b : String) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

fn compare_event(a : @timeline_v3.TimelineEvent, b : @timeline_v3.TimelineEvent) -> Int {
  let by_entity = compare_string(a.entity_id, b.entity_id)
  if by_entity != 0 {
    return by_entity
  }
  if a.logical_time < b.logical_time {
    return -1
  } else if a.logical_time > b.logical_time {
    return 1
  }
  if a.sequence < b.sequence {
    return -1
  } else if a.sequence > b.sequence {
    return 1
  }
  0
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

fn find_index(sorted : Array[@timeline_v3.TimelineEvent], event_id : String) -> Int? {
  for i in 0..<sorted.length() {
    if @timeline_event_v3_4.event_id(sorted[i]) == event_id {
      return Some(i)
    }
  }
  None
}

fn substring_from(value : String, start : Int) -> String {
  let sb = StringBuilder::new()
  for i in start..<value.length() {
    let ch = value[i].to_int()
    sb.write_char(Int::unsafe_to_char(ch))
  }
  sb.to_string()
}

///|
fn handle_event(req : ApiRequest, event_id : String) -> ApiResponse {
  let format = match req.query.get("format") {
    None => "html"
    Some(value) => match parse_format(value) {
      Some(kind) => kind
      None => return response_json(400, error_envelope_json(invalid_event_id_reason("invalid format")))
    }
  }
  let parts = @timeline_event_v3_4.parse_event_id(event_id)
  if parts is None {
    return response_json(400, error_envelope_json(invalid_event_id_reason("invalid event id")))
  }
  let entity = parts.unwrap().entity_id
  let events = events_for_entity(entity)
  events.sort_by(compare_event)
  let index = find_index(events, event_id)
  match index {
    None => return response_json(404, error_envelope_json(event_not_found_reason(event_id)))
    Some(idx) => {
      let event = events[idx]
      let prev_id = if idx > 0 { Some(@timeline_event_v3_4.event_id(events[idx - 1])) } else { None }
      let next_id = if idx + 1 < events.length() { Some(@timeline_event_v3_4.event_id(events[idx + 1])) } else { None }
      let page : @timeline_event_v3_9.TimelineEventPage = {
        detail: @timeline_event_v3_4.detail_from_event(event),
        prev_event_id: prev_id,
        next_event_id: next_id,
      }
      if format == "json" {
        return response_json(200, @timeline_event_v3_9.page_json(page).stringify(indent=2))
      }
      return response_html(200, @views.render_timeline_event_page_v3_9(page))
    }
  }
}

///|
pub fn handle_request(req : ApiRequest) -> ApiResponse {
  let prefix = "/v3.9/timeline/event/"
  if req.http_method == "GET" && req.path.has_prefix(prefix) {
    let event_id = substring_from(req.path, prefix.length())
    if event_id.length() == 0 {
      return response_json(400, error_envelope_json(invalid_event_id_reason("missing event id")))
    }
    return handle_event(req, event_id)
  }
  response_json(
    404,
    error_envelope_json(@core.Reason::with_context(
      "ROUTE_NOT_FOUND",
      "route not found",
      [
        ("target", "runtime"),
        ("level", "error"),
        ("hint", "Use /v3.9/timeline/event/:id"),
      ],
    )),
  )
}
