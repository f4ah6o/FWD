///|
/// Pure effect planner (v2.2).

///|
fn empty_payload() -> Json {
  Json::object(Map::new())
}

///|
fn idempotency_key(entity_id : String, transition_id : String, effect_id : String) -> String {
  entity_id + ":" + transition_id + ":" + effect_id
}

///|
fn effect_item_from_execution(
  entity_id : String,
  transition_id : String,
  effect : @runtime.ExecutionEffect,
) -> EffectItem {
  {
    effect_id: effect.name,
    kind: effect.kind,
    payload: empty_payload(),
    idempotency_key: idempotency_key(entity_id, transition_id, effect.name),
  }
}

///|
pub fn plan_from_execution(
  entity_id : String,
  outcome : @runtime.ExecutionOutcome,
) -> EffectsPlan {
  match outcome {
    @runtime.ExecutionOutcome::Executed(executed) => {
      let items : Array[EffectItem] = []
      for effect in executed.effects {
        items.push(effect_item_from_execution(entity_id, executed.id, effect))
      }
      {
        plan_version: plan_version_v2_2(),
        entity_id,
        transition_id: executed.id,
        status: PlanStatus::Planned,
        items,
        reasons: [],
      }
    }
    @runtime.ExecutionOutcome::Blocked(blocked) => {
      {
        plan_version: plan_version_v2_2(),
        entity_id,
        transition_id: blocked.id,
        status: PlanStatus::Skipped,
        items: [],
        reasons: blocked.reasons,
      }
    }
  }
}
