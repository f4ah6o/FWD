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
test "api v4.4 metrics html" {
  let expected = load_expected("examples/api_v4_4/metrics/expected.html")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v4.4/metrics",
    query: query_map([("format", "html")]),
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
test "api v4.4 metrics mx" {
  let expected = load_expected("examples/api_v4_4/metrics/expected_mx.html")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v4.4/metrics",
    query: query_map([("format", "mx")]),
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
test "api v4.4 metrics detail html" {
  let expected = load_expected("examples/api_v4_4/metrics_detail/expected.html")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v4.4/metrics/kind/transition",
    query: query_map([("format", "html")]),
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
test "api v4.4 metrics invalid kind" {
  let expected = load_expected("examples/api_v4_4/metrics_detail/expected_invalid_kind.json")
  let req : ApiRequest = {
    http_method: "GET",
    path: "/v4.4/metrics/kind/bad",
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
