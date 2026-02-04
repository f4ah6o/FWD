///|
/// HTTP adapter v2 (pure request/response routing).

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
fn response_html(status : Int, body : String) -> ApiResponse {
  let headers : Map[String, String] = Map::new()
  headers["content-type"] = "text/html"
  { status, headers, body }
}

///|
fn api_reason_json(reason : @core.Reason) -> Json {
  @compiler.reason_json(reason)
}

///|
fn error_envelope_json(reason : @core.Reason) -> String {
  let obj : Map[String, Json] = Map::new()
  obj["error"] = api_reason_json(reason)
  Json::object(obj).stringify(indent=2)
}

///|
fn effect_kind_string(kind : @core.EffectKind) -> String {
  match kind {
    @core.EffectKind::Sync => "sync"
    @core.EffectKind::Async => "async"
  }
}

///|
fn execution_transition_json(
  id : String,
  from : String,
  to : String,
) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["id"] = Json::string(id)
  obj["from"] = Json::string(from)
  obj["to"] = Json::string(to)
  Json::object(obj)
}

///|
fn runtime_execute_json(outcome : @runtime.ExecutionOutcome) -> String {
  let obj : Map[String, Json] = Map::new()
  match outcome {
    @runtime.ExecutionOutcome::Executed(result) => {
      obj["ok"] = Json::boolean(true)
      obj["transition"] = execution_transition_json(
        result.id,
        result.from,
        result.to,
      )
      let effects : Array[Json] = []
      for effect in result.effects {
        let effect_obj : Map[String, Json] = Map::new()
        effect_obj["name"] = Json::string(effect.name)
        effect_obj["kind"] = Json::string(effect_kind_string(effect.kind))
        effects.push(Json::object(effect_obj))
      }
      obj["effects"] = Json::array(effects)
    }
    @runtime.ExecutionOutcome::Blocked(blocked) => {
      obj["ok"] = Json::boolean(false)
      obj["transition"] = execution_transition_json(
        blocked.id,
        blocked.from,
        blocked.to,
      )
      let reasons : Array[Json] = []
      for reason in blocked.reasons {
        reasons.push(api_reason_json(reason))
      }
      obj["reasons"] = Json::array(reasons)
    }
  }
  Json::object(obj).stringify(indent=2)
}

