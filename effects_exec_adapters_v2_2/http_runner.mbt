///|
/// HTTP effects runner adapter (v2.2).

///|
pub(all) struct HttpRequest {
  http_method : String
  url : String
  headers : Map[String, String]
  body : String
}

///|
pub(all) struct HttpResponse {
  status : Int
  body : String
}

///|
fn http_reason(message : String, hint : String) -> @core.Reason {
  @core.Reason::with_context(
    "EFFECT_EXECUTION_FAILED",
    message,
    [
      ("target", "effect"),
      ("level", "error"),
      ("hint", hint),
    ],
  )
}

///|
fn allowlisted(allowlist : Array[String], url : String) -> Bool {
  for prefix in allowlist {
    if url.has_prefix(prefix) {
      return true
    }
  }
  false
}

///|
fn extract_url(payload : Json) -> Result[String, @core.Reason] {
  match payload {
    Object(m) =>
      match m.get("url") {
        Some(String(value)) => Ok(value)
        Some(_) => Err(http_reason("payload.url must be string", "Use {\"url\": \"...\"}"))
        None => Err(http_reason("missing payload.url", "Provide url in payload"))
      }
    _ => Err(http_reason("payload must be object", "Provide {\"url\": \"...\"}"))
  }
}

///|
pub fn run_http_effect(
  allowlist : Array[String],
  effect : @effects_v2_2.EffectItem,
  send : (HttpRequest) -> Result[HttpResponse, @core.Reason],
) -> Result[@effects_v2_2.ExecutionItem, @core.Reason] {
  match effect.kind {
    @core.EffectKind::Async => ()
    @core.EffectKind::Sync => ()
  }
  let url = match extract_url(effect.payload) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  if !allowlisted(allowlist, url) {
    return Err(http_reason("url not allowlisted", "Allowlist the url prefix"))
  }
  let headers : Map[String, String] = Map::new()
  headers["Idempotency-Key"] = effect.idempotency_key
  let req : HttpRequest = {
    http_method: "POST",
    url,
    headers,
    body: effect.payload.stringify(indent=2),
  }
  match send(req) {
    Ok(_) => Ok({
      effect_id: effect.effect_id,
      status: @effects_v2_2.ExecutionStatus::Executed,
      reason: None,
    })
    Err(reason) => Ok({
      effect_id: effect.effect_id,
      status: @effects_v2_2.ExecutionStatus::Failed,
      reason: Some(reason),
    })
  }
}
