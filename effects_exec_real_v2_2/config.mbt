///|
/// Real runner config (v2.2).

///|
pub(all) struct RunnerConfig {
  allowlist : Array[String]
  timeout_ms : Int?
}

///|
fn invalid_config_reason(message : String) -> @core.Reason {
  @core.Reason::with_context(
    "INPUT_JSON_INVALID",
    message,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Provide valid runner config JSON"),
    ],
  )
}

///|
fn extract_allowlist(obj : Map[String, Json]) -> Result[Array[String], @core.Reason] {
  match obj.get("allowlist") {
    Some(Array(values)) => {
      let list : Array[String] = []
      for value in values {
        match value {
          String(v) => list.push(v)
          _ => return Err(invalid_config_reason("allowlist must be string array"))
        }
      }
      if list.length() == 0 {
        return Err(invalid_config_reason("allowlist must not be empty"))
      }
      Ok(list)
    }
    Some(_) => Err(invalid_config_reason("allowlist must be array"))
    None => Err(invalid_config_reason("missing field: allowlist"))
  }
}

///|
fn extract_timeout(obj : Map[String, Json]) -> Int? {
  match obj.get("timeoutMs") {
    Some(Number(value, ..)) => Some(value.to_int())
    _ => None
  }
}

///|
pub fn parse_config_json(input_json : String) -> Result[RunnerConfig, @core.Reason] {
  let parsed : Result[Json, @json.ParseError] = try? @json.parse(input_json)
  let value = match parsed {
    Ok(v) => v
    Err(err) => return Err(invalid_config_reason("input json parse error: " + err.to_string()))
  }
  let obj = match value {
    Object(m) => m
    _ => return Err(invalid_config_reason("input json must be an object"))
  }
  let allowlist = match extract_allowlist(obj) {
    Ok(list) => list
    Err(reason) => return Err(reason)
  }
  let timeout_ms = extract_timeout(obj)
  Ok({ allowlist, timeout_ms })
}
