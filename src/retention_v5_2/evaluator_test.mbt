///|
fn default_policy() -> @export_job_v5_2.RetentionPolicyV52 {
  {
    combine: @export_job_v5_2.RetentionCombineV52::All,
    axes: [
      @export_job_v5_2.RetentionAxisConditionV52::PollCountMax(3),
      @export_job_v5_2.RetentionAxisConditionV52::GenerationMin(2),
    ],
  }
}

///|
test "retention v5.2 all pass" {
  let out = evaluate_retention_v52(default_policy(), { poll_count: 3, generation: 2 })
  match out {
    @export_job_v5_2.RetentionOutcomeV52::Visible => ()
    _ => fail("expected visible")
  }
}

///|
test "retention v5.2 poll fail" {
  let out = evaluate_retention_v52(default_policy(), { poll_count: 4, generation: 2 })
  let failed = match out {
    @export_job_v5_2.RetentionOutcomeV52::Hidden(items) => items
    _ => fail("expected hidden")
  }
  inspect(failed.length(), content="1")
  inspect(failed[0].axis, content="poll_count")
  inspect(failed[0].reason, content="EXPIRED_BY_POLL_COUNT")
}

///|
test "retention v5.2 generation fail" {
  let out = evaluate_retention_v52(default_policy(), { poll_count: 1, generation: 1 })
  let failed = match out {
    @export_job_v5_2.RetentionOutcomeV52::Hidden(items) => items
    _ => fail("expected hidden")
  }
  inspect(failed.length(), content="1")
  inspect(failed[0].axis, content="generation")
  inspect(failed[0].reason, content="EXPIRED_BY_GENERATION")
}

///|
test "retention v5.2 both fail order is policy order" {
  let out = evaluate_retention_v52(default_policy(), { poll_count: 7, generation: 1 })
  let failed = match out {
    @export_job_v5_2.RetentionOutcomeV52::Hidden(items) => items
    _ => fail("expected hidden")
  }
  inspect(failed.length(), content="2")
  inspect(failed[0].axis, content="poll_count")
  inspect(failed[1].axis, content="generation")
}
