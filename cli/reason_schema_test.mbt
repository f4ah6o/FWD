///|
struct ReasonSchema {
  required : Array[String]
  level_enum : Array[String]
  target_enum : Array[String]
  code_pattern : String
}

///|
fn json_object(json : Json, label : String) -> Result[Map[String, Json], String] {
  match json {
    Object(obj) => Ok(obj)
    _ => Err("expected object: " + label)
  }
}

///|
fn json_array(json : Json, label : String) -> Result[Array[Json], String] {
  match json {
    Array(arr) => Ok(arr)
    _ => Err("expected array: " + label)
  }
}

///|
fn json_string(json : Json, label : String) -> Result[String, String] {
  match json {
    String(value) => Ok(value)
    _ => Err("expected string: " + label)
  }
}

///|
fn json_number(json : Json, label : String) -> Result[Double, String] {
  match json {
    Number(value, ..) => Ok(value)
    _ => Err("expected number: " + label)
  }
}

///|
fn parse_json(input : String, label : String) -> Result[Json, String] {
  let result : Result[Json, @json.ParseError] = try? @json.parse(input)
  match result {
    Ok(value) => Ok(value)
    Err(err) => Err("json parse failed: " + label + ": " + err.to_string())
  }
}

///|
fn read_text(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn object_get(
  obj : Map[String, Json],
  key : String,
  label : String,
) -> Result[Json, String] {
  match obj.get(key) {
    Some(value) => Ok(value)
    None => Err("missing field: " + label)
  }
}

///|
fn load_reason_schema() -> Result[ReasonSchema, String] {
  let schema_text_result : Result[String, @fs.IOError] =
    try? @fs.read_file_to_string("schema/reason.schema.v1.json")
  let schema_text = match schema_text_result {
    Ok(text) => text
    Err(err) => return Err("read schema failed: " + err.to_string())
  }
  let schema_json = match parse_json(schema_text, "reason schema") {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let root = match json_object(schema_json, "schema root") {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let required_json = match object_get(root, "required", "schema.required") {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let required_raw = match json_array(required_json, "schema.required") {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let required : Array[String] = []
  for item in required_raw {
    match json_string(item, "schema.required item") {
      Ok(value) => required.push(value)
      Err(msg) => return Err(msg)
    }
  }
  let properties_json = match object_get(root, "properties", "schema.properties") {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let properties = match json_object(properties_json, "schema.properties") {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let reason_version = match object_get(
    properties,
    "reasonVersion",
    "schema.properties.reasonVersion",
  ) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let reason_version_obj = match json_object(
    reason_version,
    "schema.properties.reasonVersion",
  ) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let code_props = match object_get(properties, "code", "schema.properties.code") {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let code_obj = match json_object(code_props, "schema.properties.code") {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let level_props = match object_get(
    properties,
    "level",
    "schema.properties.level",
  ) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let level_obj = match json_object(level_props, "schema.properties.level") {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let target_props = match object_get(
    properties,
    "target",
    "schema.properties.target",
  ) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let target_obj = match json_object(target_props, "schema.properties.target") {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let reason_version_const = match object_get(
    reason_version_obj,
    "const",
    "schema.properties.reasonVersion.const",
  ) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let reason_version_value = match json_number(
    reason_version_const,
    "schema.properties.reasonVersion.const",
  ) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  if reason_version_value != 1.0 {
    return Err("reasonVersion.const must be 1")
  }
  let mut code_pattern : String? = None
  match object_get(code_obj, "pattern", "schema.properties.code.pattern") {
    Ok(value) =>
      match json_string(value, "schema.properties.code.pattern") {
        Ok(text) => code_pattern = Some(text)
        Err(msg) => return Err(msg)
      }
    Err(_) => ()
  }
  if code_pattern is None {
    let anyof_json = match object_get(
      code_obj,
      "anyOf",
      "schema.properties.code.anyOf",
    ) {
      Ok(value) => value
      Err(msg) => return Err(msg)
    }
    let anyof_items = match json_array(
      anyof_json,
      "schema.properties.code.anyOf",
    ) {
      Ok(value) => value
      Err(msg) => return Err(msg)
    }
    for item in anyof_items {
      let item_obj = match json_object(item, "schema.properties.code.anyOf item") {
        Ok(value) => value
        Err(msg) => return Err(msg)
      }
      match object_get(item_obj, "pattern", "schema.properties.code.anyOf.pattern") {
        Ok(value) =>
          match json_string(value, "schema.properties.code.anyOf.pattern") {
            Ok(text) => code_pattern = Some(text)
            Err(msg) => return Err(msg)
          }
        Err(_) => ()
      }
    }
  }
  let code_pattern_value = match code_pattern {
    Some(value) => value
    None => return Err("schema missing code pattern")
  }
  let level_enum_json = match object_get(
    level_obj,
    "enum",
    "schema.properties.level.enum",
  ) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let level_enum_raw = match json_array(
    level_enum_json,
    "schema.properties.level.enum",
  ) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let level_enum : Array[String] = []
  for item in level_enum_raw {
    match json_string(item, "schema.properties.level.enum item") {
      Ok(value) => level_enum.push(value)
      Err(msg) => return Err(msg)
    }
  }
  let target_enum_json = match object_get(
    target_obj,
    "enum",
    "schema.properties.target.enum",
  ) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let target_enum_raw = match json_array(
    target_enum_json,
    "schema.properties.target.enum",
  ) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let target_enum : Array[String] = []
  for item in target_enum_raw {
    match json_string(item, "schema.properties.target.enum item") {
      Ok(value) => target_enum.push(value)
      Err(msg) => return Err(msg)
    }
  }
  Ok({
    required,
    level_enum,
    target_enum,
    code_pattern: code_pattern_value,
  })
}

///|
fn is_code_char(ch : Int) -> Bool {
  (ch >= 65 && ch <= 90) || (ch >= 48 && ch <= 57) || ch == 95
}

///|
fn matches_code_pattern(pattern : String, code : String) -> Result[Bool, String] {
  if pattern != "^[A-Z0-9_]+$" {
    return Err("unsupported pattern: " + pattern)
  }
  if code.length() == 0 {
    return Ok(false)
  }
  for i in 0..<code.length() {
    if !is_code_char(code[i].to_int()) {
      return Ok(false)
    }
  }
  Ok(true)
}

///|
fn validate_reason_against_schema(
  schema : ReasonSchema,
  reason_json : Json,
) -> Result[Unit, String] {
  let reason = match reason_json {
    Object(obj) => obj
    _ => return Err("reason must be object")
  }
  for field in schema.required {
    match reason.get(field) {
      Some(_) => ()
      None => return Err("missing required field: " + field)
    }
  }
  let allowed_fields = [
    "reasonVersion",
    "code",
    "level",
    "target",
    "message",
    "hint",
  ]
  for entry in reason.to_array() {
    if !allowed_fields.contains(entry.0) {
      return Err("unexpected field: " + entry.0)
    }
  }
  match reason.get("reasonVersion") {
    Some(Number(value, ..)) => if value != 1.0 { return Err("reasonVersion must be 1") }
    _ => return Err("reasonVersion must be number")
  }
  match reason.get("code") {
    Some(String(code)) =>
      match matches_code_pattern(schema.code_pattern, code) {
        Ok(true) => ()
        Ok(false) => return Err("code does not match pattern")
        Err(msg) => return Err(msg)
      }
    _ => return Err("code must be string")
  }
  match reason.get("level") {
    Some(String(level)) =>
      if !schema.level_enum.contains(level) {
        return Err("level must be enum")
      }
    _ => return Err("level must be string")
  }
  match reason.get("target") {
    Some(String(target)) =>
      if !schema.target_enum.contains(target) {
        return Err("target must be enum")
      }
    _ => return Err("target must be string")
  }
  match reason.get("message") {
    Some(String(message)) => if message.length() == 0 { return Err("message empty") }
    _ => return Err("message must be string")
  }
  match reason.get("hint") {
    Some(String(hint)) => if hint.length() == 0 { return Err("hint empty") }
    Some(_) => return Err("hint must be string")
    None => ()
  }
  Ok(())
}

///|
fn extract_reasons(output_json : Json) -> Result[Array[Json], String] {
  let root = match json_object(output_json, "validation output") {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let reasons_json = match object_get(root, "reasons", "validation output reasons") {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  json_array(reasons_json, "validation output reasons")
}

///|
fn reason_field_non_empty(
  reason : Map[String, Json],
  key : String,
  label : String,
) -> Result[Unit, String] {
  match reason.get(key) {
    Some(String(value)) =>
      if value.length() == 0 {
        Err(label + " must be non-empty")
      } else {
        Ok(())
      }
    Some(_) => Err(label + " must be string")
    None => Err(label + " missing")
  }
}

///|
fn assert_baseline_reasons(
  schema : ReasonSchema,
  candidate_path : String,
  baseline_path : String,
  expected_codes : Array[String],
) -> Result[Unit, String] {
  let candidate = match read_text(candidate_path, "candidate") {
    Ok(text) => text
    Err(msg) => return Err(msg)
  }
  let baseline = match read_text(baseline_path, "baseline") {
    Ok(text) => text
    Err(msg) => return Err(msg)
  }
  let reasons = match @compiler.validate_with_baseline(candidate, baseline) {
    Ok(_) => return Err("expected baseline diff to fail")
    Err(items) => items
  }
  let output = @compiler.validation_json_string(false, reasons)
  let output_json = match parse_json(output, "baseline output") {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let reason_items = match extract_reasons(output_json) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let found_codes : Array[String] = []
  for item in reason_items {
    match validate_reason_against_schema(schema, item) {
      Ok(_) => ()
      Err(msg) => return Err("schema validation failed: " + msg)
    }
    let reason_obj = match json_object(item, "baseline reason") {
      Ok(value) => value
      Err(msg) => return Err(msg)
    }
    match object_get(reason_obj, "code", "baseline reason code") {
      Ok(String(code)) => found_codes.push(code)
      Ok(_) => return Err("baseline reason code must be string")
      Err(msg) => return Err(msg)
    }
    match reason_field_non_empty(reason_obj, "target", "baseline reason target") {
      Ok(_) => ()
      Err(msg) => return Err(msg)
    }
    match reason_field_non_empty(reason_obj, "hint", "baseline reason hint") {
      Ok(_) => ()
      Err(msg) => return Err(msg)
    }
  }
  for code in expected_codes {
    if !found_codes.contains(code) {
      return Err("expected baseline reason code missing: " + code)
    }
  }
  Ok(())
}

///|
test "reason json schema validation" {
  let schema = match load_reason_schema() {
    Ok(value) => value
    Err(msg) => fail(msg)
  }
  let reasons : Array[@core.Reason] = []
  reasons.push(
    @core.Reason::with_context(
      "unknown_state",
      "transition.to is not defined in states",
      [
        ("state", "Missing"),
        ("target", "state"),
        ("level", "error"),
      ],
    ),
  )
  let output = @compiler.validation_json_string(false, reasons)
  let output_json = match parse_json(output, "validation output") {
    Ok(value) => value
    Err(msg) => fail(msg)
  }
  let root = match json_object(output_json, "validation output") {
    Ok(value) => value
    Err(msg) => fail(msg)
  }
  let reasons_json = match object_get(root, "reasons", "validation output reasons") {
    Ok(value) => value
    Err(msg) => fail(msg)
  }
  let reason_items = match json_array(reasons_json, "validation output reasons") {
    Ok(value) => value
    Err(msg) => fail(msg)
  }
  for item in reason_items {
    match validate_reason_against_schema(schema, item) {
      Ok(_) => ()
      Err(msg) => fail("schema validation failed: " + msg)
    }
  }
  let invalid_text =
    #|{
    #|  "reasonVersion": 1,
    #|  "code": "BAD CODE",
    #|  "level": "fatal",
    #|  "target": "schema",
    #|  "message": "bad"
    #|}
  let invalid_reason = match parse_json(invalid_text, "invalid reason") {
    Ok(value) => value
    Err(msg) => fail(msg)
  }
  match validate_reason_against_schema(schema, invalid_reason) {
    Ok(_) => fail("expected invalid reason to fail schema validation")
    Err(_) => ()
  }
  let reserved_reasons : Array[@core.Reason] = []
  reserved_reasons.push(
    @core.Reason::with_context(
      "RESERVED_WORD_CONFLICT",
      "rule name conflicts with builtin: hasAtLeastOneState",
      [
        ("target", "rule"),
        ("hint", "Builtin rule names are reserved"),
      ],
    ),
  )
  let reserved_output = @compiler.validation_json_string(false, reserved_reasons)
  let reserved_json = match parse_json(reserved_output, "reserved output") {
    Ok(value) => value
    Err(msg) => fail(msg)
  }
  let reserved_root = match json_object(reserved_json, "reserved output") {
    Ok(value) => value
    Err(msg) => fail(msg)
  }
  let reserved_reasons_json = match object_get(
    reserved_root,
    "reasons",
    "reserved output reasons",
  ) {
    Ok(value) => value
    Err(msg) => fail(msg)
  }
  let reserved_items = match json_array(
    reserved_reasons_json,
    "reserved output reasons",
  ) {
    Ok(value) => value
    Err(msg) => fail(msg)
  }
  for item in reserved_items {
    match validate_reason_against_schema(schema, item) {
      Ok(_) => ()
      Err(msg) => fail("schema validation failed: " + msg)
    }
  }
  match assert_baseline_reasons(
    schema,
    "examples/remove-state.yaml",
    "examples/fwd_schema_change_valid.yaml",
    ["STATE_REMOVED", "MIGRATION_REQUIRED"],
  ) {
    Ok(_) => ()
    Err(msg) => fail(msg)
  }
  match assert_baseline_reasons(
    schema,
    "examples/remove-transition.yaml",
    "examples/fwd_schema_change_valid.yaml",
    ["TRANSITION_REMOVED", "MIGRATION_REQUIRED"],
  ) {
    Ok(_) => ()
    Err(msg) => fail(msg)
  }
  match assert_baseline_reasons(
    schema,
    "examples/modify-transition.yaml",
    "examples/fwd_schema_change_valid.yaml",
    ["TRANSITION_MODIFIED", "MIGRATION_REQUIRED"],
  ) {
    Ok(_) => ()
    Err(msg) => fail(msg)
  }
}
