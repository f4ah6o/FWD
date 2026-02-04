///|
/// Hypermedia resource projection (v3) with policy/effects preview.

///|
pub(all) struct ResourceTransitionV3 {
  id : String
  to : String
  input_schema : String?
  draft_payload : Json?
  field_errors : Array[@core.Reason]
  policy_decision : @policy_v3.PolicyDecision?
  effects_preview : @effects_v2_2.EffectsPlan?
  can_execute : Bool
}

///|
pub(all) struct ResourceV3 {
  state : String
  transitions : Array[ResourceTransitionV3]
}

///|
fn compare_string_v3(a : String, b : String) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
pub fn resource_v3_from_ir(ir : @ir.FwdIR, state : String) -> ResourceV3 {
  let state_tag = @core.StateTag::new(state)
  let names : Array[String] = []
  for entry in ir.transitions.to_array() {
    names.push(entry.0)
  }
  names.sort_by(compare_string_v3)
  let transitions : Array[ResourceTransitionV3] = []
  for name in names {
    let tr = ir.transitions[name]
    if tr.from != state_tag {
      continue
    }
    transitions.push({
      id: tr.name,
      to: tr.to.value(),
      input_schema: tr.input_schema,
      draft_payload: None,
      field_errors: [],
      policy_decision: None,
      effects_preview: None,
      can_execute: false,
    })
  }
  { state, transitions }
}

///|
pub fn resource_v3_validation(
  state : String,
  transition_id : String,
  to : String,
  input_schema : String?,
  draft_payload : Json?,
  field_errors : Array[@core.Reason],
  policy_decision : @policy_v3.PolicyDecision?,
  effects_preview : @effects_v2_2.EffectsPlan?,
) -> ResourceV3 {
  let can_execute = field_errors.length() == 0
  {
    state,
    transitions: [
      {
        id: transition_id,
        to,
        input_schema,
        draft_payload,
        field_errors,
        policy_decision,
        effects_preview,
        can_execute,
      },
    ],
  }
}
