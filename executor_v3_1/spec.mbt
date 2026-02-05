///|
/// Executor detailed contract (v3.1).

///|
pub(all) enum ExecutionStatus {
  Executed
  Failed
  Skipped
}

///|
pub(all) enum AttemptStatus {
  Executed
  Failed
  Skipped
}

///|
pub(all) struct Attempt {
  attempt : Int
  logical_time : Int
  sequence : Int
  status : AttemptStatus
  delay_ms : Int
  reason : Option[@core.Reason]
}

///|
pub(all) struct ExecutionDetail {
  execution_version : String
  entity_id : String
  transition_id : String
  status : ExecutionStatus
  attempts : Array[Attempt]
  idempotency : @idempotency_v3.Decision
  retry_policy : @retry_policy_v3.RetryPolicy
  audit_event : @execution_audit_v3.AuditEvent
}

///|
pub fn execution_version_v3_1() -> String {
  "3.1"
}
