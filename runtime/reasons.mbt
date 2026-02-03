///|
/// Runtime reason helpers (v1).

///|
pub fn rule_not_satisfied_reason(
  transition_id : String,
  rule : String,
) -> @core.Reason {
  @core.Reason::with_context(
    "RULE_NOT_SATISFIED",
    "Rule not satisfied",
    [
      ("rule", rule),
      ("transition", transition_id),
      ("target", "rule"),
      ("level", "info"),
      ("hint", "Provide rule result true for this transition"),
    ],
  )
}

///|
pub fn state_not_found_reason(state : String) -> @core.Reason {
  @core.Reason::with_context(
    "STATE_NOT_FOUND",
    "state not found in IR",
    [
      ("state", state),
      ("target", "state"),
      ("level", "error"),
      ("hint", "Provide a valid current state"),
    ],
  )
}

///|
pub fn transition_not_found_reason(transition_id : String) -> @core.Reason {
  @core.Reason::with_context(
    "TRANSITION_NOT_FOUND",
    "transition not found in IR",
    [
      ("transition", transition_id),
      ("target", "transition"),
      ("level", "error"),
      ("hint", "Provide a valid transition id"),
    ],
  )
}

///|
pub fn transition_not_available_reason(
  transition_id : String,
  state : String,
  expected_from : String,
) -> @core.Reason {
  @core.Reason::with_context(
    "TRANSITION_NOT_AVAILABLE",
    "transition not available from current state",
    [
      ("transition", transition_id),
      ("state", state),
      ("from", expected_from),
      ("target", "transition"),
      ("level", "error"),
      ("hint", "Select a transition available from the current state"),
    ],
  )
}
