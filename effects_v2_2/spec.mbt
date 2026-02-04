///|
/// Effects planning spec (v2.2).

///|
pub(all) enum PlanStatus {
  Planned
  Skipped
}

///|
pub(all) struct EffectItem {
  effect_id : String
  kind : @core.EffectKind
  payload : Json
  idempotency_key : String
}

///|
pub(all) struct EffectsPlan {
  plan_version : String
  entity_id : String
  transition_id : String
  status : PlanStatus
  items : Array[EffectItem]
  reasons : Array[@core.Reason]
}

///|
pub fn plan_version_v2_2() -> String {
  "2.2"
}
