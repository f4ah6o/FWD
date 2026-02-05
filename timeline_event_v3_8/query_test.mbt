///|
fn read_text_query(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected(path : String) -> String raise {
  match read_text_query(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
test "timeline event cursor json fixture" {
  let expected = load_expected("examples/v3_8/timeline_event_list/expected_cursor.json")
  let cursor : TimelineEventCursor = {
    entity_id: "order-1",
    offset: 2,
    limit: 2,
    kind: Some("policy"),
    from_logical_time: Some(10),
    to_logical_time: Some(12),
  }
  let mut output = cursor_json(cursor).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
