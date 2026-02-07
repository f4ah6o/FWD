///|
/// Deterministic retention evaluator for v5.2 draft.

///|
pub fn evaluate_retention_v52(
  policy : @export_job_v5_2.RetentionPolicyV52,
  ctx : @export_job_v5_2.RetentionEvalContextV52,
) -> @export_job_v5_2.RetentionOutcomeV52 {
  let failed : Array[@export_job_v5_2.FailedAxisDetailV52] = []
  for axis in policy.axes {
    match axis {
      @export_job_v5_2.RetentionAxisConditionV52::PollCountMax(limit) => {
        if ctx.poll_count > limit {
          failed.push({
            axis: "poll_count",
            rule: "max",
            expected: limit,
            observed: ctx.poll_count,
            reason: "EXPIRED_BY_POLL_COUNT",
          })
        }
      }
      @export_job_v5_2.RetentionAxisConditionV52::GenerationMin(minimum) => {
        if ctx.generation < minimum {
          failed.push({
            axis: "generation",
            rule: "min",
            expected: minimum,
            observed: ctx.generation,
            reason: "EXPIRED_BY_GENERATION",
          })
        }
      }
    }
  }
  if failed.length() == 0 {
    @export_job_v5_2.RetentionOutcomeV52::Visible
  } else {
    @export_job_v5_2.RetentionOutcomeV52::Hidden(failed)
  }
}

///|
pub fn retention_details(
  policy : @export_job_v5_2.RetentionPolicyV52,
  failed_axes : Array[@export_job_v5_2.FailedAxisDetailV52],
) -> @export_job_v5_2.RetentionDetailsV52 {
  {
    visibility: "hidden",
    combine: match policy.combine {
      @export_job_v5_2.RetentionCombineV52::All => "all"
    },
    failed_axes,
  }
}
