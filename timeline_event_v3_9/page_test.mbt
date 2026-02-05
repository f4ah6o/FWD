///|
fn read_text_page(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected(path : String) -> String raise {
  match read_text_page(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

fn reason(code : String, message : String, target : String) -> @core.Reason {
  @core.Reason::with_context(
    code,
    message,
    [("target", target)],
  )
}

///|
test "timeline event page json fixture" {
  let expected = load_expected("examples/v3_9/timeline_event_page/expected.json")
  let event : @timeline_v3.TimelineEvent = {
    entity_id: "order-1",
    logical_time: 11,
    sequence: 1,
    kind: @timeline_v3.TimelineKind::Policy,
    ref_id: "policy:submit",
    status: "deny",
    reasons: [
      reason("POLICY_DENY", "Policy denied execution", "transition"),
    ],
  }
  let page : TimelineEventPage = {
    detail: @timeline_event_v3_4.detail_from_event(event),
    prev_event_id: Some("order-1:10:1:transition"),
    next_event_id: Some("order-1:12:1:effect"),
  }
  let mut output = page_json(page).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
