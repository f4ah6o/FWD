///|
fn read_text_api_v2(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected(path : String) -> String raise {
  match read_text_api_v2(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
fn load_model() -> String raise {
  match read_text_api_v2("examples/effects_v2_2/model.yaml", "model") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
fn plan_body(schema_text : String, input_json : String) -> String {
  let obj : Map[String, Json] = Map::new()
  obj["schema"] = Json::string(schema_text)
  obj["entityId"] = Json::string("order-1")
  obj["state"] = Json::string("Draft")
  obj["transition"] = Json::string("submit")
  let parsed : Result[Json, @json.ParseError] = try? @json.parse(input_json)
  match parsed {
    Ok(value) => obj["input"] = value
    Err(_) => ()
  }
  Json::object(obj).stringify(indent=2)
}

///|
fn execute_body(plan_text : String) -> String {
  let obj : Map[String, Json] = Map::new()
  let parsed : Result[Json, @json.ParseError] = try? @json.parse(plan_text)
  match parsed {
    Ok(value) => obj["plan"] = value
    Err(_) => ()
  }
  Json::object(obj).stringify(indent=2)
}

///|
test "api v2.2 effects plan" {
  let expected = load_expected("examples/api_v2_2/effects_plan/expected.json")
  let schema_text = load_model()
  let body = plan_body(schema_text, "{\"rules\": {\"canSubmit\": true}}")
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v2.2/effects/plan",
    body: Some(body),
  }
  let resp = handle_request(req)
  inspect(resp.status, content="200")
  let mut output = resp.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v2.2 effects execute" {
  let expected = load_expected("examples/api_v2_2/effects_execute/expected.json")
  let plan_text = load_expected("examples/effects_v2_2/execute/plan_planned.json")
  let body = execute_body(plan_text)
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v2.2/effects/execute",
    body: Some(body),
  }
  let resp = handle_request(req)
  inspect(resp.status, content="200")
  let mut output = resp.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
