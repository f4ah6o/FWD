///|
/// JSON projection for effects execution result (v2.2).

///|
fn execution_status_string(status : ExecutionStatus) -> String {
  match status {
    ExecutionStatus::Executed => "executed"
    ExecutionStatus::Skipped => "skipped"
    ExecutionStatus::Failed => "failed"
  }
}

///|
fn execution_item_json(item : ExecutionItem) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["effectId"] = Json::string(item.effect_id)
  obj["status"] = Json::string(execution_status_string(item.status))
  match item.reason {
    Some(reason) => obj["reason"] = @compiler.reason_json(reason)
    None => ()
  }
  Json::object(obj)
}

///|
pub fn execution_result_json(result : ExecutionResult) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["resultVersion"] = Json::string(result.result_version)
  obj["planVersion"] = Json::string(result.plan_version)
  obj["entityId"] = Json::string(result.entity_id)
  obj["transitionId"] = Json::string(result.transition_id)
  obj["status"] = Json::string(execution_status_string(result.status))
  let items : Array[Json] = []
  for item in result.items {
    items.push(execution_item_json(item))
  }
  obj["items"] = Json::array(items)
  let reasons : Array[Json] = []
  for reason in result.reasons {
    reasons.push(@compiler.reason_json(reason))
  }
  obj["reasons"] = Json::array(reasons)
  Json::object(obj)
}
