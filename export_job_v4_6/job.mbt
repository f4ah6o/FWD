///|
/// Export job contract (v4.6).

///|
pub(all) enum JobKind {
  Metrics
  Timeline
}

///|
pub(all) enum JobStatus {
  Queued
  Running
  Done
  Failed
}

///|
pub(all) struct MetricsJobInput {
  entity_id : String
  from_logical_time : Int?
  to_logical_time : Int?
  format : String
}

///|
pub(all) struct TimelineJobInput {
  entity_id : String
  from_logical_time : Int?
  to_logical_time : Int?
  limit : Int
  cursor : String?
  format : String
}

///|
pub(all) enum JobInput {
  Metrics(MetricsJobInput)
  Timeline(TimelineJobInput)
}

///|
pub(all) struct JobRecord {
  id : String
  kind : JobKind
  status : JobStatus
  input : JobInput
  reasons : Array[@core.Reason]
}

fn status_string(status : JobStatus) -> String {
  match status {
    JobStatus::Queued => "queued"
    JobStatus::Running => "running"
    JobStatus::Done => "done"
    JobStatus::Failed => "failed"
  }
}

fn kind_string(kind : JobKind) -> String {
  match kind {
    JobKind::Metrics => "metrics"
    JobKind::Timeline => "timeline"
  }
}

fn reasons_json(reasons : Array[@core.Reason]) -> Json {
  let items : Array[Json] = []
  for reason in reasons {
    items.push(@compiler.reason_json(reason))
  }
  Json::array(items)
}

///|
pub fn job_json(job : JobRecord, download_url : String?) -> String {
  let obj : Map[String, Json] = Map::new()
  obj["jobVersion"] = Json::string("4.6")
  obj["jobId"] = Json::string(job.id)
  obj["kind"] = Json::string(kind_string(job.kind))
  obj["status"] = Json::string(status_string(job.status))
  match download_url {
    Some(value) => obj["downloadUrl"] = Json::string(value)
    None => ()
  }
  if job.reasons.length() > 0 {
    obj["reasons"] = reasons_json(job.reasons)
  }
  Json::object(obj).stringify(indent=2)
}
