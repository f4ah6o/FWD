///|
fn read_text_view_v3_8(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected_v3_8(path : String) -> String raise {
  match read_text_view_v3_8(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
test "timeline v3.8 event list html fixture" {
  let expected = load_expected_v3_8("examples/api_v3_8/timeline_event_list/expected_page1.html")
  let events : Array[@timeline_v3.TimelineEvent] = [
    {
      entity_id: "order-1",
      logical_time: 10,
      sequence: 1,
      kind: @timeline_v3.TimelineKind::Transition,
      ref_id: "submit",
      status: "executed",
      reasons: [],
    },
    {
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
    },
  ]
  let mut output = render_timeline_event_list_v3_8(
    "order-1",
    events,
    None,
    2,
    Some("offset:2"),
  )
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
