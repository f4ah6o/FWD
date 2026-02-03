///|
/// Normalize resolved schema into a stable IR form (v1.2).
///|
fn rule_expr_key(expr : @schema.RuleExpression) -> String {
  match expr {
    @schema.RuleExpression::Preset(name) => name
    @schema.RuleExpression::Custom(impl_name) => "custom:" + impl_name
  }
}

///|
fn sorted_states(schema : @schema.Schema) -> Array[@schema.StateDefinition] {
  let states = schema.states.copy()
  states.sort_by_key((s) => s.name)
  states
}

///|
fn sorted_entities(schema : @schema.Schema) -> Array[@schema.EntityDefinition] {
  let entities = schema.entities.copy()
  entities.sort_by_key((e) => e.name)
  entities
}

///|
fn sorted_transitions(schema : @schema.Schema) -> Array[@schema.TransitionDefinition] {
  let transitions = schema.transitions.copy()
  transitions.sort_by_key((t) => t.name)
  let normalized : Array[@schema.TransitionDefinition] = []
  for tr in transitions {
    let rules = tr.rules.copy()
    rules.sort_by_key(rule_expr_key)
    let effects = tr.effects.copy()
    effects.sort_by_key((name) => name)
    normalized.push({
      name: tr.name,
      from: tr.from,
      to: tr.to,
      rules,
      effects,
      input_schema: tr.input_schema,
    })
  }
  normalized
}

///|
fn sorted_rules(schema : @schema.Schema) -> Array[@schema.RuleDefinition] {
  let rules = schema.rules.copy()
  rules.sort_by_key((r) => r.name)
  rules
}

///|
fn sorted_reasons(schema : @schema.Schema) -> Array[@schema.ReasonDefinition] {
  let reasons = schema.reasons.copy()
  reasons.sort_by_key((r) => r.code)
  reasons
}

///|
fn sorted_boundaries(schema : @schema.Schema) -> Array[@schema.BoundaryDefinition] {
  let boundaries = schema.boundaries.copy()
  boundaries.sort_by_key((b) => b.name)
  boundaries
}

///|
fn sorted_effects(schema : @schema.Schema) -> Array[@schema.EffectDefinition] {
  let effects = schema.effects.copy()
  effects.sort_by_key((e) => e.name)
  effects
}

///|
pub fn normalize_schema(resolved : ResolvedSchema) -> @ir.FwdIR {
  let schema = resolved.schema
  let normalized : @schema.Schema = {
    fwd_version: schema.fwd_version,
    schema_version: schema.schema_version,
    states: sorted_states(schema),
    entities: sorted_entities(schema),
    transitions: sorted_transitions(schema),
    rules: sorted_rules(schema),
    reasons: sorted_reasons(schema),
    boundaries: sorted_boundaries(schema),
    effects: sorted_effects(schema),
  }
  emit_ir_from_schema(normalized)
}
