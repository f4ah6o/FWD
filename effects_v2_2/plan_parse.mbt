///|
/// Parse effects plan JSON (v2.2).

///|
fn invalid_plan_reason(message : String) -> @core.Reason {
  @core.Reason::with_context(
    "INPUT_JSON_INVALID",
    message,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Provide a valid effects plan JSON"),
    ],
  )
}

///|
fn extract_string(obj : Map[String, Json], name : String) -> Result[String, @core.Reason] {
  match obj.get(name) {
    Some(String(value)) => Ok(value)
    Some(_) => Err(invalid_plan_reason("field must be string: " + name))
    None => Err(invalid_plan_reason("missing field: " + name))
  }
}

///|
fn parse_plan_status(value : String) -> Result[PlanStatus, @core.Reason] {
  if value == "planned" {
    Ok(PlanStatus::Planned)
  } else if value == "skipped" {
    Ok(PlanStatus::Skipped)
  } else {
    Err(invalid_plan_reason("unknown status: " + value))
  }
}

///|
fn parse_effect_kind(value : String) -> Result[@core.EffectKind, @core.Reason] {
  if value == "sync" {
    Ok(@core.EffectKind::Sync)
  } else if value == "async" {
    Ok(@core.EffectKind::Async)
  } else {
    Err(invalid_plan_reason("unknown effect kind: " + value))
  }
}

///|
fn parse_reason_obj(obj : Map[String, Json]) -> Result[@core.Reason, @core.Reason] {
  let code = match extract_string(obj, "code") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let message = match extract_string(obj, "message") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let context : Array[(String, String)] = []
  match obj.get("target") {
    Some(String(value)) => context.push(("target", value))
    _ => ()
  }
  match obj.get("level") {
    Some(String(value)) => context.push(("level", value))
    _ => ()
  }
  match obj.get("hint") {
    Some(String(value)) => context.push(("hint", value))
    _ => ()
  }
  Ok(@core.Reason::with_context(code, message, context))
}

///|
fn parse_reasons(obj : Map[String, Json]) -> Result[Array[@core.Reason], @core.Reason] {
  match obj.get("reasons") {
    None => Ok([])
    Some(Array(values)) => {
      let reasons : Array[@core.Reason] = []
      for value in values {
        match value {
          Object(m) =>
            match parse_reason_obj(m) {
              Ok(reason) => reasons.push(reason)
              Err(err) => return Err(err)
            }
          _ => return Err(invalid_plan_reason("reason must be object"))
        }
      }
      Ok(reasons)
    }
    Some(_) => Err(invalid_plan_reason("reasons must be array"))
  }
}

///|
fn parse_items(obj : Map[String, Json]) -> Result[Array[EffectItem], @core.Reason] {
  match obj.get("items") {
    Some(Array(values)) => {
      let items : Array[EffectItem] = []
      for value in values {
        match value {
          Object(m) => {
            let effect_id = match extract_string(m, "effectId") {
              Ok(value) => value
              Err(reason) => return Err(reason)
            }
            let kind_text = match extract_string(m, "kind") {
              Ok(value) => value
              Err(reason) => return Err(reason)
            }
            let kind = match parse_effect_kind(kind_text) {
              Ok(value) => value
              Err(reason) => return Err(reason)
            }
            let payload = match m.get("payload") {
              Some(v) => v
              None => Json::object(Map::new())
            }
            let idempotency_key = match extract_string(m, "idempotencyKey") {
              Ok(value) => value
              Err(reason) => return Err(reason)
            }
            items.push({
              effect_id,
              kind,
              payload,
              idempotency_key,
            })
          }
          _ => return Err(invalid_plan_reason("item must be object"))
        }
      }
      Ok(items)
    }
    Some(_) => Err(invalid_plan_reason("items must be array"))
    None => Err(invalid_plan_reason("missing field: items"))
  }
}

///|
pub fn parse_plan_json(input_json : String) -> Result[EffectsPlan, @core.Reason] {
  let parsed : Result[Json, @json.ParseError] = try? @json.parse(input_json)
  let value = match parsed {
    Ok(v) => v
    Err(err) =>
      return Err(invalid_plan_reason("input json parse error: " + err.to_string()))
  }
  let obj = match value {
    Object(m) => m
    _ => return Err(invalid_plan_reason("input json must be an object"))
  }
  let plan_version = match extract_string(obj, "planVersion") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let entity_id = match extract_string(obj, "entityId") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let transition_id = match extract_string(obj, "transitionId") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let status_text = match extract_string(obj, "status") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let status = match parse_plan_status(status_text) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let items = match parse_items(obj) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let reasons = match parse_reasons(obj) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok({
    plan_version,
    entity_id,
    transition_id,
    status,
    items,
    reasons,
  })
}
