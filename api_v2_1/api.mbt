///|
/// v2.1 API adapter (pure router) for entity persistence and history.

///|
pub(all) struct ApiRequest {
  http_method : String
  path : String
  body : String?
}

///|
pub(all) struct ApiResponse {
  status : Int
  headers : Map[String, String]
  body : String
}

///|
pub(all) struct ApiState {
  store : @store_v2_1.Store
  history : @history_v2_1.HistoryStore
}

///|
pub fn ApiState::new() -> ApiState {
  { store: @store_v2_1.Store::new(), history: @history_v2_1.HistoryStore::new() }
}

///|
fn response_json(status : Int, body : String) -> ApiResponse {
  let headers : Map[String, String] = Map::new()
  headers["content-type"] = "application/json"
  { status, headers, body }
}

///|
fn response_html(status : Int, body : String) -> ApiResponse {
  let headers : Map[String, String] = Map::new()
  headers["content-type"] = "text/html"
  { status, headers, body }
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
fn invalid_body_reason(msg : String) -> @core.Reason {
  @core.Reason::with_context(
    "INPUT_JSON_INVALID",
    msg,
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
fn extract_payload_field(obj : Map[String, Json]) -> Result[Json?, @core.Reason] {
  match obj.get("payload") {
    None => Ok(None)
    Some(value) => Ok(Some(value))
  }
}

///|
fn ensure_payload_object(payload : Json?) -> Result[Json?, @core.Reason] {
  match payload {
    None => Ok(None)
    Some(Object(_)) => Ok(payload)
    Some(_) => Err(invalid_body_reason("payload must be an object"))
  }
}

///|
fn parse_entity_id(path : String, suffix : String) -> String? {
  if path.has_prefix(suffix) {
    let rest = try! path[suffix.length():]
    if rest.length() > 0 {
      return Some(rest.to_string())
    }
  }
  None
}

///|
fn runtime_execute_json(outcome : @runtime.ExecutionOutcome) -> String {
  let obj : Map[String, Json] = Map::new()
  match outcome {
    @runtime.ExecutionOutcome::Executed(result) => {
      obj["ok"] = Json::boolean(true)
      let tr_obj : Map[String, Json] = Map::new()
      tr_obj["id"] = Json::string(result.id)
      tr_obj["from"] = Json::string(result.from)
      tr_obj["to"] = Json::string(result.to)
      obj["transition"] = Json::object(tr_obj)
      let effects : Array[Json] = []
      for effect in result.effects {
        let eobj : Map[String, Json] = Map::new()
        eobj["name"] = Json::string(effect.name)
        eobj["kind"] = Json::string(match effect.kind {
          @core.EffectKind::Sync => "sync"
          @core.EffectKind::Async => "async"
        })
        effects.push(Json::object(eobj))
      }
      obj["effects"] = Json::array(effects)
    }
    @runtime.ExecutionOutcome::Blocked(blocked) => {
      obj["ok"] = Json::boolean(false)
      let tr_obj : Map[String, Json] = Map::new()
      tr_obj["id"] = Json::string(blocked.id)
      tr_obj["from"] = Json::string(blocked.from)
      tr_obj["to"] = Json::string(blocked.to)
      obj["transition"] = Json::object(tr_obj)
      let reasons : Array[Json] = []
      for reason in blocked.reasons {
        reasons.push(@compiler.reason_json(reason))
      }
      obj["reasons"] = Json::array(reasons)
    }
  }
  Json::object(obj).stringify(indent=2)
}

///|
fn snapshot_response(snapshot : @store_v2_1.Snapshot) -> String {
  @store_v2_1.snapshot_json(snapshot).stringify(indent=2)
}

///|
fn history_response(events : Array[@history_v2_1.HistoryEvent]) -> String {
  @history_v2_1.history_list_json(events).stringify(indent=2)
}

///|
fn history_html_response(events : Array[@history_v2_1.HistoryEvent]) -> String {
  @views.render_history_html(events)
}

///|
fn entity_html_response(snapshot : @store_v2_1.Snapshot) -> String {
  @views.render_entity_html(snapshot)
}

///|
fn handle_create(state : ApiState, req : ApiRequest) -> ApiResponse {
  let body = match req.body {
    Some(value) => value
    None => return response_json(400, error_envelope_json(missing_field_reason("body")))
  }
  let obj = match extract_body_json(body) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let entity_id = match extract_string_field(obj, "entityId") {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let state_value = match extract_string_field(obj, "state") {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let payload = match extract_payload_field(obj) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let snapshot = @store_v2_1.Snapshot::new(entity_id, state_value, payload, 1)
  state.store.save(snapshot)
  response_json(200, snapshot_response(snapshot))
}

///|
fn handle_get(state : ApiState, entity_id : String, format : String) -> ApiResponse {
  let snapshot = match state.store.get(entity_id) {
    Some(value) => value
    None =>
      return response_json(
        404,
        error_envelope_json(@core.Reason::with_context(
          "ENTITY_NOT_FOUND",
          "entity not found",
          [
            ("target", "runtime"),
            ("level", "error"),
            ("hint", "Create the entity first"),
          ],
        )),
      )
  }
  if format == "v2_1_html" {
    return response_html(200, entity_html_response(snapshot))
  }
  response_json(200, snapshot_response(snapshot))
}

///|
fn handle_history(state : ApiState, entity_id : String, format : String) -> ApiResponse {
  let events = state.history.get(entity_id)
  if format == "v2_1_html" {
    return response_html(200, history_html_response(events))
  }
  response_json(200, history_response(events))
}

///|
fn extract_input_field(obj : Map[String, Json]) -> Result[Map[String, Bool], @core.Reason] {
  match obj.get("input") {
    None => Ok(Map::new())
    Some(value) => @hypermedia.parse_rule_results(value.stringify())
  }
}

///|
fn handle_execute(schema_text : String, state : ApiState, req : ApiRequest, entity_id : String) -> ApiResponse {
  let body = match req.body {
    Some(value) => value
    None => return response_json(400, error_envelope_json(missing_field_reason("body")))
  }
  let obj = match extract_body_json(body) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let transition = match extract_string_field(obj, "transition") {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let payload = match ensure_payload_object(match extract_payload_field(obj) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let input = match extract_input_field(obj) {
    Ok(value) => value
    Err(reason) => return response_json(400, error_envelope_json(reason))
  }
  let snapshot = match state.store.get(entity_id) {
    Some(value) => value
    None =>
      return response_json(
        404,
        error_envelope_json(@core.Reason::with_context(
          "ENTITY_NOT_FOUND",
          "entity not found",
          [
            ("target", "runtime"),
            ("level", "error"),
            ("hint", "Create the entity first"),
          ],
        )),
      )
  }
  let ir = match @compiler.compile_yaml(schema_text) {
    Ok(value) => value
    Err(err) => return response_json(400, error_envelope_json(reason_from_compile_error(err)))
  }
  match @runtime.execute_transition(ir, snapshot.state, transition, input) {
    Ok(outcome) => {
      match outcome {
        @runtime.ExecutionOutcome::Executed(result) => {
          let payload_value = match payload {
            Some(value) => value
            None => snapshot.payload.unwrap_or(Json::object(Map::new()))
          }
          let new_snapshot = @store_v2_1.Snapshot::new(
            snapshot.entity_id,
            result.to,
            Some(payload_value),
            snapshot.version + 1,
          )
          state.store.save(new_snapshot)
          ignore(state.history.append(
            snapshot.entity_id,
            result.id,
            result.from,
            result.to,
            payload_value,
            @history_v2_1.HistoryResult::Executed,
            [],
          ))
        }
        @runtime.ExecutionOutcome::Blocked(blocked) => {
          let payload_value = match payload {
            Some(value) => value
            None => snapshot.payload.unwrap_or(Json::object(Map::new()))
          }
          ignore(state.history.append(
            snapshot.entity_id,
            blocked.id,
            blocked.from,
            blocked.to,
            payload_value,
            @history_v2_1.HistoryResult::Blocked,
            blocked.reasons,
          ))
        }
      }
      response_json(200, runtime_execute_json(outcome))
    }
    Err(reason) => response_json(400, error_envelope_json(reason))
  }
}

///|
fn parse_request_path(req : ApiRequest) -> (ApiRequest, String) {
  let mut format = "json"
  let mut path = req.path
  if path.contains("?format=") {
    let pattern = "?format="
    let index = path.find(pattern).unwrap_or(-1)
    if index >= 0 {
      let end_index = index + pattern.length()
      if end_index <= path.length() {
        let format_view = try! path[end_index:]
        format = format_view.to_string()
        let base_view = try! path[:index]
        path = base_view.to_string()
      }
    }
  }
  ({ http_method: req.http_method, path, body: req.body }, format)
}

///|
pub fn handle_request(
  schema_text : String,
  state : ApiState,
  req : ApiRequest,
) -> ApiResponse {
  let (request, format) = parse_request_path(req)
  if request.http_method == "POST" && request.path == "/v2.1/entities" {
    return handle_create(state, request)
  }
  if request.http_method == "GET" && request.path.has_prefix("/v2.1/entities/") {
    let entity_id = match parse_entity_id(request.path, "/v2.1/entities/") {
      Some(value) => value
      None => return response_json(404, error_envelope_json(missing_field_reason("entityId")))
    }
    if request.path.has_suffix("/history") {
      let trimmed = try! request.path[:request.path.length() - "/history".length()].to_string()
      let eid = match parse_entity_id(trimmed, "/v2.1/entities/") {
        Some(value) => value
        None => return response_json(404, error_envelope_json(missing_field_reason("entityId")))
      }
      return handle_history(state, eid, format)
    }
    return handle_get(state, entity_id, format)
  }
  if request.http_method == "POST" && request.path.has_suffix("/execute") {
    let trimmed = try! request.path[:request.path.length() - "/execute".length()].to_string()
    let entity_id = match parse_entity_id(trimmed, "/v2.1/entities/") {
      Some(value) => value
      None =>
        return response_json(
          404,
          error_envelope_json(@core.Reason::with_context(
            "ENTITY_NOT_FOUND",
            "entity not found",
            [
              ("target", "runtime"),
              ("level", "error"),
              ("hint", "Create the entity first"),
            ],
          )),
        )
    }
    return handle_execute(schema_text, state, request, entity_id)
  }
  response_json(
    404,
    error_envelope_json(@core.Reason::with_context(
      "ROUTE_NOT_FOUND",
      "route not found",
      [
        ("target", "runtime"),
        ("level", "error"),
        ("hint", "Use /v2.1/entities"),
      ],
    )),
  )
}
