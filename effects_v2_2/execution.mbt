///|
/// Effects execution result (v2.2 stub).

///|
pub(all) enum ExecutionStatus {
  Executed
  Skipped
  Failed
}

///|
pub(all) struct ExecutionItem {
  effect_id : String
  status : ExecutionStatus
  reason : @core.Reason?
}

///|
pub(all) struct ExecutionResult {
  result_version : String
  plan_version : String
  entity_id : String
  transition_id : String
  status : ExecutionStatus
  items : Array[ExecutionItem]
  reasons : Array[@core.Reason]
}

///|
pub fn result_version_v2_2() -> String {
  "2.2"
}

///|
fn item_status_executed(effect_id : String) -> ExecutionItem {
  { effect_id, status: ExecutionStatus::Executed, reason: None }
}

///|
pub fn execute_plan_stub(plan : EffectsPlan) -> ExecutionResult {
  match plan.status {
    PlanStatus::Planned => {
      let items : Array[ExecutionItem] = []
      for item in plan.items {
        items.push(item_status_executed(item.effect_id))
      }
      {
        result_version: result_version_v2_2(),
        plan_version: plan.plan_version,
        entity_id: plan.entity_id,
        transition_id: plan.transition_id,
        status: ExecutionStatus::Executed,
        items,
        reasons: [],
      }
    }
    PlanStatus::Skipped => {
      {
        result_version: result_version_v2_2(),
        plan_version: plan.plan_version,
        entity_id: plan.entity_id,
        transition_id: plan.transition_id,
        status: ExecutionStatus::Skipped,
        items: [],
        reasons: plan.reasons,
      }
    }
  }
}
