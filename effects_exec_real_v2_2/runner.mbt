///|
/// Config-based runner (v2.2).

///|
fn merge_reasons(items : Array[@effects_v2_2.ExecutionItem]) -> Array[@core.Reason] {
  let reasons : Array[@core.Reason] = []
  for item in items {
    match item.reason {
      Some(value) => reasons.push(value)
      None => ()
    }
  }
  reasons
}

///|
fn status_from_items(items : Array[@effects_v2_2.ExecutionItem]) -> @effects_v2_2.ExecutionStatus {
  for item in items {
    match item.status {
      @effects_v2_2.ExecutionStatus::Failed => return @effects_v2_2.ExecutionStatus::Failed
      _ => ()
    }
  }
  @effects_v2_2.ExecutionStatus::Executed
}

///|
pub fn execute_with_transport(
  plan : @effects_v2_2.EffectsPlan,
  config : RunnerConfig,
  send : (@effects_exec_adapters_v2_2.HttpRequest) -> Result[@effects_exec_adapters_v2_2.HttpResponse, @core.Reason],
) -> @effects_v2_2.ExecutionResult {
  match plan.status {
    @effects_v2_2.PlanStatus::Skipped => {
      {
        result_version: @effects_v2_2.result_version_v2_2(),
        plan_version: plan.plan_version,
        entity_id: plan.entity_id,
        transition_id: plan.transition_id,
        status: @effects_v2_2.ExecutionStatus::Skipped,
        items: [],
        reasons: plan.reasons,
      }
    }
    @effects_v2_2.PlanStatus::Planned => {
      let items : Array[@effects_v2_2.ExecutionItem] = []
      for item in plan.items {
        match @effects_exec_adapters_v2_2.run_http_effect(
          config.allowlist,
          item,
          send,
        ) {
          Ok(executed) => items.push(executed)
          Err(reason) => items.push({
            effect_id: item.effect_id,
            status: @effects_v2_2.ExecutionStatus::Failed,
            reason: Some(reason),
          })
        }
      }
      {
        result_version: @effects_v2_2.result_version_v2_2(),
        plan_version: plan.plan_version,
        entity_id: plan.entity_id,
        transition_id: plan.transition_id,
        status: status_from_items(items),
        items,
        reasons: merge_reasons(items),
      }
    }
  }
}
