///|
/// JSON projection for effect plans (v2.2).

///|
fn plan_status_string(status : PlanStatus) -> String {
  match status {
    PlanStatus::Planned => "planned"
    PlanStatus::Skipped => "skipped"
  }
}

///|
fn effect_kind_string(kind : @core.EffectKind) -> String {
  match kind {
    @core.EffectKind::Sync => "sync"
    @core.EffectKind::Async => "async"
  }
}

///|
fn effect_item_json(item : EffectItem) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["effectId"] = Json::string(item.effect_id)
  obj["kind"] = Json::string(effect_kind_string(item.kind))
  obj["payload"] = item.payload
  obj["idempotencyKey"] = Json::string(item.idempotency_key)
  Json::object(obj)
}

///|
pub fn effect_plan_json(plan : EffectsPlan) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["planVersion"] = Json::string(plan.plan_version)
  obj["entityId"] = Json::string(plan.entity_id)
  obj["transitionId"] = Json::string(plan.transition_id)
  obj["status"] = Json::string(plan_status_string(plan.status))
  let items : Array[Json] = []
  for item in plan.items {
    items.push(effect_item_json(item))
  }
  obj["items"] = Json::array(items)
  let reasons : Array[Json] = []
  for reason in plan.reasons {
    reasons.push(@compiler.reason_json(reason))
  }
  obj["reasons"] = Json::array(reasons)
  Json::object(obj)
}
