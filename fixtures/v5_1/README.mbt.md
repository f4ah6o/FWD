# v5.1 Fixtures (Delta Freeze Scaffold)

This folder contains v5.1 delta fixtures only.
Do not restate or mutate any v5.0 fixtures under `fixtures/v5/`.

## Required artifacts
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

## Layout (suggested)
```
fixtures/v5_1/
  transitions/
    case_matrix.response.json
  retry_resume/
    case_retry_clean_start.response.json
    case_resume_from_cursor.response.json
    case_partial_resume.response.json
  rollback/
    case_rollback_metadata_only.response.json
    case_full_rollback.response.json
  retention/
    case_hierarchy.response.json
    case_precedence.response.json
    case_post_expiry_visibility.response.json
  views_optional/
    case_job_view.response.json
    case_batch_view.response.json
```

## Freeze decisions (fixture-locked in current deltas)
- Rollback mode for implementation: `metadata_only`
- Tie-breaker when same-scope expiries collide at same poll-count step: `lowest_rule_id`
- Post-expiry visibility tuple:
  - results: `hidden`
  - metadata: `retained`

## Non-Goals (v5.1)
- Changing retention axis away from poll-count
- Streaming or partial result delivery
- Background workers or wall-clock scheduling
- Job API interpretation of policy outcomes
- Rewriting v5.0 fixtures, contracts, or anchors
