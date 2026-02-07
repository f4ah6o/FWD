///|
/// Batch job contract types (v5.2 draft).

///|
pub(all) struct BatchChildSpec {
  entity_id : String
  from_logical_time : Int
  to_logical_time : Int
}

///|
pub let default_poll_max : Int = 3
pub let default_generation_min : Int = 1

///|
pub(all) struct BatchJobRecord {
  id : String
  child_ids : Array[String]
  child_specs : Array[BatchChildSpec]
  status : @export_job_v5_2.JobStatus
  progress : @export_job_v5_2.JobProgress
  retention_policy : @export_job_v5_2.RetentionPolicyV52
  generation : Int
  format : @export_job_v5_2.ResultFormat
  reasons : Array[@export_job_v5.ReasonV1]
  poll_count : Int
  next_child_index : Int
}
