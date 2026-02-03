///|
/// Hypermedia input parsing (v1): parse rule results.

///|
pub fn parse_rule_results(
  input_json : String,
) -> Result[Map[String, Bool], @core.Reason] {
  let parsed : Result[Json, @json.ParseError] = try? @json.parse(input_json)
  let value = match parsed {
    Ok(v) => v
    Err(err) =>
      return Err(
        @core.Reason::with_context(
          "INPUT_JSON_INVALID",
          "input json parse error: " + err.to_string(),
          [
            ("target", "runtime"),
            ("level", "error"),
            ("hint", "Provide valid JSON for --input"),
          ],
        ),
      )
  }
  let obj = match value {
    Object(m) => m
    _ =>
      return Err(
        @core.Reason::with_context(
          "INPUT_JSON_INVALID",
          "input json must be an object",
          [
            ("target", "runtime"),
            ("level", "error"),
            ("hint", "Provide an object of rule results or {\"rules\": {...}}"),
          ],
        ),
      )
  }
  let rules_obj = match obj.get("rules") {
    Some(Object(m)) => m
    Some(_) =>
      return Err(
        @core.Reason::with_context(
          "INPUT_JSON_INVALID",
          "rules must be an object",
          [
            ("target", "runtime"),
            ("level", "error"),
            ("hint", "Use {\"rules\": {\"ruleName\": true}}"),
          ],
        ),
      )
    None => obj
  }
  let results : Map[String, Bool] = Map::new()
  for entry in rules_obj.to_array() {
    match entry.1 {
      True => results[entry.0] = true
      False => results[entry.0] = false
      _ =>
        return Err(
          @core.Reason::with_context(
            "INPUT_JSON_INVALID",
            "rule result must be boolean",
            [
              ("rule", entry.0),
              ("target", "runtime"),
              ("level", "error"),
              ("hint", "Use true/false for each rule result"),
            ],
          ),
        )
    }
  }
  Ok(results)
}
