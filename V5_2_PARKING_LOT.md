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
- `problem`: `Large result sets require incremental client consumption.`
- `why_not_v5_1_delta`: `v5.1 non-goals explicitly excluded streaming delivery semantics.`
- `candidate_fixtures`: `fixtures/v5_2/candidates/streaming/`
- `deterministic_invariants`: `TBD`
- `non_goals`: `TBD`
- `open_questions`: `Chunk boundary contract, cursor semantics, terminal state signaling.`

- `id`: `v5_2_candidate_scheduling_001`
- `title`: `Wall-clock scheduling / background workers`
- `problem`: `Execution timing and async processing are currently out of scope.`
- `why_not_v5_1_delta`: `v5.1 non-goals excluded wall-clock scheduling and workers.`
- `candidate_fixtures`: `fixtures/v5_2/candidates/scheduling/`
- `deterministic_invariants`: `TBD`
- `non_goals`: `TBD`
- `open_questions`: `Clock abstraction, retry timing, queue semantics, cancellation windows.`

- `id`: `v5_2_candidate_retention_axis_001`
- `title`: `Retention axis expansion beyond poll-count`
- `problem`: `Poll-count-only retention may not satisfy external retention policies.`
- `why_not_v5_1_delta`: `v5.1 locked poll-count as the only retention axis.`
- `candidate_fixtures`: `fixtures/v5_2/candidates/retention_axis/`
- `deterministic_invariants`: `TBD`
- `non_goals`: `TBD`
- `open_questions`: `Precedence with poll-count, tie-break behavior, visibility migration.`

- `id`: `v5_2_candidate_lifecycle_001`
- `title`: `Lifecycle semantics beyond v5.1 staging model`
- `problem`: `Potential new control states or transitions may be required.`
- `why_not_v5_1_delta`: `v5.1 lifecycle delta is already frozen.`
- `candidate_fixtures`: `fixtures/v5_2/candidates/lifecycle/`
- `deterministic_invariants`: `TBD`
- `non_goals`: `TBD`
- `open_questions`: `Compatibility with existing status matrix and rollback rules.`

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
