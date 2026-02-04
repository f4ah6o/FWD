///|
fn read_text_policy(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected(path : String) -> String raise {
  match read_text_policy(path, "expected") {
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
test "policy allow fixture" {
  let expected = load_expected("examples/v3/policy/expected_allow.json")
  let decision : PolicyDecision = {
    entity_id: "order-1",
    transition_id: "submit",
    decision: PolicyDecisionKind::Allow,
    reasons: [],
  }
  let mut output = policy_decision_json(decision).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "policy deny fixture" {
  let expected = load_expected("examples/v3/policy/expected_deny.json")
  let decision : PolicyDecision = {
    entity_id: "order-1",
    transition_id: "submit",
    decision: PolicyDecisionKind::Deny,
    reasons: [
      reason("POLICY_DENY", "Policy denied execution", "transition"),
    ],
  }
  let mut output = policy_decision_json(decision).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
