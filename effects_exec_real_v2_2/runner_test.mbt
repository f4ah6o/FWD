///|
fn read_text_real(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_fixture(path : String) -> String raise {
  match read_text_real(path, "fixture") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
fn fake_send(_req : @effects_exec_adapters_v2_2.HttpRequest) -> Result[@effects_exec_adapters_v2_2.HttpResponse, @core.Reason] {
  Ok({ status: 200, body: "{\"ok\":true}" })
}

///|
test "real runner uses config allowlist" {
  let plan_text = load_fixture("examples/effects_v2_2/record_cli/plan.json")
  let config_text = load_fixture("examples/effects_v2_2/real_runner/config.json")
  let expected = load_fixture("examples/effects_v2_2/real_runner/expected_execution.json")
  let plan = match @effects_v2_2.parse_plan_json(plan_text) {
    Ok(value) => value
    Err(reason) => fail(reason.message())
  }
  let config = match parse_config_json(config_text) {
    Ok(value) => value
    Err(reason) => fail(reason.message())
  }
  let result = execute_with_transport(plan, config, fake_send)
  let mut output = @effects_v2_2.execution_result_json(result).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
