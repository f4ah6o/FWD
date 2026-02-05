///|
fn read_text_view_v4_detail(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected_v4_detail(path : String) -> String raise {
  match read_text_view_v4_detail(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
test "v4 timeline detail html fixture" {
  let expected = load_expected_v4_detail("examples/v4/html/timeline_detail_expected.html")
  let view : V4TimelineDetailView = {
    event_id: "order-1:11:1:policy",
    kind: "policy",
    ref_id: "policy:submit",
    status: "deny",
    reasons: ["Policy denied execution"],
    prev_event_id: Some("order-1:10:1:transition"),
    next_event_id: Some("order-1:12:1:effect"),
  }
  let mut output = render_timeline_detail_html_v4(view)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "v4 timeline detail mx html fixture" {
  let expected = load_expected_v4_detail("examples/v4/html/timeline_detail_mx_expected.html")
  let view : V4TimelineDetailView = {
    event_id: "order-1:11:1:policy",
    kind: "policy",
    ref_id: "policy:submit",
    status: "deny",
    reasons: ["Policy denied execution"],
    prev_event_id: Some("order-1:10:1:transition"),
    next_event_id: Some("order-1:12:1:effect"),
  }
  let mut output = render_timeline_detail_html_v4_mx(view)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
