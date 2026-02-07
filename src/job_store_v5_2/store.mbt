///|
/// Deterministic in-memory job store (v5.2 draft).

let store : Ref[Map[String, @export_job_v5_2.JobRecord]] = @ref.new(Map::new())
let progress_total = 3

fn job_id_value(id : @export_job_v5_2.JobId) -> String {
  id.value
}

fn cancel_reason(job_id : String) -> @export_job_v5.ReasonV1 {
  {
    code: @export_job_v5.ReasonCode::JobCanceled,
    level: @export_job_v5.ReasonLevel::Error,
    target: "runtime",
    message: "job canceled: " + job_id,
    hint: Some("Job was canceled"),
  }
}

fn advance_status(status : @export_job_v5_2.JobStatus) -> @export_job_v5_2.JobStatus {
  match status {
    @export_job_v5_2.JobStatus::Queued => @export_job_v5_2.JobStatus::Running
    @export_job_v5_2.JobStatus::Running => @export_job_v5_2.JobStatus::Done
    _ => status
  }
}

fn advance_progress(progress : @export_job_v5_2.JobProgress, status : @export_job_v5_2.JobStatus) -> @export_job_v5_2.JobProgress {
  match status {
    @export_job_v5_2.JobStatus::Queued => { processed: 0, total: progress.total }
    @export_job_v5_2.JobStatus::Running => { processed: 1, total: progress.total }
    @export_job_v5_2.JobStatus::Done => { processed: progress.total, total: progress.total }
    _ => progress
  }
}

fn is_terminal(status : @export_job_v5_2.JobStatus) -> Bool {
  match status {
    @export_job_v5_2.JobStatus::Done => true
    @export_job_v5_2.JobStatus::Failed => true
    @export_job_v5_2.JobStatus::Canceled => true
    @export_job_v5_2.JobStatus::Expired => true
    _ => false
  }
}

///|
pub fn reset_for_test() -> Unit {
  @export_job_v5_2.reset_id_for_test()
  store.val = Map::new()
}

///|
pub fn create_job(
  format : @export_job_v5_2.ResultFormat,
  retention_policy : @export_job_v5_2.RetentionPolicyV52,
) -> @export_job_v5_2.JobRecord {
  let id = @export_job_v5_2.next_job_id()
  let id_value = id.value
  let job : @export_job_v5_2.JobRecord = {
    id,
    status: @export_job_v5_2.JobStatus::Queued,
    progress: { processed: 0, total: progress_total },
    retention_policy,
    generation: 1,
    format,
    reasons: [],
    poll_count: 0,
  }
  store.val[id_value] = job
  job
}

///|
pub fn get_job(id : String) -> @export_job_v5_2.JobRecord? {
  store.val.get(id)
}

///|
pub fn step_job(id : String) -> @export_job_v5_2.JobRecord? {
  match store.val.get(id) {
    Some(job) => {
      let next_poll = job.poll_count + 1
      let next_status = if is_terminal(job.status) {
        job.status
      } else {
        advance_status(job.status)
      }
      let next_progress = advance_progress(job.progress, next_status)
      let next : @export_job_v5_2.JobRecord = {
        id: job.id,
        status: next_status,
        progress: next_progress,
        retention_policy: job.retention_policy,
        generation: job.generation,
        format: job.format,
        reasons: job.reasons,
        poll_count: next_poll,
      }
      store.val[id] = next
      Some(next)
    }
    None => None
  }
}

///|
pub fn cancel_job(id : String) -> @export_job_v5_2.JobRecord? {
  match store.val.get(id) {
    Some(job) => {
      let next_status = match job.status {
        @export_job_v5_2.JobStatus::Canceled => @export_job_v5_2.JobStatus::Canceled
        @export_job_v5_2.JobStatus::Expired => @export_job_v5_2.JobStatus::Expired
        @export_job_v5_2.JobStatus::Done => @export_job_v5_2.JobStatus::Done
        @export_job_v5_2.JobStatus::Failed => @export_job_v5_2.JobStatus::Failed
        _ => @export_job_v5_2.JobStatus::Canceled
      }
      let next_reasons = match next_status {
        @export_job_v5_2.JobStatus::Canceled => [cancel_reason(job_id_value(job.id))]
        _ => job.reasons
      }
      let next : @export_job_v5_2.JobRecord = {
        id: job.id,
        status: next_status,
        progress: job.progress,
        retention_policy: job.retention_policy,
        generation: job.generation,
        format: job.format,
        reasons: next_reasons,
        poll_count: job.poll_count,
      }
      store.val[id] = next
      Some(next)
    }
    None => None
  }
}
