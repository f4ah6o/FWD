///|
fn read_text_resource(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected(path : String) -> String raise {
  match read_text_resource(path, "expected") {
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

fn build_resource_v3() -> ResourceV3 {
  let payload_obj : Map[String, Json] = Map::new()
  payload_obj["amount"] = Json::number(10.0)
  let payload = Json::object(payload_obj)
  let policy : @policy_v3.PolicyDecision = {
    entity_id: "order-1",
    transition_id: "submit",
    decision: @policy_v3.PolicyDecisionKind::Deny,
    reasons: [
      reason("POLICY_DENY", "Policy denied execution", "transition"),
    ],
  }
  let plan : @effects_v2_2.EffectsPlan = {
    plan_version: @effects_v2_2.plan_version_v2_2(),
    entity_id: "order-1",
    transition_id: "submit",
    status: @effects_v2_2.PlanStatus::Planned,
    items: [],
    reasons: [],
  }
  {
    state: "Draft",
    transitions: [
      {
        id: "submit",
        to: "Approved",
        input_schema: Some("PayloadV1"),
        draft_payload: Some(payload),
        field_errors: [],
        policy_decision: Some(policy),
        effects_preview: Some(plan),
        can_execute: false,
      },
    ],
  }
}

///|
test "resource v3 json fixture" {
  let expected = load_expected("examples/resource_v3/expected.json")
  let resource = build_resource_v3()
  let mut output = resource_v3_json(resource).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
