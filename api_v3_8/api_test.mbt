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
test "api v3.8 timeline event list page1" {
  let expected = load_expected("examples/api_v3_8/timeline_event_list/expected_page1.html")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v3.8/timeline/events",
    query: query_map([("entityId", "order-1"), ("limit", "2")]),
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
test "api v3.8 timeline event list page2" {
  let expected = load_expected("examples/api_v3_8/timeline_event_list/expected_page2.html")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v3.8/timeline/events",
    query: query_map([("entityId", "order-1"), ("limit", "2"), ("cursor", "offset:2")]),
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
test "api v3.8 timeline event list invalid query" {
  let expected = load_expected("examples/api_v3_8/timeline_event_list/expected_invalid_query.json")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v3.8/timeline/events",
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
