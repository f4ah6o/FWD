///|
fn read_text_api(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_schema(path : String) -> String raise {
  match read_text_api(path, "schema") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
fn load_expected(path : String) -> String raise {
  match read_text_api(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
fn assert_body(output : String, expected : String) -> Unit raise {
  let mut body = output
  if expected.has_suffix("\n") {
    body = body + "\n"
  }
  inspect(body, content=expected)
}

///|
fn make_query(entries : Array[(String, String)]) -> Map[String, String] {
  let query : Map[String, String] = Map::new()
  for entry in entries {
    query[entry.0] = entry.1
  }
  query
}

///|
test "api v2 resource json" {
  let schema_text = load_schema("examples/hypermedia_show/model.yaml")
  let expected = load_expected("examples/api_v2/resource/expected.json")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v2/resource",
    query: make_query([("state", "Draft")]),
    body: None,
  }
  let resp = handle_request(schema_text, req)
  inspect(resp.status, content="200")
  assert_body(resp.body, expected)
}

///|
test "api v2 resource html" {
  let schema_text = load_schema("examples/hypermedia_show/model.yaml")
  let expected = load_expected("examples/api_v2/resource/expected.html")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v2/resource",
    query: make_query([("state", "Draft"), ("format", "html")]),
    body: None,
  }
  let resp = handle_request(schema_text, req)
  inspect(resp.status, content="200")
  assert_body(resp.body, expected)
}

///|
test "api v2 resource mx" {
  let schema_text = load_schema("examples/hypermedia_show/model.yaml")
  let expected = load_expected("examples/api_v2/resource/expected_mx.html")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v2/resource",
    query: make_query([("state", "Draft"), ("format", "mx")]),
    body: None,
  }
  let resp = handle_request(schema_text, req)
  inspect(resp.status, content="200")
  assert_body(resp.body, expected)
}

///|
fn execute_request_body(state : String, transition : String) -> String {
  let obj : Map[String, Json] = Map::new()
  obj["state"] = Json::string(state)
  obj["transition"] = Json::string(transition)
  let rules : Map[String, Json] = Map::new()
  rules["canApprove"] = Json::boolean(true)
  rules["canReject"] = Json::boolean(false)
  let input_obj : Map[String, Json] = Map::new()
  input_obj["rules"] = Json::object(rules)
  obj["input"] = Json::object(input_obj)
  Json::object(obj).stringify(indent=2)
}

///|
fn validate_request_body(state : String, transition : String, payload : Json) -> String {
  let obj : Map[String, Json] = Map::new()
  obj["state"] = Json::string(state)
  obj["transition"] = Json::string(transition)
  obj["payload"] = payload
  Json::object(obj).stringify(indent=2)
}

///|
test "api v2 resource form html" {
  let schema_text = load_schema("examples/api_v2/input_form/model.yaml")
  let expected = load_expected("examples/api_v2/input_form/expected.html")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v2/resource",
    query: make_query([("state", "Draft"), ("format", "form")]),
    body: None,
  }
  let resp = handle_request(schema_text, req)
  inspect(resp.status, content="200")
  assert_body(resp.body, expected)
}

///|
test "api v2 resource validate invalid payload" {
  let schema_text = load_schema("examples/api_v2/input_form/model.yaml")
  let expected = load_expected("examples/api_v2/input_invalid/expected.json")
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v2/resource/validate",
    query: Map::new(),
    body: Some(validate_request_body("Draft", "submit", Json::string("bad"))),
  }
  let resp = handle_request(schema_text, req)
  inspect(resp.status, content="400")
  assert_body(resp.body, expected)
}

///|
test "api v2 resource validate ok" {
  let schema_text = load_schema("examples/api_v2/input_form/model.yaml")
  let expected = load_expected("examples/api_v2/input_form/expected_validate_ok.html")
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v2/resource/validate",
    query: Map::new(),
    body: Some(validate_request_body("Draft", "submit", Json::object(Map::new()))),
  }
  let resp = handle_request(schema_text, req)
  inspect(resp.status, content="200")
  assert_body(resp.body, expected)
}

///|
test "api v2 execute executed" {
  let schema_text = load_schema("examples/runtime_execute/model.yaml")
  let expected = load_expected("examples/api_v2/execute/expected_executed.json")
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v2/transition/execute",
    query: Map::new(),
    body: Some(execute_request_body("Draft", "approve")),
  }
  let resp = handle_request(schema_text, req)
  inspect(resp.status, content="200")
  assert_body(resp.body, expected)
}

///|
test "api v2 execute blocked" {
  let schema_text = load_schema("examples/runtime_execute/model.yaml")
  let expected = load_expected("examples/api_v2/execute/expected_blocked.json")
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v2/transition/execute",
    query: Map::new(),
    body: Some(execute_request_body("Draft", "reject")),
  }
  let resp = handle_request(schema_text, req)
  inspect(resp.status, content="200")
  assert_body(resp.body, expected)
}

///|
test "api v2 execute not found" {
  let schema_text = load_schema("examples/runtime_execute/model.yaml")
  let expected = load_expected("examples/api_v2/execute/expected_not_found.json")
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v2/transition/execute",
    query: Map::new(),
    body: Some(execute_request_body("Draft", "missing")),
  }
  let resp = handle_request(schema_text, req)
  inspect(resp.status, content="400")
  assert_body(resp.body, expected)
}

///|
test "api v2 execute not available" {
  let schema_text = load_schema("examples/runtime_execute/model.yaml")
  let expected = load_expected("examples/api_v2/execute/expected_not_available.json")
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v2/transition/execute",
    query: Map::new(),
    body: Some(execute_request_body("Approved", "reject")),
  }
  let resp = handle_request(schema_text, req)
  inspect(resp.status, content="400")
  assert_body(resp.body, expected)
}
