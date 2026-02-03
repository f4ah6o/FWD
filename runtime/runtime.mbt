///|
/// Runtime computation (v1): compute available and blocked transitions.

///|
pub(all) struct AvailableTransition {
  id : String
  to : String
}

///|
pub(all) struct BlockedTransition {
  id : String
  reasons : Array[@core.Reason]
}

///|
pub(all) struct RuntimeResult {
  available_transitions : Array[AvailableTransition]
  blocked_transitions : Array[BlockedTransition]
}

///|
fn compare_string(a : String, b : String) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
pub fn compute_available_transitions(
  ir : @ir.FwdIR,
  state : String,
  rule_results : Map[String, Bool],
) -> Result[RuntimeResult, @core.Reason] {
  let state_tag = @core.StateTag::new(state)
  if !ir.state_graph.nodes.contains(state_tag) {
    return Err(state_not_found_reason(state))
  }
  let names : Array[String] = []
  for item in ir.transitions.to_array() {
    names.push(item.0)
  }
  names.sort_by(compare_string)
  let available : Array[AvailableTransition] = []
  let blocked : Array[BlockedTransition] = []
  for name in names {
    let tr = ir.transitions[name]
    if tr.from != state_tag {
      continue
    }
    let reasons : Array[@core.Reason] = []
    for rule in tr.rule_refs {
      match rule_results.get(rule) {
        Some(true) => ()
        _ => reasons.push(rule_not_satisfied_reason(tr.name, rule))
      }
    }
    if reasons.length() == 0 {
      available.push({ id: tr.name, to: tr.to.value() })
    } else {
      blocked.push({ id: tr.name, reasons })
    }
  }
  Ok({
    available_transitions: available,
    blocked_transitions: blocked,
  })
}
