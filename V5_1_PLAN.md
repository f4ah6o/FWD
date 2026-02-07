# v5.1 Plan (Draft) — Delta Only (Reviewer-Adjusted)

This document describes **v5.1 deltas only**. It MUST NOT restate v5.0 contracts.
All v5.0 fixtures, anchors, identities, and semantics remain immutable.

## Scope (v5.1)

1) Job/Batch lifecycle extensions (resume / retry / partial resume + rollback semantics)  
2) Retention evaluation extensions (poll-count axis remains fixed)  
3) Optional: Observability granularity (read-only, opt-in views)  
4) Optional: Policy explanations / classification (policy-only; job APIs remain non-interpreting)

## Lifecycle Extensions (Job/Batch) — Delta

### New concepts (v5.1)

- **Retry**  
  Re-execution of a job **from a clean start** within the same job identity.
  No resume cursor is used.

- **Resume**  
  Continuation after interruption **from a persisted deterministic resume cursor**.

- **Partial resume**  
  Resume applied only to a deterministic subset of units
  (e.g. batch children or job segments).

- **Rollback**  
  Deterministic cleanup semantics applied to batch cancellation.

### Status model delta (explicit transition additions)

This section defines a **transition delta only**.
All v5.0 statuses and transitions remain valid.

#### New statuses
- `paused`
- `retrying`
- `resuming`
- `rolled_back`

#### Allowed new transitions (delta)

- `running -> paused` (explicit pause)
- `paused -> resuming` (resume requested)
- `resuming -> running` (resume accepted)
- `running -> retrying` (retry requested)
- `retrying -> running` (retry accepted)
- `running -> rolled_back` (rollback applied)
- `paused -> rolled_back` (rollback applied)

#### Forbidden transitions (delta)

- Any transition that skips `paused | retrying | resuming` staging states
- `done -> retrying | resuming | paused`
- `failed -> paused` (must retry or remain failed)

### Resume / Retry semantics (deterministic)

- Resume and retry MUST be explicit endpoints (no implicit retries).
- Resume cursor MUST be opaque and fixture-driven.
- Resume and retry MUST be deterministic given the same fixture inputs.
- Retry always re-enters execution from the start.
- Resume always continues from a previously persisted cursor.
- Partial resume MUST operate on a deterministic unit list.
  - Unit granularity is fixed per fixture
    (e.g. `batch_children`, `job_segments`).

### Batch rollback semantics

- Rollback semantics MUST be deterministic and fixture-driven.
- Rollback MUST NOT affect:
  - job identity
  - creation timestamp
  - fixture anchors

#### Rollback modes (implementation must pick one and freeze in fixtures)

- `metadata_only`
  - results retained
  - only state transitions applied

- `full_rollback`
  - results tombstoned
  - state transitions applied

- Batch rollback MUST cascade deterministically to all children.

## Retention Evaluation Extensions (Poll-Count Axis Only)

- Retention axis remains **poll-count only** (unchanged).
- v5.1 adds **evaluation rules only**.

### Deterministic evaluation rules (delta)

- Retention hierarchy is explicit:
  - job > batch > system
- Higher-precedence scopes always override lower ones.
- If multiple expiries apply at the same poll-count:
  - precedence wins
  - ties within the same scope are resolved by fixture-defined rule
- Expiry evaluation MUST be deterministic per poll-count step.

### Post-expiry visibility (fixture-locked)

- Results:
  - hidden OR tombstoned
- Metadata:
  - retained OR tombstoned

No other post-expiry states are allowed.

## Optional: Observability Granularity (Read-only)

- Opt-in read-only views MAY be added:
  - per-job view
  - per-batch view
- These views:
  - expose only data already visible in the global view
  - introduce no new information
  - remain fully deterministic

## Optional: Policy Explanation / Classification

- Policy responses MAY include explanation fields.
- Reason v1 remains the base.
- Explanations are additive and policy-only.
- Job APIs MUST NOT interpret or enforce policy semantics.

## Non-Goals (v5.1)

- Changing retention axis away from poll-count
- Streaming or partial result delivery
- Background workers or wall-clock scheduling
- Job API interpretation of policy outcomes
- Rewriting v5.0 fixtures, contracts, or anchors

## Required Artifacts for v5.1 Freeze

- Transition delta fixtures
  - retry
  - resume
  - partial resume
  - rollback
- Retention evaluation fixtures
  - hierarchy
  - precedence
  - post-expiry visibility
- Optional view fixtures (if included)
- Explicit Non-Goals section in the v5.1 anchor
