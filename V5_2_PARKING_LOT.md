# v5.2 Parking Lot

This file tracks candidate scope for v5.2.
Entries are ideas, not commitments.

## Candidate Template
- `id`:
- `title`:
- `problem`:
- `why_not_v5_1_delta`:
- `candidate_fixtures`:
- `deterministic_invariants`:
- `non_goals`:
- `open_questions`:

## Seed Candidates
- `id`: `v5_2_candidate_streaming_001`
- `title`: `Streaming / partial result delivery`
- `problem`: `Large result sets force clients to wait for full materialization, which increases timeout risk and makes progressive UX difficult in long-running exports.`
- `why_not_v5_1_delta`: `v5.1 result APIs are shaped around complete retrieval and do not include a partial-delivery surface.`
- `candidate_fixtures`: `fixtures/v5_2/candidates/streaming/`
- `touches_scheduling_or_policy_integration`: `no`
- `deterministic_invariants`: `TBD`
- `non_goals`: `TBD`
- `open_questions`: `What unit defines a stream chunk (row, byte window, logical page); how stream cursors relate to existing result cursors; how completion is represented when stream output is truncated or empty.`

- `id`: `v5_2_candidate_scheduling_001`
- `title`: `Wall-clock scheduling / background workers`
- `problem`: `Execution timing and async processing are currently out of scope.`
- `why_not_v5_1_delta`: `v5.1 non-goals excluded wall-clock scheduling and workers.`
- `candidate_fixtures`: `fixtures/v5_2/candidates/scheduling/`
- `deterministic_invariants`: `TBD`
- `non_goals`: `TBD`
- `open_questions`: `Clock abstraction, retry timing, queue semantics, cancellation windows.`

- `id`: `v5_2_candidate_retention_axis_001`
- `title`: `Retention multi-axis generalization (without wall-clock)`
- `problem`: `Single-axis poll-count retention cannot represent some domain-specific lifecycle signals that are not time-based but still need deterministic expiry decisions.`
- `why_not_v5_1_delta`: `v5.1 fixes retention to poll-count-only evaluation, so adding non-time secondary axes is outside that frozen contract.`
- `candidate_fixtures`: `fixtures/v5_2/candidates/retention_axis/`
- `touches_scheduling_or_policy_integration`: `no`
- `deterministic_invariants`: `TBD`
- `non_goals`: `Introduce wall-clock as a retention axis in v5.2.`
- `open_questions`: `Which non-time axes are representable from existing deterministic state; how cross-axis precedence is expressed when poll-count and secondary axes diverge; how post-expiry visibility remains legible across axes without redefining lifecycle states.`

- `id`: `v5_2_candidate_lifecycle_001`
- `title`: `Lifecycle semantics beyond v5.1 staging model`
- `problem`: `Current staged lifecycle may not describe operator workflows such as longer operator holds, multi-phase restart paths, or richer interruption taxonomies.`
- `why_not_v5_1_delta`: `v5.1 lifecycle transitions and staging states are frozen as delta-complete for that release line.`
- `candidate_fixtures`: `fixtures/v5_2/candidates/lifecycle/`
- `touches_scheduling_or_policy_integration`: `yes`
- `touch_note`: `Lifecycle expansions can pull in scheduling-style execution windows when pause/resume intent is time-aware.`
- `deterministic_invariants`: `TBD`
- `non_goals`: `TBD`
- `open_questions`: `Which additional operator-visible states are meaningfully distinct from existing staging; how transition readability is preserved as the matrix grows; how rollback narratives remain understandable with added state paths.`

- `id`: `v5_2_candidate_policy_integration_001`
- `title`: `Policy/job integration beyond non-interpreting boundary`
- `problem`: `Some flows may require policy-aware execution decisions.`
- `why_not_v5_1_delta`: `v5.1 locked job APIs as non-interpreting for policy outcomes.`
- `candidate_fixtures`: `fixtures/v5_2/candidates/policy_integration/`
- `deterministic_invariants`: `TBD`
- `non_goals`: `TBD`
- `open_questions`: `Interpretation boundary, explainability, failure mapping.`

## Initial Out-of-Scope (Non-Binding)
- `v5_2_candidate_scheduling_001`: depends on wall-clock and background execution assumptions that would require cross-cutting runtime model changes.
- `v5_2_candidate_policy_integration_001`: assumes crossing the v5.1 non-interpreting boundary and would require semantics that span policy and job layers.

## Draft Focus Candidate (Non-Binding)
- `current_focus`: `v5_2_candidate_retention_axis_001`
- `focus_note`: `This focus explores multi-axis retention generalization with poll-count retained and wall-clock excluded.`
- `scope_note`: `Other in-scope candidates remain active in intake.`
- `freeze_note`: `No freeze, commitment, or prioritization is implied by this marker.`

## Retention Working Proposal Snapshot (Non-Binding)
- `axis_min_set`: `poll_count_max + generation_min`
- `combine_candidate`: `all (AND)`
- `eval_timing_candidate`: `read-time only (GET / RESULT)`
- `hidden_api_candidate`: `404 + ReasonV1 + retentionDetails`
- `failed_axes_candidate`: `return all failed axes in policy order`
- `precedence_candidate`: `job > batch > system (same as current, planning baseline)`
- `fixture_batches`: `Batch 1 = visibility+reasons, Batch 2 = precedence`
