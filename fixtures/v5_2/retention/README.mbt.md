# v5.2 Retention Fixture Drafts (Non-Authoritative)

These files are planning-time comparison drafts.
They are not canonical fixtures and do not freeze semantics.

## Batch 1 (visibility + reasons)
- case_visible_all_pass.draft.response.json
- case_hidden_poll_only.draft.response.json
- case_hidden_generation_only.draft.response.json
- case_hidden_multi_fail.draft.response.json
- case_result_endpoint_hidden.draft.response.json
- case_compat_legacy_expired_read.draft.response.json

## Batch 2 (precedence)
- case_precedence_job_over_batch_over_system.draft.response.json

## Notes
- Hidden API shape currently uses a 404 candidate in this draft set.
- Scope precedence and failed-axis ordering are planning baselines only.
