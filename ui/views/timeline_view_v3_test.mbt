///|
fn read_text_timeline_view(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected_timeline(path : String) -> String raise {
  match read_text_timeline_view(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

fn timeline_reason(code : String, message : String, target : String) -> @core.Reason {
  @core.Reason::with_context(
    code,
    message,
    [("target", target)],
  )
}

///|
test "timeline v3 html fixture" {
  let expected = load_expected_timeline("examples/v3/timeline/expected.html")
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
        timeline_reason("POLICY_DENY", "Policy denied execution", "transition"),
      ],
    },
  ]
  let mut output = render_timeline_html_v3(events)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
