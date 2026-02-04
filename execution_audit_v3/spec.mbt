///|
/// Execution audit contract (v3).

///|
pub(all) enum AuditStatus {
  Executed
  Blocked
  Failed
}

///|
pub(all) enum ItemStatus {
  Executed
  Failed
}

///|
pub(all) struct AuditItem {
  effect_id : String
  status : ItemStatus
  duration_ms : Int
  reason : Option[@core.Reason]
}

///|
pub(all) struct AuditEvent {
  entity_id : String
  transition_id : String
  logical_time : Int
  sequence : Int
  status : AuditStatus
  items : Array[AuditItem]
  reasons : Array[@core.Reason]
}
