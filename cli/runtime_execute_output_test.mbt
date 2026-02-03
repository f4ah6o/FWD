///|
fn read_text_execute(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_execution_fixture(
  rules_path : String,
  expected_path : String,
  transition_id : String,
) -> Unit raise {
  let schema_text = match read_text_execute(
    "examples/runtime_execute/model.yaml",
    "model",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let rules_text = match read_text_execute(rules_path, "rules") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = match read_text_execute(expected_path, "expected") {
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
    transition_id,
    rule_results,
  ) {
    Ok(value) => value
    Err(reason) => fail(reason.message())
  }
  let mut output = runtime_execute_json(outcome).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
fn load_execution_error_fixture(
  rules_path : String,
  expected_path : String,
  transition_id : String,
  state : String,
) -> Unit raise {
  let schema_text = match read_text_execute(
    "examples/runtime_execute/model.yaml",
    "model",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let rules_text = match read_text_execute(rules_path, "rules") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = match read_text_execute(expected_path, "expected") {
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
  let reason = match @runtime.execute_transition(
    ir,
    state,
    transition_id,
    rule_results,
  ) {
    Ok(_) => fail("expected execute to return error")
    Err(value) => value
  }
  let mut output = runtime_error_json(reason).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "runtime execute fixture (executed)" {
  load_execution_fixture(
    "examples/runtime_execute/rules.json",
    "examples/runtime_execute/expected_executed.json",
    "approve",
  )
}

///|
test "runtime execute fixture (blocked)" {
  load_execution_fixture(
    "examples/runtime_execute/rules.json",
    "examples/runtime_execute/expected_blocked.json",
    "reject",
  )
}

///|
test "runtime execute fixture (not found)" {
  load_execution_error_fixture(
    "examples/runtime_execute/rules.json",
    "examples/runtime_execute/expected_not_found.json",
    "missing",
    "Draft",
  )
}

///|
test "runtime execute fixture (not available)" {
  load_execution_error_fixture(
    "examples/runtime_execute/rules.json",
    "examples/runtime_execute/expected_not_available.json",
    "reject",
    "Approved",
  )
}
