///|
fn read_text_plain(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn parse_rule_results_local(input_json : String) -> Result[Map[String, Bool], @core.Reason] {
  parse_rule_results(input_json)
}

///|
test "hypermedia show fixture" {
  let schema_text = match read_text_plain(
    "examples/hypermedia_show/model.yaml",
    "model",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let rules_text = match read_text_plain(
    "examples/hypermedia_show/rules.json",
    "rules",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = match read_text_plain(
    "examples/hypermedia_show/expected.json",
    "expected",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let ir = match @compiler.compile_yaml(schema_text) {
    Ok(value) => value
    Err(err) => fail(@compiler.describe_error(err))
  }
  let rule_results = match parse_rule_results_local(rules_text) {
    Ok(values) => values
    Err(reason) => fail(reason.message())
  }
  let runtime_result = match @runtime.compute_available_transitions(
    ir,
    "Draft",
    rule_results,
  ) {
    Ok(value) => value
    Err(reason) => fail(reason.message())
  }
  let resource = @hypermedia.resource_from_runtime(runtime_result)
  let mut output = @hypermedia.resource_json(resource).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "hypermedia invalid input json" {
  let expected = match read_text_plain(
    "examples/hypermedia_show/invalid_input.json",
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
