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
test "api v3.9 timeline event page html" {
  let expected = load_expected("examples/api_v3_9/timeline_event_page/expected.html")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v3.9/timeline/event/order-1:11:1:policy",
    query: query_map([]),
    body: None,
  }
  let res = handle_request(req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3.9 timeline event page json" {
  let expected = load_expected("examples/api_v3_9/timeline_event_page/expected.json")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v3.9/timeline/event/order-1:11:1:policy",
    query: query_map([("format", "json")]),
    body: None,
  }
  let res = handle_request(req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3.9 timeline event not found" {
  let expected = load_expected("examples/api_v3_9/timeline_event_page/expected_not_found.json")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v3.9/timeline/event/order-1:99:1:policy",
    query: query_map([]),
    body: None,
  }
  let res = handle_request(req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "api v3.9 timeline event invalid id" {
  let expected = load_expected("examples/api_v3_9/timeline_event_page/expected_invalid_id.json")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v3.9/timeline/event/invalid",
    query: query_map([]),
    body: None,
  }
  let res = handle_request(req)
  let mut output = res.body
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
