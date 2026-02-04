///|
/// JSON projection for execution audit events (v3).

fn audit_status_string(status : AuditStatus) -> String {
  match status {
    AuditStatus::Executed => "executed"
    AuditStatus::Blocked => "blocked"
    AuditStatus::Failed => "failed"
  }
}

fn item_status_string(status : ItemStatus) -> String {
  match status {
    ItemStatus::Executed => "executed"
    ItemStatus::Failed => "failed"
  }
}

fn audit_item_json(item : AuditItem) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["effectId"] = Json::string(item.effect_id)
  obj["status"] = Json::string(item_status_string(item.status))
  obj["durationMs"] = Json::number(item.duration_ms.to_double())
  match item.reason {
    Some(reason) => obj["reason"] = @compiler.reason_json(reason)
    None => ()
  }
  Json::object(obj)
}

///|
pub fn audit_event_json(event : AuditEvent) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["entityId"] = Json::string(event.entity_id)
  obj["transitionId"] = Json::string(event.transition_id)
  obj["logicalTime"] = Json::number(event.logical_time.to_double())
  obj["sequence"] = Json::number(event.sequence.to_double())
  obj["status"] = Json::string(audit_status_string(event.status))
  let items : Array[Json] = []
  for item in event.items {
    items.push(audit_item_json(item))
  }
  obj["items"] = Json::array(items)
  let reasons : Array[Json] = []
  for reason in event.reasons {
    reasons.push(@compiler.reason_json(reason))
  }
  obj["reasons"] = Json::array(reasons)
  Json::object(obj)
}
