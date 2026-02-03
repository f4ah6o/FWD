///|
/// Runtime CLI JSON helpers.

///|
fn runtime_reason_json(reason : @core.Reason) -> Json {
  @compiler.reason_json(reason)
}

///|
pub fn runtime_output_json(result : @runtime.RuntimeResult) -> Json {
  let obj : Map[String, Json] = Map::new()
  let available : Array[Json] = []
  for tr in result.available_transitions {
    let tr_obj : Map[String, Json] = Map::new()
    tr_obj["id"] = Json::string(tr.id)
    tr_obj["to"] = Json::string(tr.to)
    available.push(Json::object(tr_obj))
  }
  let blocked : Array[Json] = []
  for tr in result.blocked_transitions {
    let tr_obj : Map[String, Json] = Map::new()
    tr_obj["id"] = Json::string(tr.id)
    let reasons : Array[Json] = []
    for reason in tr.reasons {
      reasons.push(runtime_reason_json(reason))
    }
    tr_obj["reasons"] = Json::array(reasons)
    blocked.push(Json::object(tr_obj))
  }
  obj["availableTransitions"] = Json::array(available)
  obj["blockedTransitions"] = Json::array(blocked)
  Json::object(obj)
}

///|
pub fn runtime_error_json(reason : @core.Reason) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["error"] = runtime_reason_json(reason)
  Json::object(obj)
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
pub fn runtime_execute_json(outcome : @runtime.ExecutionOutcome) -> Json {
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
        reasons.push(runtime_reason_json(reason))
      }
      obj["reasons"] = Json::array(reasons)
    }
  }
  Json::object(obj)
}

///|
pub fn parse_rule_results(
  input_json : String,
) -> Result[Map[String, Bool], @core.Reason] {
  @hypermedia.parse_rule_results(input_json)
}
