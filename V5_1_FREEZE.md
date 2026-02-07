# v5.1 Freeze Anchor (Core)

This anchor freezes v5.1 core semantics as complete and additive to v5.0.

## Frozen scope (complete)
- Lifecycle axis
  - retry (`case_retry_clean_start.response.json`)
  - resume (`case_resume_from_cursor.response.json`)
  - partial resume (`case_partial_resume.response.json`)
  - rollback metadata-only (`case_rollback_metadata_only.response.json`)
- Retention axis (poll-count only)
  - hierarchy (`case_hierarchy.response.json`)
  - precedence + same-scope tie-break (`case_precedence.response.json`)
  - post-expiry visibility (`case_post_expiry_visibility.response.json`)

## Locked decisions
- Rollback mode: `metadata_only`
- Same-scope tie-break rule: `lowest_rule_id`
- Post-expiry visibility tuple:
  - results: `hidden`
  - metadata: `retained`

## Remaining optional work
- Read-only optional views only:
  - `case_job_view.response.json`
  - `case_batch_view.response.json`

## Invariants
- v5.0 fixtures, anchors, identities, and semantics remain immutable.
- No retention axis changes beyond poll-count.
- No job API interpretation of policy outcomes.
