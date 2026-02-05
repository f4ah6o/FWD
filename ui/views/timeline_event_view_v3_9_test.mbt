///|
fn read_text_view_v3_9(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected_v3_9(path : String) -> String raise {
  match read_text_view_v3_9(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
test "timeline v3.9 event page html fixture" {
  let expected = load_expected_v3_9("examples/api_v3_9/timeline_event_page/expected.html")
  let event : @timeline_v3.TimelineEvent = {
    entity_id: "order-1",
    logical_time: 11,
    sequence: 1,
    kind: @timeline_v3.TimelineKind::Policy,
    ref_id: "policy:submit",
    status: "deny",
    reasons: [
      @core.Reason::with_context(
        "POLICY_DENY",
        "Policy denied execution",
        [("target", "transition")],
      ),
    ],
  }
  let page : @timeline_event_v3_9.TimelineEventPage = {
    detail: @timeline_event_v3_4.detail_from_event(event),
    prev_event_id: Some("order-1:10:1:transition"),
    next_event_id: Some("order-1:12:1:effect"),
  }
  let mut output = render_timeline_event_page_v3_9(page)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
