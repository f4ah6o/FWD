///|
/// Replay transport using a cassette (v2.2).

///|
fn replay_miss_reason() -> @core.Reason {
  @core.Reason::with_context(
    "EFFECT_REPLAY_MISS",
    "cassette entry not found",
    [
      ("target", "effect"),
      ("level", "error"),
      ("hint", "Record a cassette entry for this request"),
    ],
  )
}

///|
fn header_value(headers : Map[String, String], name : String) -> String? {
  headers.get(name)
}

///|
fn requests_match(
  entry : CassetteEntry,
  req : @effects_exec_adapters_v2_2.HttpRequest,
) -> Bool {
  if entry.request.http_method != req.http_method {
    return false
  }
  if entry.request.url != req.url {
    return false
  }
  if entry.request.body != req.body {
    return false
  }
  let expected_key = header_value(entry.request.headers, "Idempotency-Key")
  let actual_key = header_value(req.headers, "Idempotency-Key")
  match (expected_key, actual_key) {
    (None, None) => true
    (Some(a), Some(b)) => a == b
    _ => false
  }
}

///|
pub fn replay_transport(
  cassette : Cassette,
) -> (@effects_exec_adapters_v2_2.HttpRequest) -> Result[@effects_exec_adapters_v2_2.HttpResponse, @core.Reason] {
  fn transport(req : @effects_exec_adapters_v2_2.HttpRequest) -> Result[@effects_exec_adapters_v2_2.HttpResponse, @core.Reason] {
    for entry in cassette.entries {
      if requests_match(entry, req) {
        return Ok({
          status: entry.response.status,
          body: entry.response.body,
        })
      }
    }
    Err(replay_miss_reason())
  }
  transport
}
