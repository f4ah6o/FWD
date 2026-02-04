///|
fn read_text_effects_cli(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_effects_fixture(
  rules_path : String,
  expected_path : String,
) -> Unit raise {
  let schema_text = match read_text_effects_cli(
    "examples/effects_v2_2/model.yaml",
    "model",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let rules_text = match read_text_effects_cli(rules_path, "rules") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = match read_text_effects_cli(expected_path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let ir = match @compiler.compile_yaml(schema_text) {
    Ok(value) => value
    Err(err) => fail(@compiler.describe_error(err))
  }
  let rule_results = match parse_rule_results(rules_text) {
    Ok(values) => values
    Err(reason) => fail(reason.message())
  }
  let outcome = match @runtime.execute_transition(
    ir,
    "Draft",
    "submit",
    rule_results,
  ) {
    Ok(value) => value
    Err(reason) => fail(reason.message())
  }
  let plan = @effects_v2_2.plan_from_execution("order-1", outcome)
  let mut output = @effects_v2_2.effect_plan_json(plan).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "effects plan cli fixture (planned)" {
  load_effects_fixture(
    "examples/effects_v2_2/rules_planned.json",
    "examples/effects_v2_2/cli_planned/expected.json",
  )
}

///|
test "effects plan cli fixture (skipped)" {
  load_effects_fixture(
    "examples/effects_v2_2/rules_blocked.json",
    "examples/effects_v2_2/cli_skipped/expected.json",
  )
}
