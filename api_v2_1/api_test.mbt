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

///|
fn load_schema() -> String raise {
  match read_text_api("examples/runtime_execute/model.yaml", "schema") {
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
fn create_body(entity_id : String, state : String, note : String) -> String {
  let obj : Map[String, Json] = Map::new()
  obj["entityId"] = Json::string(entity_id)
  obj["state"] = Json::string(state)
  let payload : Map[String, Json] = Map::new()
  payload["note"] = Json::string(note)
  obj["payload"] = Json::object(payload)
  Json::object(obj).stringify(indent=2)
}

///|
fn execute_body(transition : String, approve : Bool, reject : Bool) -> String {
  let obj : Map[String, Json] = Map::new()
  obj["transition"] = Json::string(transition)
  let rules : Map[String, Json] = Map::new()
  rules["canApprove"] = Json::boolean(approve)
  rules["canReject"] = Json::boolean(reject)
  let input_obj : Map[String, Json] = Map::new()
  input_obj["rules"] = Json::object(rules)
  obj["input"] = Json::object(input_obj)
  Json::object(obj).stringify(indent=2)
}

///|
test "api v2.1 create entity" {
  let expected = load_expected("examples/api_v2_1/entities_create/expected.json")
  let schema_text = load_schema()
  let state = ApiState::new()
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v2.1/entities",
    body: Some(create_body("order-1", "Draft", "hello")),
  }
  let resp = handle_request(schema_text, state, req)
  inspect(resp.status, content="200")
  assert_body(resp.body, expected)
}

///|
test "api v2.1 get entity" {
  let expected = load_expected("examples/api_v2_1/entities_get/expected.json")
  let schema_text = load_schema()
  let state = ApiState::new()
  let create_req : ApiRequest = {
    http_method: "POST",
    path: "/v2.1/entities",
    body: Some(create_body("order-1", "Draft", "hello")),
  }
  ignore(handle_request(schema_text, state, create_req))
  let get_req : ApiRequest = {
    http_method: "GET",
    path: "/v2.1/entities/order-1",
    body: None,
  }
  let resp = handle_request(schema_text, state, get_req)
  inspect(resp.status, content="200")
  assert_body(resp.body, expected)
}

///|
test "api v2.1 history" {
  let expected = load_expected("examples/api_v2_1/history_get/expected.json")
  let schema_text = load_schema()
  let state = ApiState::new()
  let create_req : ApiRequest = {
    http_method: "POST",
    path: "/v2.1/entities",
    body: Some(create_body("order-1", "Draft", "hello")),
  }
  ignore(handle_request(schema_text, state, create_req))
  let exec_req : ApiRequest = {
    http_method: "POST",
    path: "/v2.1/entities/order-1/execute",
    body: Some(execute_body("approve", true, false)),
  }
  ignore(handle_request(schema_text, state, exec_req))
  let history_req : ApiRequest = {
    http_method: "GET",
    path: "/v2.1/entities/order-1/history",
    body: None,
  }
  let resp = handle_request(schema_text, state, history_req)
  inspect(resp.status, content="200")
  assert_body(resp.body, expected)
}

///|
test "api v2.1 history html" {
  let expected = load_expected("examples/api_v2_1/history_html/expected.html")
  let schema_text = load_schema()
  let state = ApiState::new()
  let create_req : ApiRequest = {
    http_method: "POST",
    path: "/v2.1/entities",
    body: Some(create_body("order-1", "Draft", "hello")),
  }
  ignore(handle_request(schema_text, state, create_req))
  let exec_req : ApiRequest = {
    http_method: "POST",
    path: "/v2.1/entities/order-1/execute",
    body: Some(execute_body("approve", true, false)),
  }
  ignore(handle_request(schema_text, state, exec_req))
  let history_req : ApiRequest = {
    http_method: "GET",
    path: "/v2.1/entities/order-1/history?format=v2_1_html",
    body: None,
  }
  let resp = handle_request(schema_text, state, history_req)
  inspect(resp.status, content="200")
  assert_body(resp.body, expected)
}

///|
test "api v2.1 execute executed" {
  let expected = load_expected("examples/api_v2_1/execute_executed/expected.json")
  let schema_text = load_schema()
  let state = ApiState::new()
  let create_req : ApiRequest = {
    http_method: "POST",
    path: "/v2.1/entities",
    body: Some(create_body("order-1", "Draft", "hello")),
  }
  ignore(handle_request(schema_text, state, create_req))
  let exec_req : ApiRequest = {
    http_method: "POST",
    path: "/v2.1/entities/order-1/execute",
    body: Some(execute_body("approve", true, false)),
  }
  let resp = handle_request(schema_text, state, exec_req)
  inspect(resp.status, content="200")
  assert_body(resp.body, expected)
}

///|
test "api v2.1 execute blocked" {
  let expected = load_expected("examples/api_v2_1/execute_blocked/expected.json")
  let schema_text = load_schema()
  let state = ApiState::new()
  let create_req : ApiRequest = {
    http_method: "POST",
    path: "/v2.1/entities",
    body: Some(create_body("order-1", "Draft", "hello")),
  }
  ignore(handle_request(schema_text, state, create_req))
  let exec_req : ApiRequest = {
    http_method: "POST",
    path: "/v2.1/entities/order-1/execute",
    body: Some(execute_body("reject", true, false)),
  }
  let resp = handle_request(schema_text, state, exec_req)
  inspect(resp.status, content="200")
  assert_body(resp.body, expected)
}

///|
test "api v2.1 execute not found" {
  let expected = load_expected("examples/api_v2_1/execute_not_found/expected.json")
  let schema_text = load_schema()
  let state = ApiState::new()
  let create_req : ApiRequest = {
    http_method: "POST",
    path: "/v2.1/entities",
    body: Some(create_body("order-1", "Draft", "hello")),
  }
  ignore(handle_request(schema_text, state, create_req))
  let exec_req : ApiRequest = {
    http_method: "POST",
    path: "/v2.1/entities/order-1/execute",
    body: Some(execute_body("missing", true, false)),
  }
  let resp = handle_request(schema_text, state, exec_req)
  inspect(resp.status, content="400")
  assert_body(resp.body, expected)
}

///|
test "api v2.1 execute not available" {
  let expected = load_expected("examples/api_v2_1/execute_not_available/expected.json")
  let schema_text = load_schema()
  let state = ApiState::new()
  let create_req : ApiRequest = {
    http_method: "POST",
    path: "/v2.1/entities",
    body: Some(create_body("order-1", "Approved", "hello")),
  }
  ignore(handle_request(schema_text, state, create_req))
  let exec_req : ApiRequest = {
    http_method: "POST",
    path: "/v2.1/entities/order-1/execute",
    body: Some(execute_body("reject", true, false)),
  }
  let resp = handle_request(schema_text, state, exec_req)
  inspect(resp.status, content="400")
  assert_body(resp.body, expected)
}
