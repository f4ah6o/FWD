# v5.1 Plan (Draft) — Delta Only

This document describes **v5.1 deltas only**. It MUST NOT restate v5.0 contracts. All v5.0 fixtures and anchors remain immutable.

## Scope (v5.1)
1) Job/Batch lifecycle extensions (resume/retry/partial resume + rollback semantics)
2) Retention evaluation extensions (poll-count axis remains fixed)
3) Optional: Observability granularity (read-only, opt-in views)
4) Optional: Policy explanations/classification (policy-only; job APIs remain non-interpreting)

## Lifecycle Extensions (Job/Batch) — Delta
### New concepts (v5.1)
- **Retry**: re-execution of a job without changing its identity.
- **Resume**: continuation after interruption using a deterministic resume cursor.
- **Partial resume**: resume only for failed/unfinished units (batch children or job segments).
- **Rollback**: deterministic cleanup semantics for batch cancellation.

### Status model delta (explicit transition additions)
Define a **transition delta**, not a new base model. The v5.0 transitions remain valid.

New statuses (proposed):
- `paused`
- `retrying`
- `resuming`
- `rolled_back`

**Allowed new transitions (delta):**
- `running -> paused` (explicit pause)
- `paused -> resuming` (resume requested)
- `resuming -> running` (resume accepted)
- `running -> retrying` (retry requested)
- `retrying -> running` (retry accepted)
- `running -> rolled_back` (rollback applied)
- `paused -> rolled_back` (rollback applied)

**Forbidden transitions (delta):**
- Any transition that skips `paused|retrying|resuming` staging states
- `done -> retrying|resuming|paused`
- `failed -> paused` (must retry or remain failed)

### Resume/Retry semantics (deterministic)
- Resume/retry requests MUST be explicit endpoints (no implicit retries).
- Resume cursor MUST be opaque and fixture-driven.
- Resume/retry MUST be deterministic given the same fixture inputs.
- Partial resume MUST operate on a deterministic unit list (batch children or job segments).

### Batch rollback semantics
- Rollback semantics MUST be deterministic and fixture-driven.
- Two modes (pick one in implementation; freeze in fixtures):
  - `metadata_only` rollback (results retained, only state changes)
  - `full_rollback` (results tombstoned)
- Batch rollback MUST cascade deterministically to children.

## Retention Evaluation Extensions (Poll-Count Axis Only)
- The retention axis remains **poll-count only** (unchanged).
- v5.1 adds **evaluation rules** only (no axis change):
  - hierarchical retention (job / batch / system) with deterministic precedence
  - post-expiry visibility rules (metadata vs results)

### Deterministic evaluation rules (delta)
- Precedence MUST be explicit (e.g., job overrides batch overrides system).
- Expiry evaluation MUST be deterministic per poll-count step.
- Visibility after expiry MUST be fixture-locked:
  - results: hidden or tombstoned
  - metadata: retained or tombstoned

## Optional: Observability Granularity (Read-only)
- Add opt-in views (no change to global-only v5.0 view):
  - per-job view
  - per-batch view
- These views MUST be read-only and deterministic.

## Optional: Policy Explanation/Classification
- Policy responses MAY add explanation fields (policy-only).
- Job APIs MUST NOT interpret or enforce policy semantics.
- Reason v1 remains the base; explanations are additive and policy-only.

## Non-Goals (v5.1)
- Changing retention axis away from poll-count
- Streaming/partial result delivery
- Background worker or wall-clock scheduling
- Job API interpreting policy outcomes
- Rewriting v5.0 fixtures or contracts

## Required Artifacts for v5.1 Freeze
- Transition delta fixtures (resume/retry/rollback paths)
- Retention evaluation fixtures (hierarchy + visibility)
- Optional view fixtures (if included)
- Explicit Non-Goals section in the v5.1 anchor
