///|
fn read_text_plain_mx(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
test "resource html fixture (mx)" {
  let schema_text = match read_text_plain_mx(
    "examples/hypermedia_show/model.yaml",
    "model",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let rules_text = match read_text_plain_mx(
    "examples/hypermedia_show/rules.json",
    "rules",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = match read_text_plain_mx(
    "examples/hypermedia_show/expected_mx.html",
    "expected",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let ir = match @compiler.compile_yaml(schema_text) {
    Ok(value) => value
    Err(err) => fail(@compiler.describe_error(err))
  }
  let rule_results = match @hypermedia.parse_rule_results(rules_text) {
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
  let mut output = render_resource_html_mx(resource)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
