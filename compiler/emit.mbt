///|
/// Emit FWD-IR from schema.
///|
fn ensure_rule(
  rules : Map[String, @ir.CompiledRule],
  expr : @schema.RuleExpression,
) -> String {
  match expr {
    @schema.RuleExpression::Preset(name) => {
      if rules.contains(name) {
        name
      } else {
        rules[name] = @ir.CompiledRule::Preset(name)
        name
      }
    }
    @schema.RuleExpression::Custom(impl_name) => {
      let key = "custom:" + impl_name
      if !rules.contains(key) {
        rules[key] = @ir.CompiledRule::Custom(impl_name)
      }
      key
    }
  }
}

///|
fn build_state_graph(
  schema : @schema.Schema,
) -> @ir.DirectedGraph[@core.StateTag, @ir.TransitionRef] {
  let nodes : Map[@core.StateTag, Unit] = Map::new()
  for state in schema.states {
    nodes[@core.StateTag::new(state.name)] = ()
  }
  let edges : Map[@core.StateTag, Map[@core.StateTag, @ir.TransitionRef]] = Map::new()
  for transition in schema.transitions {
    let from_tag = @core.StateTag::new(transition.from)
    let to_tag = @core.StateTag::new(transition.to)
    nodes[from_tag] = ()
    nodes[to_tag] = ()
    let to_map = edges.get_or_init(from_tag, () => Map::new())
    to_map[to_tag] = { name: transition.name }
  }
  { nodes, edges }
}

///|
pub fn emit_ir_from_schema(schema : @schema.Schema) -> @ir.FwdIR {
  let rules : Map[String, @ir.CompiledRule] = Map::new()
  for rule in schema.rules {
    let key = rule.name
    let compiled = match rule.expr {
      @schema.RuleExpression::Preset(name) => @ir.CompiledRule::Preset(name)
      @schema.RuleExpression::Custom(impl_name) => @ir.CompiledRule::Custom(impl_name)
    }
    rules[key] = compiled
  }

  let transitions : Map[String, @ir.NormalizedTransition] = Map::new()
  for transition in schema.transitions {
    let refs : Array[String] = []
    for expr in transition.rules {
      refs.push(ensure_rule(rules, expr))
    }
    transitions[transition.name] = {
      name: transition.name,
      from: @core.StateTag::new(transition.from),
      to: @core.StateTag::new(transition.to),
      rule_refs: refs,
      effect_refs: transition.effects,
      input_schema: transition.input_schema,
    }
  }

  let entities : Map[String, @ir.NormalizedEntity] = Map::new()
  for entity in schema.entities {
    entities[entity.name] = {
      name: entity.name,
      state: @core.StateTag::new(entity.initial_state),
      data_schema: None,
    }
  }

  let reasons : Map[String, @ir.ReasonSpec] = Map::new()
  for reason in schema.reasons {
    reasons[reason.code] = {
      code: reason.code,
      message: reason.message,
      context_schema: reason.context_schema,
    }
  }

  let effects : Map[String, @ir.EffectSpec] = Map::new()
  for effect in schema.effects {
    effects[effect.name] = {
      name: effect.name,
      kind: effect.kind,
    }
  }

  {
    version: "1.0",
    fwd_version: schema.fwd_version,
    state_graph: build_state_graph(schema),
    entities,
    transitions,
    rules,
    reasons,
    effects,
  }
}
