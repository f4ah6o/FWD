///|
/// JSON projection for Hypermedia Resource (v3).

fn reason_json_v3(reason : @core.Reason) -> Json {
  @compiler.reason_json(reason)
}

fn option_string_json(value : String?) -> Json {
  match value {
    Some(v) => Json::string(v)
    None => Json::null()
  }
}

fn option_json(value : Json?) -> Json {
  match value {
    Some(v) => v
    None => Json::null()
  }
}

fn policy_json(decision : @policy_v3.PolicyDecision?) -> Json {
  match decision {
    Some(value) => @policy_v3.policy_decision_json(value)
    None => Json::null()
  }
}

fn effects_json(plan : @effects_v2_2.EffectsPlan?) -> Json {
  match plan {
    Some(value) => @effects_v2_2.effect_plan_json(value)
    None => Json::null()
  }
}

///|
pub fn resource_v3_json(resource : ResourceV3) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["state"] = Json::string(resource.state)
  let transitions : Array[Json] = []
  for tr in resource.transitions {
    let tr_obj : Map[String, Json] = Map::new()
    tr_obj["id"] = Json::string(tr.id)
    tr_obj["to"] = Json::string(tr.to)
    tr_obj["inputSchema"] = option_string_json(tr.input_schema)
    tr_obj["draftPayload"] = option_json(tr.draft_payload)
    let errors : Array[Json] = []
    for reason in tr.field_errors {
      errors.push(reason_json_v3(reason))
    }
    tr_obj["fieldErrors"] = Json::array(errors)
    tr_obj["policyDecision"] = policy_json(tr.policy_decision)
    tr_obj["effectsPreview"] = effects_json(tr.effects_preview)
    tr_obj["canExecute"] = Json::boolean(tr.can_execute)
    transitions.push(Json::object(tr_obj))
  }
  obj["transitions"] = Json::array(transitions)
  Json::object(obj)
}
