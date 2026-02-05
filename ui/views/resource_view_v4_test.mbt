///|
fn read_text_view_v4(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected_v4(path : String) -> String raise {
  match read_text_view_v4(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

fn reason_v4(message : String, hint : String?) -> V4ReasonView {
  { message, hint }
}

///|
test "v4 resource html fixture" {
  let expected = load_expected_v4("examples/v4/html/resource_expected.html")
  let view : V4ResourceView = {
    entity: { id: "order-1", state: "Draft", logical_time: 12 },
    draft_reason: "Need approval",
    field_errors: [
      {
        path: "/reason",
        reason: reason_v4("reason is required", Some("Provide a non-empty reason")),
      },
    ],
    policy: {
      decision: "deny",
      reasons: [reason_v4("Policy denied execution", None)],
    },
    effects: {
      plan_status: "planned",
      execution_status: "skipped",
      reasons: [reason_v4("Rule not satisfied", Some("Provide rule result true for this transition"))],
    },
    timeline: {
      cursor: "offset:0",
      events: [
        {
          event_id: "order-1:11:1:policy",
          kind: "policy",
          ref_id: "policy:submit",
          status: "deny",
          reasons: [reason_v4("Policy denied execution", None)],
        },
      ],
    },
  }
  let mut output = render_resource_html_v4(view)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "v4 resource mx html fixture" {
  let expected = load_expected_v4("examples/v4/html/resource_mx_expected.html")
  let view : V4ResourceView = {
    entity: { id: "order-1", state: "Draft", logical_time: 12 },
    draft_reason: "Need approval",
    field_errors: [
      {
        path: "/reason",
        reason: reason_v4("reason is required", Some("Provide a non-empty reason")),
      },
    ],
    policy: {
      decision: "deny",
      reasons: [reason_v4("Policy denied execution", None)],
    },
    effects: {
      plan_status: "planned",
      execution_status: "skipped",
      reasons: [reason_v4("Rule not satisfied", Some("Provide rule result true for this transition"))],
    },
    timeline: {
      cursor: "offset:0",
      events: [
        {
          event_id: "order-1:11:1:policy",
          kind: "policy",
          ref_id: "policy:submit",
          status: "deny",
          reasons: [reason_v4("Policy denied execution", None)],
        },
      ],
    },
  }
  let mut output = render_resource_html_v4_mx(view)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
