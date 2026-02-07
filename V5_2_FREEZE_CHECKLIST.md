# v5.2 Global Freeze Checklist (Draft, Docs-Only)

This checklist defines the entry criteria and verification steps for starting
and completing the global v5.2 freeze.
This document is planning-only and does not start freeze by itself.

## Current Status (as of now)
- v5.2 status: PLANNING
- global freeze: not started
- Batch 1 (retention semantics): draft-frozen
- Batch 2 (precedence semantics): draft-frozen
- v5.1.0 baseline: immutable

## A. Entry Criteria (Start Freeze)

### A1. Scope Closure
- [ ] In-scope surface list is explicit and final for v5.2 (no new candidates)
- [ ] Out-of-scope list is explicit (wall-clock, scheduling/background, policy interpretation)
- [ ] No `TBD` remains in the in-scope semantics sections

### A2. Fixture Readiness
- [ ] All v5.2 fixtures intended to define semantics are moved from draft markers to canonical fixture files (or a canonical naming scheme)
- [ ] Each semantic surface has a named fixture family under `fixtures/v5_2/`
- [ ] Fixture drift guards remain in place (tests) and pass

### A3. Determinism / Invariants
- [ ] Deterministic invariants are written (docs) and backed by tests:
- [ ] Stable failedAxes ordering = policy declaration order
- [ ] `combine=all` semantics (AND) for v5.2
- [ ] No retentionDetails on visible responses
- [ ] Precedence resolution order = `job > batch > system`
- [ ] `No wall-clock axis` is explicitly restated as a v5.2 non-goal

### A4. Compatibility
- [ ] v5.1 artifacts unchanged (fixtures/anchors/semantics)
- [ ] Legacy expired compatibility behavior is documented and tested
- [ ] ReasonV1 compatibility is preserved and stated

## B. Freeze Start Procedure (Docs + Tagging Discipline)
- [ ] Set `V5_2_PLAN.md`:
- [ ] `Freeze status: started`
- [ ] `Scope status: closed`
- [ ] Record freeze commit hash as the freeze anchor
- [ ] Declare that all subsequent changes require fixture-first updates, explicit versioned artifacts, and reviewer sign-off for semantic changes

## C. Freeze Verification (Before Declaring Complete)

### C1. Test Gates
- [ ] `moon test src/retention_v5_2` passes
- [ ] `moon test src/api_v5_2` passes
- [ ] Batch 1 fixture shape sync checks pass
- [ ] Batch 2 precedence tests pass

### C2. Fixture Authority Gates
- [ ] Canonical fixture set exists (no draft markers for authoritative fixtures)
- [ ] Each canonical fixture has a corresponding test asserting:
- [ ] Status code
- [ ] Presence/absence of retentionDetails
- [ ] failedAxes nesting + required fields
- [ ] Endpoint marker correctness for result

### C3. Documentation Gates
- [ ] `V5_2_RETENTION_MULTI_AXIS_DRAFT.md` is either promoted to non-draft spec or explicitly marked as frozen semantics reference
- [ ] Non-goals are re-asserted in final freeze notes

## D. Freeze Completion Procedure
- [ ] Set `V5_2_PLAN.md`:
- [ ] `Freeze status: complete`
- [ ] Create immutable reference (tag or documented commit) for v5.2 freeze point
- [ ] Record post-freeze change rules:
- [ ] Semantics changes require v5.3 or explicitly versioned v5.2.x artifacts

## E. Explicit Non-Goals (Must Remain True for v5.2)
- [ ] No wall-clock retention axis
- [ ] No scheduling/background worker model
- [ ] No policy/job interpretation beyond existing boundary
- [ ] No changes to v5.1 fixtures/anchors
