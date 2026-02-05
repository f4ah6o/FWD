///|
fn read_text_view_v3_4_mx(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected_v3_4_mx(path : String) -> String raise {
  match read_text_view_v3_4_mx(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
test "timeline v3.4 mx view fixture" {
  let expected = load_expected_v3_4_mx("examples/v3_4/timeline_mx/expected.html")
  let events : Array[@timeline_v3.TimelineEvent] = [
    {
      entity_id: "order-1",
      logical_time: 11,
      sequence: 1,
      kind: @timeline_v3.TimelineKind::Policy,
      ref_id: "policy:submit",
      status: "deny",
      reasons: [],
    },
  ]
  let mut output = render_timeline_html_v3_4_mx("order-1", events)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
