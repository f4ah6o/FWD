///|
fn dummy_send(_req : HttpRequest) -> Result[HttpResponse, @core.Reason] {
  Ok({ status: 200, body: "ok" })
}

///|
test "http runner allowlist blocks" {
  let effect : @effects_v2_2.EffectItem = {
    effect_id: "notify",
    kind: @core.EffectKind::Async,
    payload: Json::object({ "url": Json::string("https://example.com/hook") }),
    idempotency_key: "k",
  }
  let result = run_http_effect(["https://allowed.example/"], effect, dummy_send)
  guard result is Err(_) else {
    fail("expected allowlist block")
  }
}

///|
test "http runner allowlist passes" {
  let effect : @effects_v2_2.EffectItem = {
    effect_id: "notify",
    kind: @core.EffectKind::Async,
    payload: Json::object({ "url": Json::string("https://allowed.example/hook") }),
    idempotency_key: "k",
  }
  let result = run_http_effect(["https://allowed.example/"], effect, dummy_send)
  guard result is Ok(item) else {
    fail("expected ok")
  }
  inspect(item.effect_id, content="notify")
  match item.status {
    @effects_v2_2.ExecutionStatus::Executed => ()
    _ => fail("expected executed status")
  }
}
