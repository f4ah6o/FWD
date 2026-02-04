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
test "api v3 resource json" {
  let schema_text = match read_text_api("examples/effects_v2_2/model.yaml", "model") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = load_expected("examples/api_v3/resource/expected.json")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v3/resource",
    query: query_map([("state", "Draft")]),
    body: None,
  }
  let res = handle_request(schema_text, req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3 resource missing state" {
  let schema_text = match read_text_api("examples/effects_v2_2/model.yaml", "model") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = load_expected("examples/api_v3/resource/expected_missing_state.json")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v3/resource",
    query: query_map([]),
    body: None,
  }
  let res = handle_request(schema_text, req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3 effects plan" {
  let schema_text = match read_text_api("examples/effects_v2_2/model.yaml", "model") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = load_expected("examples/api_v3/effects/expected.json")
  let body = match read_text_api("examples/api_v3/effects/body.json", "body") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v3/effects",
    query: query_map([]),
    body: Some(body),
  }
  let res = handle_request(schema_text, req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3 effects invalid body" {
  let schema_text = match read_text_api("examples/effects_v2_2/model.yaml", "model") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = load_expected("examples/api_v3/effects/expected_invalid_body.json")
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v3/effects",
    query: query_map([]),
    body: Some("[]"),
  }
  let res = handle_request(schema_text, req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3 execute audit" {
  let schema_text = match read_text_api("examples/effects_v2_2/model.yaml", "model") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = load_expected("examples/api_v3/execute/expected.json")
  let body = match read_text_api("examples/api_v3/execute/body.json", "body") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v3/execute",
    query: query_map([]),
    body: Some(body),
  }
  let res = handle_request(schema_text, req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3 execute missing transition" {
  let schema_text = match read_text_api("examples/effects_v2_2/model.yaml", "model") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = load_expected("examples/api_v3/execute/expected_missing_transition.json")
  let body = match read_text_api("examples/api_v3/execute/body.json", "body") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let parsed : Result[Json, @json.ParseError] = try? @json.parse(body)
  let mut out_body = "{}"
  match parsed {
    Ok(Object(map)) => {
      map.remove("transition")
      out_body = Json::object(map).stringify(indent=2)
    }
    Ok(_) => fail("body must be object")
    Err(_) => fail("parse body failed")
  }
  let req : ApiRequest = {
    http_method: "POST",
    path: "/v3/execute",
    query: query_map([]),
    body: Some(out_body),
  }
  let res = handle_request(schema_text, req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3 timeline" {
  let schema_text = match read_text_api("examples/effects_v2_2/model.yaml", "model") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = load_expected("examples/api_v3/timeline/expected.json")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v3/timeline",
    query: query_map([("entity", "order-1")]),
    body: None,
  }
  let res = handle_request(schema_text, req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3 timeline missing entity" {
  let schema_text = match read_text_api("examples/effects_v2_2/model.yaml", "model") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = load_expected("examples/api_v3/timeline/expected_missing_entity.json")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v3/timeline",
    query: query_map([]),
    body: None,
  }
  let res = handle_request(schema_text, req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
