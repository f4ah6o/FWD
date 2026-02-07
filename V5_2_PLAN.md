# v5.2 Plan (Open)

This document opens v5.2 planning.
It does not freeze semantics.

## Baseline
- v5.1.0 is the immutable upstream baseline.
- v5.0 and v5.1 fixtures/anchors remain unchanged unless explicitly versioned as v5.2 artifacts.

## Planning Status
- State: `open`
- Freeze status: `not started`
- Scope status: `focused exploration`

## Draft Freeze Marker (Scoped)
- Retention Batch 1 semantics are `draft-frozen` in v5.2 planning scope.
- Coverage (as implemented + tested):
  - `visible_all_pass`
  - `hidden_poll_only`
  - `hidden_generation_only`
  - `hidden_multi_fail`
  - `result_endpoint_hidden`
  - `compat_legacy_expired_read`
- Explicitly excluded from this marker:
  - precedence logic (Batch 2)
  - wall-clock axis
  - scheduling/background worker semantics
- Global freeze status remains `not started`.

## Draft Freeze Marker (Scoped: Batch 2 Precedence)
- Retention Batch 2 precedence semantics are `draft-frozen` in v5.2 planning scope.
- Covered precedence rule:
  - `job > batch > system`
- Batch 1 draft-freeze remains unchanged.
- No additional semantics are frozen by this marker.
- Global freeze status remains `not started`.

## Planning Direction (Non-Binding)
- v5.2 planning focus: generalize retention from single-axis poll-count to multi-axis retention.
- Explicit exclusion in this planning direction: wall-clock axis is not introduced in v5.2 scope.
- This direction is exploratory and does not start freeze.

## Working Proposal Reference (Non-Binding)
- See `V5_2_RETENTION_MULTI_AXIS_DRAFT.md`.
- Any API/algorithm behavior in that document is a working proposal for comparison, not a frozen contract.

## Candidate Scope (Parking Lot)
- Streaming or partial result delivery
- Wall-clock scheduling or background worker model
- Retention axis expansion beyond poll-count
- Additional lifecycle semantics not representable as v5.1 delta
- Policy/job integration changes beyond v5.1 non-interpreting boundary

## v5.2 Guardrails
- Keep delta-first versioning discipline.
- Encode semantics through fixtures before implementation changes.
- Separate core decisions from optional surfaces.
- Record explicit non-goals for each freeze cycle.

## Entry Criteria For Draft Freeze
- Candidate scope narrowed to a minimal coherent set.
- New fixture families named and scaffolded under `fixtures/v5_2/`.
- Deterministic invariants written before runtime behavior changes.
