///|
///|
fn parse_rule_results_text(input_json : String) -> Result[Map[String, Bool], String] {
  match parse_rule_results(input_json) {
    Ok(values) => Ok(values)
    Err(reason) => Err(reason.message())
  }
}

///|
test "hypermedia resource fixture" {
  let schema_text = match read_text(
    "examples/hypermedia_show/model.yaml",
    "model",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let rules_text = match read_text(
    "examples/hypermedia_show/rules.json",
    "rules",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = match read_text(
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
  let rule_results = match parse_rule_results_text(rules_text) {
    Ok(values) => values
    Err(msg) => fail(msg)
  }
  let runtime_result = match @runtime.compute_available_transitions(
    ir,
    "Draft",
    rule_results,
  ) {
    Ok(value) => value
    Err(reason) => fail(reason.message())
  }
  let resource = resource_from_runtime(runtime_result)
  let mut output = resource_json(resource).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
