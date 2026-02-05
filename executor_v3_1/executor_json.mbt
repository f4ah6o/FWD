///|
/// JSON projection for executor detail (v3.1).

fn execution_status_string(status : ExecutionStatus) -> String {
  match status {
    ExecutionStatus::Executed => "executed"
    ExecutionStatus::Failed => "failed"
    ExecutionStatus::Skipped => "skipped"
  }
}

fn attempt_status_string(status : AttemptStatus) -> String {
  match status {
    AttemptStatus::Executed => "executed"
    AttemptStatus::Failed => "failed"
    AttemptStatus::Skipped => "skipped"
  }
}

fn attempt_json(attempt : Attempt) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["attempt"] = Json::number(attempt.attempt.to_double())
  obj["logicalTime"] = Json::number(attempt.logical_time.to_double())
  obj["sequence"] = Json::number(attempt.sequence.to_double())
  obj["status"] = Json::string(attempt_status_string(attempt.status))
  obj["delayMs"] = Json::number(attempt.delay_ms.to_double())
  match attempt.reason {
    Some(reason) => obj["reason"] = @compiler.reason_json(reason)
    None => ()
  }
  Json::object(obj)
}

///|
pub fn execution_detail_json(detail : ExecutionDetail) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["executionVersion"] = Json::string(detail.execution_version)
  obj["entityId"] = Json::string(detail.entity_id)
  obj["transitionId"] = Json::string(detail.transition_id)
  obj["status"] = Json::string(execution_status_string(detail.status))
  let attempts : Array[Json] = []
  for item in detail.attempts {
    attempts.push(attempt_json(item))
  }
  obj["attempts"] = Json::array(attempts)
  obj["idempotency"] = @idempotency_v3.decision_json(detail.idempotency)
  obj["retryPolicy"] = @retry_policy_v3.retry_policy_schedule_json(detail.retry_policy)
  obj["auditEvent"] = @execution_audit_v3.audit_event_json(detail.audit_event)
  Json::object(obj)
}
