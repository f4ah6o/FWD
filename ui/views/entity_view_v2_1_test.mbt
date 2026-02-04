///|
fn read_text_entity_view(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_snapshot() -> @store_v2_1.Snapshot {
  let payload : Map[String, Json] = Map::new()
  payload["note"] = Json::string("hello")
  @store_v2_1.Snapshot::new("order-1", "Draft", Some(Json::object(payload)), 1)
}

///|
test "entity html fixture" {
  let expected = match read_text_entity_view(
    "examples/api_v2_1/entity_html/expected.html",
    "expected entity html",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let snapshot = load_snapshot()
  let mut output = render_entity_html(snapshot)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
