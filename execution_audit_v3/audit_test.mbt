///|
fn read_text_audit(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected(path : String) -> String raise {
  match read_text_audit(path, "expected") {
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
test "audit executed fixture" {
  let expected = load_expected("examples/v3/execution_audit/expected_executed.json")
  let event : AuditEvent = {
    entity_id: "order-1",
    transition_id: "submit",
    logical_time: 10,
    sequence: 1,
    status: AuditStatus::Executed,
    items: [
      {
        effect_id: "http:notify",
        status: ItemStatus::Executed,
        duration_ms: 120,
        reason: None,
      },
    ],
    reasons: [],
  }
  let mut output = audit_event_json(event).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "audit blocked fixture" {
  let expected = load_expected("examples/v3/execution_audit/expected_blocked.json")
  let event : AuditEvent = {
    entity_id: "order-1",
    transition_id: "submit",
    logical_time: 11,
    sequence: 1,
    status: AuditStatus::Blocked,
    items: [],
    reasons: [
      reason("RULE_NOT_SATISFIED", "Rule not satisfied", "runtime"),
    ],
  }
  let mut output = audit_event_json(event).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "audit partial failure fixture" {
  let expected = load_expected("examples/v3/execution_audit/expected_partial_failed.json")
  let event : AuditEvent = {
    entity_id: "order-1",
    transition_id: "submit",
    logical_time: 12,
    sequence: 1,
    status: AuditStatus::Failed,
    items: [
      {
        effect_id: "http:notify",
        status: ItemStatus::Executed,
        duration_ms: 90,
        reason: None,
      },
      {
        effect_id: "http:archive",
        status: ItemStatus::Failed,
        duration_ms: 300,
        reason: Some(reason("EFFECT_HTTP_FAILED", "HTTP request failed", "effect")),
      },
    ],
    reasons: [],
  }
  let mut output = audit_event_json(event).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
