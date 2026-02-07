# v5.2 Retention Multi-Axis Draft (no wall-clock, pre-freeze / non-binding)

This document is a working proposal for focused exploration in v5.2.
It is not a freeze artifact and does not commit semantics.

## Batch 1 Draft-Frozen Scope
- The following Batch 1 behaviors are draft-frozen as currently implemented and tested:
  - `visible_all_pass`
  - `hidden_poll_only`
  - `hidden_generation_only`
  - `hidden_multi_fail`
  - `result_endpoint_hidden`
  - `compat_legacy_expired_read`
- Batch 2 precedence remains open draft scope.
- This marker does not start global v5.2 freeze.

## Batch 2 Draft-Frozen Scope (Precedence)
- Batch 2 precedence behavior is draft-frozen as currently implemented and tested:
  - `job > batch > system`
- Batch 1 draft-frozen scope remains unchanged.
- No additional semantics are frozen by this marker.
- This marker does not start global v5.2 freeze.

## Summary
- Target: generalize retention from single-axis poll-count to multi-axis (non-time axes only).
- Baseline: v5.1.0 semantics remain immutable.
- Positioning: retention is planned as a visibility filter in the observability layer.

## Working Proposal (Non-Binding)
- Retention filters visibility, not physical deletion.
- Retention does not change state-machine transitions.
- Poll-count is one axis among multiple planned axes.
- Axis composition is planned with `combine=all` (AND) for comparison.
- Evaluation is planned at read time (`GET` / `RESULT`) only.
- Hidden responses are currently planned with a `404 + ReasonV1 + retentionDetails` candidate shape.
- Failed-axis reasons are planned to include all failed axes in policy order.

## Planned Minimal Axis Set (Non-Binding)
- `poll_count_max`
- `generation_min`

Wall-clock axis is out of scope for v5.2 planning.

## Evaluation Inputs (Working Assumptions, Non-Binding)
Evaluation context is planned to be internal-derived and deterministic:
- `poll_count`
- `generation`

No wall-clock inputs are used.

## API Candidate Behavior (Non-Binding)
- Create endpoints may accept optional `retentionPolicy`.
- If policy is absent, poll-only default behavior is used for compatibility.
- Hidden API representation is currently a 404 candidate (not frozen).

## Compatibility Working Assumption (Non-Binding)
- Existing `job > batch > system` precedence is used as a planning baseline.
- Existing legacy expired records remain readable under compatibility behavior.

## Fixture Draft Batches (Non-Authoritative)
### Batch 1
- `visible_all_pass`
- `hidden_poll_only`
- `hidden_generation_only`
- `hidden_multi_fail` (failed-axis order follows policy order)
- `result_endpoint_hidden`
- `compat_legacy_expired_read`

### Batch 2
- `precedence_job_over_batch_over_system`

These fixtures are draft comparison artifacts and not canonical contracts.
