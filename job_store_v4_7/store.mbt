///|
/// Deterministic in-memory job store (v4.7).

let counter : Ref[Int] = @ref.new(0)
let store : Ref[Map[String, @export_job_v4_7.JobRecord]] = @ref.new(Map::new())

let ttl_seconds = 120
let ttl_polls = 5
let progress_total = 3

fn next_status(status : @export_job_v4_7.JobStatus) -> @export_job_v4_7.JobStatus {
  match status {
    @export_job_v4_7.JobStatus::Queued => @export_job_v4_7.JobStatus::Running
    @export_job_v4_7.JobStatus::Running => @export_job_v4_7.JobStatus::Done
    @export_job_v4_7.JobStatus::Done => @export_job_v4_7.JobStatus::Done
    @export_job_v4_7.JobStatus::Failed => @export_job_v4_7.JobStatus::Failed
  }
}

fn next_progress(progress : @export_job_v4_7.JobProgress, status : @export_job_v4_7.JobStatus) -> @export_job_v4_7.JobProgress {
  match status {
    @export_job_v4_7.JobStatus::Queued => { processed: 0, total: progress.total }
    @export_job_v4_7.JobStatus::Running => { processed: 1, total: progress.total }
    @export_job_v4_7.JobStatus::Done => { processed: progress.total, total: progress.total }
    @export_job_v4_7.JobStatus::Failed => progress
  }
}

///|
pub fn reset_for_test() -> Unit {
  counter.val = 0
  store.val = Map::new()
}

///|
pub fn create_job(
  kind : @export_job_v4_7.JobKind,
  input : @export_job_v4_7.JobInput,
) -> @export_job_v4_7.JobRecord {
  counter.val = counter.val + 1
  let id = "job-" + counter.val.to_string()
  let job : @export_job_v4_7.JobRecord = {
    id,
    kind,
    status: @export_job_v4_7.JobStatus::Queued,
    input,
    progress: { processed: 0, total: progress_total },
    ttl_seconds,
    reasons: [],
    poll_count: 0,
  }
  store.val[id] = job
  job
}

fn is_expired(job : @export_job_v4_7.JobRecord) -> Bool {
  job.poll_count >= ttl_polls
}

///|
pub fn get_job(id : String) -> (@export_job_v4_7.JobRecord?, Bool) {
  match store.val.get(id) {
    Some(job) => (Some(job), is_expired(job))
    None => (None, false)
  }
}

///|
pub fn get_job_and_step(id : String) -> (@export_job_v4_7.JobRecord?, Bool) {
  match store.val.get(id) {
    Some(job) => {
      let expired = is_expired(job)
      let next_status_value = next_status(job.status)
      let next_progress_value = next_progress(job.progress, next_status_value)
      let next : @export_job_v4_7.JobRecord = {
        id: job.id,
        kind: job.kind,
        status: next_status_value,
        input: job.input,
        progress: next_progress_value,
        ttl_seconds: job.ttl_seconds,
        reasons: job.reasons,
        poll_count: job.poll_count + 1,
      }
      store.val[id] = next
      (Some(job), expired)
    }
    None => (None, false)
  }
}

///|
pub fn cancel_job(id : String, reason : @core.Reason) -> (@export_job_v4_7.JobRecord?, Bool) {
  match store.val.get(id) {
    Some(job) => {
      let expired = is_expired(job)
      let next : @export_job_v4_7.JobRecord = {
        id: job.id,
        kind: job.kind,
        status: @export_job_v4_7.JobStatus::Failed,
        input: job.input,
        progress: job.progress,
        ttl_seconds: job.ttl_seconds,
        reasons: [reason],
        poll_count: job.poll_count,
      }
      store.val[id] = next
      (Some(next), expired)
    }
    None => (None, false)
  }
}
