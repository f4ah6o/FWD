///|
/// Policy gate contract (v3).

///|
pub(all) enum PolicyDecisionKind {
  Allow
  Deny
}

///|
pub(all) struct PolicyDecision {
  entity_id : String
  transition_id : String
  decision : PolicyDecisionKind
  reasons : Array[@core.Reason]
}
