///|
fn read_text_rr(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected(path : String) -> String raise {
  match read_text_rr(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
fn load_cassette() -> Cassette raise {
  let text = load_expected("examples/effects_v2_2/record_replay/cassette_example.json")
  match parse_cassette_json(text) {
    Ok(value) => value
    Err(reason) => fail(reason.message())
  }
}

///|
fn to_execution_result(item : @effects_v2_2.ExecutionItem) -> @effects_v2_2.ExecutionResult {
  {
    result_version: @effects_v2_2.result_version_v2_2(),
    plan_version: "2.2",
    entity_id: "order-1",
    transition_id: "submit",
    status: @effects_v2_2.ExecutionStatus::Executed,
    items: [item],
    reasons: [],
  }
}

///|
test "replay transport matches cassette" {
  let cassette = load_cassette()
  let transport = replay_transport(cassette)
  let effect : @effects_v2_2.EffectItem = {
    effect_id: "notify",
    kind: @core.EffectKind::Async,
    payload: Json::object({ "url": Json::string("https://allowed.example/hook") }),
    idempotency_key: "order-1:submit:notify",
  }
  let result = @effects_exec_adapters_v2_2.run_http_effect(
    ["https://allowed.example/"],
    effect,
    transport,
  )
  guard result is Ok(item) else {
    fail("expected replayed response")
  }
  let exec_result = to_execution_result(item)
  let expected = load_expected("examples/effects_v2_2/record_replay/expected_executed.json")
  let mut output = @effects_v2_2.execution_result_json(exec_result).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
