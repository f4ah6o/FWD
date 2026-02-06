///|
fn read_text_api(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected(path : String) -> String raise {
  match read_text_api(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

fn query_map(pairs : Array[(String, String)]) -> Map[String, String] {
  let map : Map[String, String] = Map::new()
  for pair in pairs {
    map[pair.0] = pair.1
  }
  map
}

///|
test "api v4.7 metrics job create" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/metrics_jobs/create_expected.json")
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v4.7/metrics/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"format\":\"jsonl\"}"),
  }
  let res = handle_request(req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v4.7 metrics job status queued" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/metrics_jobs/get_queued_expected.json")
  ignore(handle_request({
    http_method: "POST",
    path: "/v4.7/metrics/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"format\":\"jsonl\"}"),
  }))
  let res = handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1",
    query: query_map([]),
    body: None,
  })
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v4.7 metrics job status done" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/metrics_jobs/get_done_expected.json")
  ignore(handle_request({
    http_method: "POST",
    path: "/v4.7/metrics/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"format\":\"jsonl\"}"),
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  let res = handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1",
    query: query_map([]),
    body: None,
  })
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v4.7 metrics job cancel" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/metrics_jobs/cancel_expected.json")
  ignore(handle_request({
    http_method: "POST",
    path: "/v4.7/metrics/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"format\":\"jsonl\"}"),
  }))
  let res = handle_request({
    http_method: "POST",
    path: "/v4.7/metrics/export/jobs/job-1/cancel",
    query: query_map([]),
    body: None,
  })
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v4.7 metrics job result jsonl" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/metrics_jobs/result_expected.jsonl")
  ignore(handle_request({
    http_method: "POST",
    path: "/v4.7/metrics/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"format\":\"jsonl\"}"),
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  let res = handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1/result.jsonl",
    query: query_map([]),
    body: None,
  })
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v4.7 metrics job result not ready" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/common/expected_job_not_ready.json")
  ignore(handle_request({
    http_method: "POST",
    path: "/v4.7/metrics/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"format\":\"jsonl\"}"),
  }))
  let res = handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1/result.jsonl",
    query: query_map([]),
    body: None,
  })
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v4.7 metrics job result canceled" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/common/expected_job_canceled.json")
  ignore(handle_request({
    http_method: "POST",
    path: "/v4.7/metrics/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"format\":\"jsonl\"}"),
  }))
  ignore(handle_request({
    http_method: "POST",
    path: "/v4.7/metrics/export/jobs/job-1/cancel",
    query: query_map([]),
    body: None,
  }))
  let res = handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1/result.jsonl",
    query: query_map([]),
    body: None,
  })
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v4.7 metrics job result expired" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/common/expected_job_expired.json")
  ignore(handle_request({
    http_method: "POST",
    path: "/v4.7/metrics/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"format\":\"jsonl\"}"),
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  let res = handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1/result.jsonl",
    query: query_map([]),
    body: None,
  })
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v4.7 metrics job result csv" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/metrics_jobs/result_expected.csv")
  ignore(handle_request({
    http_method: "POST",
    path: "/v4.7/metrics/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"format\":\"csv\"}"),
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  let res = handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-1/result.csv",
    query: query_map([]),
    body: None,
  })
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v4.7 timeline job create" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/timeline_jobs/create_expected.json")
  let res = handle_request({
    http_method: "POST",
    path: "/v4.7/timeline/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"limit\":2,\"format\":\"jsonl\"}"),
  })
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v4.7 timeline job status done" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/timeline_jobs/get_done_expected.json")
  ignore(handle_request({
    http_method: "POST",
    path: "/v4.7/timeline/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"limit\":2,\"format\":\"jsonl\"}"),
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/timeline/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/timeline/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  let res = handle_request({
    http_method: "GET",
    path: "/v4.7/timeline/export/jobs/job-1",
    query: query_map([]),
    body: None,
  })
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v4.7 timeline job result page1" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/timeline_jobs/result_page1_expected.jsonl")
  ignore(handle_request({
    http_method: "POST",
    path: "/v4.7/timeline/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"limit\":2,\"format\":\"jsonl\"}"),
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/timeline/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/timeline/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/timeline/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  let res = handle_request({
    http_method: "GET",
    path: "/v4.7/timeline/export/jobs/job-1/result.jsonl",
    query: query_map([]),
    body: None,
  })
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
  inspect(res.headers.get("x-next-cursor"), content="Some(\"offset:2\")")
}

///|
test "api v4.7 timeline job result page2" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/timeline_jobs/result_page2_expected.jsonl")
  ignore(handle_request({
    http_method: "POST",
    path: "/v4.7/timeline/export/jobs",
    query: query_map([]),
    body: Some("{\"entityId\":\"order-1\",\"fromLogicalTime\":10,\"toLogicalTime\":12,\"limit\":2,\"cursor\":\"offset:2\",\"format\":\"jsonl\"}"),
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/timeline/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/timeline/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  ignore(handle_request({
    http_method: "GET",
    path: "/v4.7/timeline/export/jobs/job-1",
    query: query_map([]),
    body: None,
  }))
  let res = handle_request({
    http_method: "GET",
    path: "/v4.7/timeline/export/jobs/job-1/result.jsonl",
    query: query_map([]),
    body: None,
  })
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
  inspect(res.headers.get("x-next-cursor"), content="None")
}

///|
test "api v4.7 invalid body" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/common/expected_invalid_body.json")
  let res = handle_request({
    http_method: "POST",
    path: "/v4.7/metrics/export/jobs",
    query: query_map([]),
    body: Some("[]"),
  })
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v4.7 missing entity" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/common/expected_missing_entity.json")
  let res = handle_request({
    http_method: "POST",
    path: "/v4.7/metrics/export/jobs",
    query: query_map([]),
    body: Some("{\"format\":\"jsonl\"}"),
  })
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v4.7 job not found" {
  @job_store_v4_7.reset_for_test()
  let expected = load_expected("examples/api_v4_7/common/expected_job_not_found.json")
  let res = handle_request({
    http_method: "GET",
    path: "/v4.7/metrics/export/jobs/job-999",
    query: query_map([]),
    body: None,
  })
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