///|
fn missing_query_reason(name : String) -> @core.Reason {
  @core.Reason::with_context(
    "INPUT_MISSING",
    "missing query parameter: " + name,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Provide ?" + name + "=..."),
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
fn render_resource(
  resource : @hypermedia.Resource,
  format : String,
) -> ApiResponse {
  if format == "html" {
    return response_html(200, @views.render_resource_html(resource))
  }
  if format == "mx" {
    return response_html(200, @views.render_resource_html_mx(resource))
  }
  response_json(200, @hypermedia.resource_json(resource).stringify(indent=2))
}

///|
fn transitions_from_state(
  ir : @ir.FwdIR,
  state : String,
) -> Array[@views.FormTransition] {
  let state_tag = @core.StateTag::new(state)
  let names : Array[String] = []
  for entry in ir.transitions.to_array() {
    names.push(entry.0)
  }
  names.sort_by((a, b) => if a < b { -1 } else if a > b { 1 } else { 0 })
  let transitions : Array[@views.FormTransition] = []
  for name in names {
    let tr = ir.transitions[name]
    if tr.from != state_tag {
      continue
    }
    transitions.push({ id: tr.name, to: tr.to.value(), input_schema: tr.input_schema })
  }
  transitions
}

///|
fn blocked_map_from_runtime(
  result : @runtime.RuntimeResult,
) -> Map[String, Array[@core.Reason]] {
  let blocked : Map[String, Array[@core.Reason]] = Map::new()
  for tr in result.blocked_transitions {
    blocked[tr.id] = tr.reasons
  }
  blocked
}

///|
fn handle_resource(schema_text : String, req : ApiRequest) -> ApiResponse {
  let state = match req.query.get("state") {
    Some(value) => value
    None =>
      return response_json(
        400,
        error_envelope_json(missing_query_reason("state")),
      )
  }
  let ir = match @compiler.compile_yaml(schema_text) {
    Ok(value) => value
    Err(err) =>
      return response_json(
        400,
        error_envelope_json(reason_from_compile_error(err)),
      )
  }
  let format = match req.query.get("format") {
    Some(value) => value
    None => "json"
  }
  if format == "form" {
    let runtime_result = match @runtime.compute_available_transitions(
      ir,
      state,
      Map::new(),
    ) {
      Ok(value) => value
      Err(reason) =>
        return response_json(
          400,
          error_envelope_json(reason),
        )
    }
    let transitions = transitions_from_state(ir, state)
    let blocked = blocked_map_from_runtime(runtime_result)
    return response_html(
      200,
      @views.render_resource_html_v2_form(state, transitions, blocked),
    )
  }
  let runtime_result = match @runtime.compute_available_transitions(
    ir,
    state,
    Map::new(),
  ) {
    Ok(value) => value
    Err(reason) =>
      return response_json(
        400,
        error_envelope_json(reason),
      )
  }
  let resource = @hypermedia.resource_from_runtime(runtime_result)
  render_resource(resource, format)
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
fn extract_input_field(
  obj : Map[String, Json],
) -> Result[Map[String, Bool], @core.Reason] {
  match obj.get("input") {
    None => Ok(Map::new())
    Some(value) => {
      let input_json = value.stringify()
      @hypermedia.parse_rule_results(input_json)
    }
  }
}

///|
fn extract_payload_field(
  obj : Map[String, Json],
) -> Result[Json?, @core.Reason] {
  match obj.get("payload") {
    None => Ok(None)
    Some(value) => Ok(Some(value))
  }
}

///|
fn payload_required_reason() -> @core.Reason {
  @core.Reason::with_context(
    "INPUT_MISSING",
    "payload is required",
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Provide payload object"),
    ],
  )
}

///|
fn payload_invalid_reason() -> @core.Reason {
  @core.Reason::with_context(
    "INPUT_JSON_INVALID",
    "payload must be an object",
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Provide payload as a JSON object"),
    ],
  )
}

///|
fn handle_execute(schema_text : String, req : ApiRequest) -> ApiResponse {
  let body = match req.body {
    Some(value) => value
    None =>
      return response_json(
        400,
        error_envelope_json(missing_field_reason("body")),
      )
  }
  let body_obj = match extract_body_json(body) {
    Ok(value) => value
    Err(reason) =>
      return response_json(
        400,
        error_envelope_json(reason),
      )
  }
  let state = match extract_string_field(body_obj, "state") {
    Ok(value) => value
    Err(reason) =>
      return response_json(
        400,
        error_envelope_json(reason),
      )
  }
  let transition = match extract_string_field(body_obj, "transition") {
    Ok(value) => value
    Err(reason) =>
      return response_json(
        400,
        error_envelope_json(reason),
      )
  }
  let rule_results = match extract_input_field(body_obj) {
    Ok(value) => value
    Err(reason) =>
      return response_json(
        400,
        error_envelope_json(reason),
      )
  }
  let ir = match @compiler.compile_yaml(schema_text) {
    Ok(value) => value
    Err(err) =>
      return response_json(
        400,
        error_envelope_json(reason_from_compile_error(err)),
      )
  }
  match @runtime.execute_transition(ir, state, transition, rule_results) {
    Ok(outcome) => response_json(200, runtime_execute_json(outcome))
    Err(reason) => response_json(400, error_envelope_json(reason))
  }
}

///|
fn handle_validate(schema_text : String, req : ApiRequest) -> ApiResponse {
  let body = match req.body {
    Some(value) => value
    None =>
      return response_json(
        400,
        error_envelope_json(missing_field_reason("body")),
      )
  }
  let body_obj = match extract_body_json(body) {
    Ok(value) => value
    Err(reason) =>
      return response_json(
        400,
        error_envelope_json(reason),
      )
  }
  let state = match extract_string_field(body_obj, "state") {
    Ok(value) => value
    Err(reason) =>
      return response_json(
        400,
        error_envelope_json(reason),
      )
  }
  let transition = match extract_string_field(body_obj, "transition") {
    Ok(value) => value
    Err(reason) =>
      return response_json(
        400,
        error_envelope_json(reason),
      )
  }
  let payload = match extract_payload_field(body_obj) {
    Ok(value) => value
    Err(reason) =>
      return response_json(
        400,
        error_envelope_json(reason),
      )
  }
  let ir = match @compiler.compile_yaml(schema_text) {
    Ok(value) => value
    Err(err) =>
      return response_json(
        400,
        error_envelope_json(reason_from_compile_error(err)),
      )
  }
  let state_tag = @core.StateTag::new(state)
  if !ir.state_graph.nodes.contains(state_tag) {
    return response_json(
      400,
      error_envelope_json(@runtime.state_not_found_reason(state)),
    )
  }
  if !ir.transitions.contains(transition) {
    return response_json(
      400,
      error_envelope_json(@runtime.transition_not_found_reason(transition)),
    )
  }
  let tr = ir.transitions[transition]
  if tr.from != state_tag {
    return response_json(
      400,
      error_envelope_json(@runtime.transition_not_available_reason(
        transition,
        state,
        tr.from.value(),
      )),
    )
  }
  let payload_json = match payload {
    Some(value) => value
    None => Json::object(Map::new())
  }
  match tr.input_schema {
    Some(_) => {
      match payload_json {
        Object(_) => ()
        _ =>
          return response_json(
            400,
            error_envelope_json(payload_invalid_reason()),
          )
      }
      if payload is None {
        return response_json(
          400,
          error_envelope_json(payload_required_reason()),
        )
      }
    }
    None => ()
  }
  let payload_text = payload_json.stringify()
  response_html(
    200,
    @views.render_validation_result_html(state, transition, payload_text),
  )
}

///|
pub fn handle_request(schema_text : String, req : ApiRequest) -> ApiResponse {
  if req.http_method == "GET" && req.path == "/v2/resource" {
    return handle_resource(schema_text, req)
  }
  if req.http_method == "POST" && req.path == "/v2/transition/execute" {
    return handle_execute(schema_text, req)
  }
  if req.http_method == "POST" && req.path == "/v2/resource/validate" {
    return handle_validate(schema_text, req)
  }
  response_json(
    404,
    error_envelope_json(@core.Reason::with_context(
      "ROUTE_NOT_FOUND",
      "route not found",
      [
        ("target", "runtime"),
        ("level", "error"),
        ("hint", "Use /v2/resource or /v2/transition/execute"),
      ],
    )),
  )
}
