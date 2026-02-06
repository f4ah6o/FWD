///|
/// Metrics job execution helpers (v4.6).

///|
pub fn export_jsonl(input : @export_job_v4_6.MetricsJobInput) -> String {
  let snapshot = @metrics_snapshot_v4_5.build_snapshot(
    input.entity_id,
    input.from_logical_time,
    input.to_logical_time,
  )
  @metrics_export_v4_5.export_jsonl(snapshot)
}

///|
pub fn export_csv(input : @export_job_v4_6.MetricsJobInput) -> String {
  let snapshot = @metrics_snapshot_v4_5.build_snapshot(
    input.entity_id,
    input.from_logical_time,
    input.to_logical_time,
  )
  @metrics_export_v4_5.export_csv(snapshot)
}
