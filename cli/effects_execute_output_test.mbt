///|
fn read_text_effects_exec(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_exec_fixture(
  plan_path : String,
  expected_path : String,
) -> Unit raise {
  let plan_text = match read_text_effects_exec(plan_path, "plan") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let expected = match read_text_effects_exec(expected_path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let plan = match @effects_v2_2.parse_plan_json(plan_text) {
    Ok(value) => value
    Err(reason) => fail(reason.message())
  }
  let result = @effects_v2_2.execute_plan_stub(plan)
  let mut output = @effects_v2_2.execution_result_json(result).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "effects execute fixture (executed)" {
  load_exec_fixture(
    "examples/effects_v2_2/execute/plan_planned.json",
    "examples/effects_v2_2/execute/expected_executed.json",
  )
}

///|
test "effects execute fixture (skipped)" {
  load_exec_fixture(
    "examples/effects_v2_2/execute/plan_skipped.json",
    "examples/effects_v2_2/execute/expected_skipped.json",
  )
}
