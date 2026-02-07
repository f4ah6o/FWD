///|
fn query_map(pairs : Array[(String, String)]) -> Map[String, String] {
  let map : Map[String, String] = Map::new()
  for pair in pairs {
    map[pair.0] = pair.1
  }
  map
}

fn parse_json_or_fail(text : String, label : String) -> Json raise {
  try @json.parse(text) catch {
    err => fail("parse failed: " + label + ": " + err.to_string())
  }
}

///|
test "api v5.2 get visible all pass omits retentionDetails" {
  @job_store_v5_2.reset_for_test()
  ignore(handle_request({
    http_method: "POST",
    path: "/v5.2/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"format\":\"jsonl\",\"retentionPolicy\":{\"combine\":\"all\",\"axes\":[{\"type\":\"poll_count_max\",\"value\":3},{\"type\":\"generation_min\",\"value\":1}]}}"),
  }))
  let res = handle_request({
    http_method: "GET",
    path: "/v5.2/export/jobs/job-1",
    query: query_map([]),
    body: None,
  })
  inspect(res.status, content="200")
  let body = parse_json_or_fail(res.body, "visible body")
  let obj = match body {
    Object(v) => v
    _ => fail("expected object")
  }
  inspect(obj.get("retentionDetails").to_string(), content="None")
  inspect(obj.get("status").to_string(), content="Some(String(\"queued\"))")
}

///|
test "api v5.2 get hidden multi fail returns failedAxes in policy order" {
  @job_store_v5_2.reset_for_test()
  ignore(handle_request({
    http_method: "POST",
    path: "/v5.2/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"format\":\"jsonl\",\"retentionPolicy\":{\"combine\":\"all\",\"axes\":[{\"type\":\"poll_count_max\",\"value\":0},{\"type\":\"generation_min\",\"value\":2}]}}"),
  }))
  ignore(handle_request({
    http_method: "POST",
    path: "/v5.2/export/jobs/job-1/step",
    query: query_map([]),
    body: None,
  }))
  let res = handle_request({
    http_method: "GET",
    path: "/v5.2/export/jobs/job-1",
    query: query_map([]),
    body: None,
  })
  inspect(res.status, content="404")
  let body = parse_json_or_fail(res.body, "hidden body")
  let obj = match body {
    Object(v) => v
    _ => fail("expected object")
  }
  let details = match obj.get("retentionDetails") {
    Some(Object(v)) => v
    _ => fail("missing retentionDetails")
  }
  let failed_axes = match details.get("failedAxes") {
    Some(Array(v)) => v
    _ => fail("missing failedAxes")
  }
  inspect(failed_axes.length(), content="2")
  let first = match failed_axes[0] {
    Object(v) => v
    _ => fail("first axis not object")
  }
  let second = match failed_axes[1] {
    Object(v) => v
    _ => fail("second axis not object")
  }
  inspect(first.get("axis").to_string(), content="Some(String(\"poll_count\"))")
  inspect(second.get("axis").to_string(), content="Some(String(\"generation\"))")
}

///|
test "api v5.2 result hidden includes endpoint marker" {
  @job_store_v5_2.reset_for_test()
  ignore(handle_request({
    http_method: "POST",
    path: "/v5.2/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"format\":\"jsonl\",\"retentionPolicy\":{\"combine\":\"all\",\"axes\":[{\"type\":\"poll_count_max\",\"value\":0}]}}"),
  }))
  ignore(handle_request({
    http_method: "POST",
    path: "/v5.2/export/jobs/job-1/step",
    query: query_map([]),
    body: None,
  }))
  let res = handle_request({
    http_method: "GET",
    path: "/v5.2/export/jobs/job-1/result",
    query: query_map([]),
    body: None,
  })
  inspect(res.status, content="404")
  let body = parse_json_or_fail(res.body, "result hidden body")
  let obj = match body {
    Object(v) => v
    _ => fail("expected object")
  }
  let details = match obj.get("retentionDetails") {
    Some(Object(v)) => v
    _ => fail("missing retentionDetails")
  }
  inspect(details.get("endpoint").to_string(), content="Some(String(\"result\"))")
}

///|
test "api v5.2 batch get hidden by generation" {
  @export_job_batch_v5_2.reset_for_test()
  ignore(handle_request({
    http_method: "POST",
    path: "/v5.2/export/batch/jobs",
    query: query_map([]),
    body: Some("{\"format\":\"jsonl\",\"retentionPolicy\":{\"combine\":\"all\",\"axes\":[{\"type\":\"generation_min\",\"value\":2}]},\"jobs\":[{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12}] }"),
  }))
  let res = handle_request({
    http_method: "GET",
    path: "/v5.2/export/batch/jobs/job-1",
    query: query_map([]),
    body: None,
  })
  inspect(res.status, content="404")
}

///|
test "api v5.2 get legacy expired compatibility block" {
  @job_store_v5_2.reset_for_test()
  @job_store_v5_2.seed_for_test(1, [{
    id: { value: "job-1" },
    status: @export_job_v5_2.JobStatus::Expired,
    progress: { processed: 1, total: 3 },
    retention_policy: {
      combine: @export_job_v5_2.RetentionCombineV52::All,
      axes: [@export_job_v5_2.RetentionAxisConditionV52::PollCountMax(3)],
    },
    generation: 1,
    format: @export_job_v5_2.ResultFormat::Jsonl,
    reasons: [],
    poll_count: 5,
  }])
  let res = handle_request({
    http_method: "GET",
    path: "/v5.2/export/jobs/job-1",
    query: query_map([]),
    body: None,
  })
  inspect(res.status, content="404")
  let body = parse_json_or_fail(res.body, "legacy expired body")
  let obj = match body {
    Object(v) => v
    _ => fail("expected object")
  }
  let compat = match obj.get("compatibility") {
    Some(Object(v)) => v
    _ => fail("missing compatibility")
  }
  inspect(compat.get("sourceStatus").to_string(), content="Some(String(\"expired\"))")
  inspect(compat.get("mode").to_string(), content="Some(String(\"legacy-read\"))")
}
