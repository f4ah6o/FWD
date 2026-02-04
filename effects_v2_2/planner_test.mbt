///|
fn read_text_effects(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_model() -> String raise {
  match read_text_effects("examples/effects_v2_2/model.yaml", "model") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
fn load_expected(path : String) -> String raise {
  match read_text_effects(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
fn plan_output(plan : EffectsPlan) -> String {
  effect_plan_json(plan).stringify(indent=2)
}

///|
test "effects plan planned fixture" {
  let schema_text = load_model()
  let expected = load_expected("examples/effects_v2_2/planned/expected.json")
  let ir = match @compiler.compile_yaml(schema_text) {
    Ok(value) => value
    Err(err) => fail(@compiler.describe_error(err))
  }
  let rules : Map[String, Bool] = Map::new()
  rules["canSubmit"] = true
  let outcome = match @runtime.execute_transition(ir, "Draft", "submit", rules) {
    Ok(value) => value
    Err(reason) => fail(reason.message())
  }
  let plan = plan_from_execution("order-1", outcome)
  let mut output = plan_output(plan)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "effects plan skipped fixture" {
  let schema_text = load_model()
  let expected = load_expected("examples/effects_v2_2/skipped_blocked/expected.json")
  let ir = match @compiler.compile_yaml(schema_text) {
    Ok(value) => value
    Err(err) => fail(@compiler.describe_error(err))
  }
  let rules : Map[String, Bool] = Map::new()
  rules["canSubmit"] = false
  let outcome = match @runtime.execute_transition(ir, "Draft", "submit", rules) {
    Ok(value) => value
    Err(reason) => fail(reason.message())
  }
  let plan = plan_from_execution("order-1", outcome)
  let mut output = plan_output(plan)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
