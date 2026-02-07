///|
/// v5.2 export job contract types (non-wall-clock retention exploration).

///|
pub(all) struct JobId {
  value : String
}

///|
pub(all) enum JobStatus {
  Queued
  Running
  Done
  Failed
  Canceled
  Expired
}

///|
pub(all) struct JobProgress {
  processed : Int
  total : Int
}

///|
pub(all) enum RetentionCombineV52 {
  All
}

///|
pub(all) enum RetentionAxisConditionV52 {
  PollCountMax(Int)
  GenerationMin(Int)
}

///|
pub(all) struct RetentionPolicyV52 {
  combine : RetentionCombineV52
  axes : Array[RetentionAxisConditionV52]
}

///|
pub(all) struct RetentionEvalContextV52 {
  poll_count : Int
  generation : Int
}

///|
pub(all) struct FailedAxisDetailV52 {
  axis : String
  rule : String
  expected : Int
  observed : Int
  reason : String
}

///|
pub(all) enum RetentionOutcomeV52 {
  Visible
  Hidden(Array[FailedAxisDetailV52])
}

///|
pub(all) struct RetentionDetailsV52 {
  visibility : String
  combine : String
  failed_axes : Array[FailedAxisDetailV52]
}

///|
pub(all) enum ResultFormat {
  Jsonl
  Csv
}

///|
pub(all) struct JobRecord {
  id : JobId
  status : JobStatus
  progress : JobProgress
  retention_policy : RetentionPolicyV52
  generation : Int
  format : ResultFormat
  reasons : Array[@export_job_v5.ReasonV1]
  poll_count : Int
}
