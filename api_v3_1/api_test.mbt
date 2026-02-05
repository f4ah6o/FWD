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
test "api v3.1 execute executed" {
  let expected = load_expected("examples/v3_1/executor/expected_executed.json")
  let body = match read_text_api("examples/v3_1/executor/body_executed.json", "body") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v3.1/effects/execute",
    query: query_map([]),
    body: Some(body),
  }
  let res = handle_request(req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3.1 execute retry then success" {
  let expected = load_expected("examples/v3_1/executor/expected_retry_then_success.json")
  let body = match read_text_api("examples/v3_1/executor/body_retry_then_success.json", "body") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v3.1/effects/execute",
    query: query_map([]),
    body: Some(body),
  }
  let res = handle_request(req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3.1 execute idempotent duplicate" {
  let expected = load_expected("examples/v3_1/executor/expected_idempotent_duplicate.json")
  let body = match read_text_api("examples/v3_1/executor/body_idempotent_duplicate.json", "body") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v3.1/effects/execute",
    query: query_map([]),
    body: Some(body),
  }
  let res = handle_request(req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3.1 execute invalid body" {
  let expected = load_expected("examples/api_v3_1/execute/expected_invalid_body.json")
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v3.1/effects/execute",
    query: query_map([]),
    body: Some("[]"),
  }
  let res = handle_request(req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3.1 execute missing plan" {
  let expected = load_expected("examples/api_v3_1/execute/expected_missing_plan.json")
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v3.1/effects/execute",
    query: query_map([]),
    body: Some("{}"),
  }
  let res = handle_request(req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3.1 execute missing allowlist" {
  let expected = load_expected("examples/api_v3_1/execute/expected_missing_allowlist.json")
  let body = match read_text_api("examples/v3_1/executor/body_executed.json", "body") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let parsed : Result[Json, @json.ParseError] = try? @json.parse(body)
  let mut out_body = "{}"
  match parsed {
    Ok(Object(map)) => {
      map.remove("allowlist")
      out_body = Json::object(map).stringify(indent=2)
    }
    Ok(_) => fail("body must be object")
    Err(_) => fail("parse body failed")
  }
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v3.1/effects/execute",
    query: query_map([]),
    body: Some(out_body),
  }
  let res = handle_request(req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3.1 execute missing idempotency" {
  let expected = load_expected("examples/api_v3_1/execute/expected_missing_idempotency.json")
  let body = match read_text_api("examples/v3_1/executor/body_executed.json", "body") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let parsed : Result[Json, @json.ParseError] = try? @json.parse(body)
  let mut out_body = "{}"
  match parsed {
    Ok(Object(map)) => {
      map.remove("idempotency")
      out_body = Json::object(map).stringify(indent=2)
    }
    Ok(_) => fail("body must be object")
    Err(_) => fail("parse body failed")
  }
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v3.1/effects/execute",
    query: query_map([]),
    body: Some(out_body),
  }
  let res = handle_request(req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
