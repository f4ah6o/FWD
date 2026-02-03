///|
/// Runtime transition execution (v1): pure evaluation only.

///|
pub(all) struct ExecutionEffect {
  name : String
  kind : @core.EffectKind
}

///|
pub(all) struct ExecutedTransition {
  id : String
  from : String
  to : String
  effects : Array[ExecutionEffect]
}

///|
pub(all) struct BlockedExecution {
  id : String
  from : String
  to : String
  reasons : Array[@core.Reason]
}

///|
pub(all) enum ExecutionOutcome {
  Executed(ExecutedTransition)
  Blocked(BlockedExecution)
}

///|
fn collect_effects(
  ir : @ir.FwdIR,
  effect_refs : Array[String],
) -> Array[ExecutionEffect] {
  let effects : Array[ExecutionEffect] = []
  for name in effect_refs {
    if ir.effects.contains(name) {
      let spec = ir.effects[name]
      effects.push({ name: spec.name, kind: spec.kind })
    }
  }
  effects
}

///|
pub fn execute_transition(
  ir : @ir.FwdIR,
  state : String,
  transition_id : String,
  rule_results : Map[String, Bool],
) -> Result[ExecutionOutcome, @core.Reason] {
  let state_tag = @core.StateTag::new(state)
  if !ir.state_graph.nodes.contains(state_tag) {
    return Err(state_not_found_reason(state))
  }
  if !ir.transitions.contains(transition_id) {
    return Err(transition_not_found_reason(transition_id))
  }
  let tr = ir.transitions[transition_id]
  if tr.from != state_tag {
    return Err(transition_not_available_reason(
      transition_id,
      state,
      tr.from.value(),
    ))
  }
  let reasons : Array[@core.Reason] = []
  for rule in tr.rule_refs {
    match rule_results.get(rule) {
      Some(true) => ()
      _ => reasons.push(rule_not_satisfied_reason(tr.name, rule))
    }
  }
  if reasons.length() > 0 {
    return Ok(ExecutionOutcome::Blocked({
      id: tr.name,
      from: tr.from.value(),
      to: tr.to.value(),
      reasons,
    }))
  }
  let effects = collect_effects(ir, tr.effect_refs)
  Ok(ExecutionOutcome::Executed({
    id: tr.name,
    from: tr.from.value(),
    to: tr.to.value(),
    effects,
  }))
}
