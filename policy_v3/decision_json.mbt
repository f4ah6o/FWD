///|
/// JSON projection for policy decisions (v3).

fn decision_string(decision : PolicyDecisionKind) -> String {
  match decision {
    PolicyDecisionKind::Allow => "allow"
    PolicyDecisionKind::Deny => "deny"
  }
}

///|
pub fn policy_decision_json(decision : PolicyDecision) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["entityId"] = Json::string(decision.entity_id)
  obj["transitionId"] = Json::string(decision.transition_id)
  obj["decision"] = Json::string(decision_string(decision.decision))
  let reasons : Array[Json] = []
  for reason in decision.reasons {
    reasons.push(@compiler.reason_json(reason))
  }
  obj["reasons"] = Json::array(reasons)
  Json::object(obj)
}
