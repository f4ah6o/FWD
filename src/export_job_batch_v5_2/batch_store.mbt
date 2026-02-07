///|
/// Deterministic in-memory batch store (v5.2 draft).

let batch_store : Ref[Map[String, BatchJobRecord]] = @ref.new(Map::new())
let child_store : Ref[Map[String, @export_job_v5_2.JobRecord]] = @ref.new(Map::new())

fn cancel_reason(job_id : String) -> @export_job_v5.ReasonV1 {
  {
    code: @export_job_v5.ReasonCode::JobCanceled,
    level: @export_job_v5.ReasonLevel::Error,
    target: "runtime",
    message: "job canceled: " + job_id,
    hint: Some("Job was canceled"),
  }
}

fn child_record(
  id_value : String,
  format : @export_job_v5_2.ResultFormat,
  retention_policy : @export_job_v5_2.RetentionPolicyV52,
) -> @export_job_v5_2.JobRecord {
  {
    id: { value: id_value },
    status: @export_job_v5_2.JobStatus::Queued,
    progress: { processed: 0, total: 1 },
    retention_policy,
    generation: 1,
    format,
    reasons: [],
    poll_count: 0,
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

fn update_child(id : String, status : @export_job_v5_2.JobStatus, reasons : Array[@export_job_v5.ReasonV1]) -> Unit {
  match child_store.val.get(id) {
    Some(child) => {
      child_store.val[id] = {
        id: child.id,
        status,
        progress: match status {
          @export_job_v5_2.JobStatus::Done => { processed: 1, total: 1 }
          _ => child.progress
        },
        retention_policy: child.retention_policy,
        generation: child.generation,
        format: child.format,
        reasons,
        poll_count: child.poll_count,
      }
    }
    None => ()
  }
}

///|
pub fn reset_for_test() -> Unit {
  @export_job_v5_2.reset_id_for_test()
  batch_store.val = Map::new()
  child_store.val = Map::new()
}

///|
pub fn create_batch(
  format : @export_job_v5_2.ResultFormat,
  retention_policy : @export_job_v5_2.RetentionPolicyV52,
  child_specs : Array[BatchChildSpec],
) -> BatchJobRecord {
  let id = @export_job_v5_2.next_job_id().value
  let child_ids : Array[String] = []
  for _ in child_specs {
    let child_id = @export_job_v5_2.next_job_id().value
    child_ids.push(child_id)
    child_store.val[child_id] = child_record(child_id, format, retention_policy)
  }
  let batch : BatchJobRecord = {
    id,
    child_ids,
    child_specs,
    status: @export_job_v5_2.JobStatus::Queued,
    progress: { processed: 0, total: child_specs.length() },
    retention_policy,
    generation: 1,
    format,
    reasons: [],
    poll_count: 0,
    next_child_index: 0,
  }
  batch_store.val[id] = batch
  batch
}

///|
pub fn get_batch(id : String) -> BatchJobRecord? {
  batch_store.val.get(id)
}

///|
pub fn step_batch(id : String) -> BatchJobRecord? {
  match batch_store.val.get(id) {
    Some(batch) => {
      let child_count = batch.child_ids.length()
      let next_index = if is_terminal(batch.status) || child_count == 0 {
        batch.next_child_index
      } else if batch.next_child_index < child_count {
        batch.next_child_index + 1
      } else {
        batch.next_child_index
      }
      if batch.next_child_index < child_count && !is_terminal(batch.status) {
        let child_id = batch.child_ids[batch.next_child_index]
        update_child(child_id, @export_job_v5_2.JobStatus::Done, [])
      }
      let next_status = if is_terminal(batch.status) {
        batch.status
      } else if next_index >= child_count {
        @export_job_v5_2.JobStatus::Done
      } else if next_index > 0 {
        @export_job_v5_2.JobStatus::Running
      } else {
        batch.status
      }
      let next : BatchJobRecord = {
        id: batch.id,
        child_ids: batch.child_ids,
        child_specs: batch.child_specs,
        status: next_status,
        progress: { processed: next_index, total: batch.progress.total },
        retention_policy: batch.retention_policy,
        generation: batch.generation,
        format: batch.format,
        reasons: batch.reasons,
        poll_count: batch.poll_count + 1,
        next_child_index: next_index,
      }
      batch_store.val[id] = next
      Some(next)
    }
    None => None
  }
}

///|
pub fn cancel_batch(id : String) -> BatchJobRecord? {
  match batch_store.val.get(id) {
    Some(batch) => {
      for child_id in batch.child_ids {
        update_child(child_id, @export_job_v5_2.JobStatus::Canceled, [cancel_reason(child_id)])
      }
      let next_status = if is_terminal(batch.status) {
        batch.status
      } else {
        @export_job_v5_2.JobStatus::Canceled
      }
      let next_reasons = match next_status {
        @export_job_v5_2.JobStatus::Canceled => [cancel_reason(batch.id)]
        _ => batch.reasons
      }
      let next : BatchJobRecord = {
        id: batch.id,
        child_ids: batch.child_ids,
        child_specs: batch.child_specs,
        status: next_status,
        progress: batch.progress,
        retention_policy: batch.retention_policy,
        generation: batch.generation,
        format: batch.format,
        reasons: next_reasons,
        poll_count: batch.poll_count,
        next_child_index: batch.next_child_index,
      }
      batch_store.val[id] = next
      Some(next)
    }
    None => None
  }
}
