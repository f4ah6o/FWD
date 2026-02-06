///|
/// Deterministic in-memory job store (v4.6).

let counter : Ref[Int] = @ref.new(0)
let store : Ref[Map[String, @export_job_v4_6.JobRecord]] = @ref.new(Map::new())

fn next_status(status : @export_job_v4_6.JobStatus) -> @export_job_v4_6.JobStatus {
  match status {
    @export_job_v4_6.JobStatus::Queued => @export_job_v4_6.JobStatus::Running
    @export_job_v4_6.JobStatus::Running => @export_job_v4_6.JobStatus::Done
    @export_job_v4_6.JobStatus::Done => @export_job_v4_6.JobStatus::Done
    @export_job_v4_6.JobStatus::Failed => @export_job_v4_6.JobStatus::Failed
  }
}

///|
pub fn reset_for_test() -> Unit {
  counter.val = 0
  store.val = Map::new()
}

///|
pub fn create_job(
  kind : @export_job_v4_6.JobKind,
  input : @export_job_v4_6.JobInput,
) -> @export_job_v4_6.JobRecord {
  counter.val = counter.val + 1
  let id = "job-" + counter.val.to_string()
  let job : @export_job_v4_6.JobRecord = {
    id,
    kind,
    status: @export_job_v4_6.JobStatus::Queued,
    input,
    reasons: [],
  }
  store.val[id] = job
  job
}

///|
pub fn get_job(id : String) -> @export_job_v4_6.JobRecord? {
  store.val.get(id)
}

///|
pub fn get_job_and_step(id : String) -> @export_job_v4_6.JobRecord? {
  match store.val.get(id) {
    Some(job) => {
      let next : @export_job_v4_6.JobRecord = {
        id: job.id,
        kind: job.kind,
        status: next_status(job.status),
        input: job.input,
        reasons: job.reasons,
      }
      store.val[id] = next
      Some(job)
    }
    None => None
  }
}
