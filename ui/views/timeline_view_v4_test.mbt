///|
fn read_text_view_v4_timeline(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected_v4_timeline(path : String) -> String raise {
  match read_text_view_v4_timeline(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
test "v4 timeline list html fixture" {
  let expected = load_expected_v4_timeline("examples/v4/html/timeline_list_expected.html")
  let view : V4TimelineListView = {
    cursor: "offset:0",
    next_cursor: Some("offset:2"),
    events: [
      {
        event_id: "order-1:10:1:transition",
        kind: "transition",
        ref_id: "submit",
        status: "executed",
        reasons: [],
      },
      {
        event_id: "order-1:11:1:policy",
        kind: "policy",
        ref_id: "policy:submit",
        status: "deny",
        reasons: ["Policy denied execution"],
      },
    ],
  }
  let mut output = render_timeline_list_html_v4(view)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "v4 timeline list mx html fixture" {
  let expected = load_expected_v4_timeline("examples/v4/html/timeline_list_mx_expected.html")
  let view : V4TimelineListView = {
    cursor: "offset:0",
    next_cursor: Some("offset:2"),
    events: [
      {
        event_id: "order-1:10:1:transition",
        kind: "transition",
        ref_id: "submit",
        status: "executed",
        reasons: [],
      },
      {
        event_id: "order-1:11:1:policy",
        kind: "policy",
        ref_id: "policy:submit",
        status: "deny",
        reasons: ["Policy denied execution"],
      },
    ],
  }
  let mut output = render_timeline_list_html_v4_mx(view)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
