///|
fn read_text_runtime(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
test "runtime available fixture" {
  let schema_text = match read_text_runtime(
    "examples/runtime_available/model.yaml",
    "model",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let rules_text = match read_text_runtime(
    "examples/runtime_available/rules.json",
    "rules",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = match read_text_runtime(
    "examples/runtime_available/expected.json",
    "expected",
  ) {
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
  let result = match @runtime.compute_available_transitions(
    ir,
    "Draft",
    rule_results,
  ) {
    Ok(value) => value
    Err(reason) => fail(reason.message())
  }
  let mut output = runtime_output_json(result).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "runtime invalid input json" {
  let expected = match read_text_runtime(
    "examples/runtime_available/invalid_input.json",
    "invalid expected",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let reason = match parse_rule_results("true") {
    Ok(_) => fail("expected invalid input to fail")
    Err(value) => value
  }
  let mut output = runtime_error_json(reason).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
