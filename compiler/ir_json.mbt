///|
/// Convert FWD-IR into JSON.
///|
fn json_string(value : String) -> Json {
  Json::string(value)
}

///|
fn option_string_json(value : String?) -> Json {
  match value {
    Some(v) => json_string(v)
    None => Json::null()
  }
}

///|
fn effect_kind_json(kind : @core.EffectKind) -> Json {
  match kind {
    @core.EffectKind::Sync => json_string("sync")
    @core.EffectKind::Async => json_string("async")
  }
}

///|
fn compiled_rule_json(rule : @ir.CompiledRule) -> Json {
  let obj : Map[String, Json] = Map::new()
  match rule {
    @ir.CompiledRule::Preset(name) => {
      obj["type"] = json_string("preset")
      obj["name"] = json_string(name)
    }
    @ir.CompiledRule::Custom(impl_name) => {
      obj["type"] = json_string("custom")
      obj["impl"] = json_string(impl_name)
    }
  }
  Json::object(obj)
}

///|
fn transition_ref_json(tr : @ir.TransitionRef) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["name"] = json_string(tr.name)
  Json::object(obj)
}

///|
fn normalized_entity_json(entity : @ir.NormalizedEntity) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["name"] = json_string(entity.name)
  obj["state"] = json_string(entity.state.value())
  obj["dataSchema"] = option_string_json(entity.data_schema)
  Json::object(obj)
}

///|
fn normalized_transition_json(tr : @ir.NormalizedTransition) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["name"] = json_string(tr.name)
  obj["from"] = json_string(tr.from.value())
  obj["to"] = json_string(tr.to.value())
  obj["ruleRefs"] = Json::array(tr.rule_refs.map(json_string))
  obj["effectRefs"] = Json::array(tr.effect_refs.map(json_string))
  obj["inputSchema"] = option_string_json(tr.input_schema)
  Json::object(obj)
}

///|
fn reason_spec_json(reason : @ir.ReasonSpec) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["code"] = json_string(reason.code)
  obj["message"] = json_string(reason.message)
  obj["contextSchema"] = option_string_json(reason.context_schema)
  Json::object(obj)
}

///|
fn effect_spec_json(effect : @ir.EffectSpec) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["name"] = json_string(effect.name)
  obj["kind"] = effect_kind_json(effect.kind)
  Json::object(obj)
}

///|
fn[T] map_values_json(
  map : Map[String, T],
  f : (T) -> Json,
) -> Json {
  let obj : Map[String, Json] = Map::new()
  for key, value in map {
    obj[key] = f(value)
  }
  Json::object(obj)
}

///|
fn directed_graph_json(
  graph : @ir.DirectedGraph[@core.StateTag, @ir.TransitionRef],
) -> Json {
  let nodes : Array[Json] = []
  for tag, _ in graph.nodes {
    nodes.push(json_string(tag.value()))
  }
  let edges_obj : Map[String, Json] = Map::new()
  for from_tag, to_map in graph.edges {
    let inner : Map[String, Json] = Map::new()
    for to_tag, tr in to_map {
      inner[to_tag.value()] = transition_ref_json(tr)
    }
    edges_obj[from_tag.value()] = Json::object(inner)
  }
  let obj : Map[String, Json] = Map::new()
  obj["nodes"] = Json::array(nodes)
  obj["edges"] = Json::object(edges_obj)
  Json::object(obj)
}

///|
/// Public entry: IR -> Json.
///|
pub fn ir_to_json(ir : @ir.FwdIR) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["version"] = json_string(ir.version)
  obj["fwdVersion"] = json_string(ir.fwd_version)
  obj["stateGraph"] = directed_graph_json(ir.state_graph)
  obj["entities"] = map_values_json(ir.entities, normalized_entity_json)
  obj["transitions"] = map_values_json(ir.transitions, normalized_transition_json)
  obj["rules"] = map_values_json(ir.rules, compiled_rule_json)
  obj["reasons"] = map_values_json(ir.reasons, reason_spec_json)
  obj["effects"] = map_values_json(ir.effects, effect_spec_json)
  Json::object(obj)
}
