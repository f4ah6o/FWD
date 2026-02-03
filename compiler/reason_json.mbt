///|
fn rj_json_string(value : String) -> Json {
  Json::string(value)
}

///|
fn is_ascii_lower(ch : Int) -> Bool {
  ch >= 97 && ch <= 122
}

///|
fn is_ascii_upper(ch : Int) -> Bool {
  ch >= 65 && ch <= 90
}

///|
fn is_ascii_digit(ch : Int) -> Bool {
  ch >= 48 && ch <= 57
}

///|
fn normalize_code(code : String) -> String {
  let sb = StringBuilder::new()
  let mut prev_is_underscore = false
  let mut prev_is_lower = false
  let mut prev_is_digit = false
  for i in 0..<code.length() {
    let ch = code[i].to_int()
    if is_ascii_upper(ch) {
      if (prev_is_lower || prev_is_digit) && !prev_is_underscore {
        sb.write_char('_')
      }
      sb.write_char(Int::unsafe_to_char(ch))
      prev_is_underscore = false
      prev_is_lower = false
      prev_is_digit = false
    } else if is_ascii_lower(ch) {
      sb.write_char(Int::unsafe_to_char(ch - 32))
      prev_is_underscore = false
      prev_is_lower = true
      prev_is_digit = false
    } else if is_ascii_digit(ch) {
      sb.write_char(Int::unsafe_to_char(ch))
      prev_is_underscore = false
      prev_is_lower = false
      prev_is_digit = true
    } else {
      if !prev_is_underscore {
        sb.write_char('_')
      }
      prev_is_underscore = true
      prev_is_lower = false
      prev_is_digit = false
    }
  }
  sb.to_string()
}

///|
fn find_last_context_value(
  context : Array[(String, String)],
  key : String,
) -> String? {
  for i in 0..<context.length() {
    let index = context.length() - 1 - i
    let pair = context[index]
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
fn is_known_level(level : String) -> Bool {
  level == "error" || level == "warn" || level == "info"
}

///|
fn is_known_target(target : String) -> Bool {
  target == "schema" ||
  target == "state" ||
  target == "transition" ||
  target == "rule" ||
  target == "effect" ||
  target == "baseline" ||
  target == "runtime"
}

///|
fn reason_level(reason : @core.Reason) -> String {
  match find_last_context_value(reason.context(), "level") {
    Some(level) => if is_known_level(level) { level } else { "error" }
    None => "error"
  }
}

///|
fn reason_target(reason : @core.Reason) -> String {
  match find_last_context_value(reason.context(), "target") {
    Some(target) => if is_known_target(target) { return target } else { () }
    None => ()
  }
  let code = reason.code()
  if code == "MIGRATION_REQUIRED" {
    return "baseline"
  }
  let context = reason.context()
  if find_last_context_value(context, "state") is Some(_) {
    return "state"
  }
  if find_last_context_value(context, "transition") is Some(_) {
    return "transition"
  }
  if find_last_context_value(context, "rule") is Some(_) {
    return "rule"
  }
  if find_last_context_value(context, "effect") is Some(_) {
    return "effect"
  }
  "schema"
}

///|
fn reason_hint(reason : @core.Reason) -> String? {
  match find_last_context_value(reason.context(), "hint") {
    Some(hint) => if hint.length() > 0 { Some(hint) } else { None }
    None => None
  }
}

///|
fn json_string_value(value : String) -> String {
  Json::string(value).stringify()
}

///|
fn json_bool_value(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
///|
fn reason_json_string_output(reason : @core.Reason) -> String {
  let hint = reason_hint(reason)
  let sb = StringBuilder::new()
  sb.write_view("    {\n")
  sb.write_view("      \"reasonVersion\": 1,\n")
  sb.write_view("      \"code\": ")
  sb.write_view(json_string_value(normalize_code(reason.code())))
  sb.write_view(",\n")
  sb.write_view("      \"level\": ")
  sb.write_view(json_string_value(reason_level(reason)))
  sb.write_view(",\n")
  sb.write_view("      \"target\": ")
  sb.write_view(json_string_value(reason_target(reason)))
  sb.write_view(",\n")
  sb.write_view("      \"message\": ")
  sb.write_view(json_string_value(reason.message()))
  match hint {
    Some(value) => {
      sb.write_view(",\n")
      sb.write_view("      \"hint\": ")
      sb.write_view(json_string_value(value))
      sb.write_char('\n')
    }
    None => sb.write_char('\n')
  }
  sb.write_view("    }")
  sb.to_string()
}

///|
pub fn reason_json(reason : @core.Reason) -> Json {
  let hint = reason_hint(reason)
  let obj : Map[String, Json] = Map::new()
  obj["reasonVersion"] = Json::number(1)
  obj["code"] = rj_json_string(normalize_code(reason.code()))
  obj["level"] = rj_json_string(reason_level(reason))
  obj["target"] = rj_json_string(reason_target(reason))
  obj["message"] = rj_json_string(reason.message())
  match hint {
    Some(value) => obj["hint"] = rj_json_string(value)
    None => ()
  }
  Json::object(obj)
}

///|
pub fn validation_json(ok : Bool, reasons : Array[@core.Reason]) -> Json {
  let obj : Map[String, Json] = Map::new()
  if ok {
    obj["ok"] = Json::boolean(true)
    return Json::object(obj)
  }
  obj["ok"] = Json::boolean(false)
  obj["errorCount"] = Json::number(reasons.length().to_double())
  obj["reasons"] = Json::array(reasons.map(reason_json))
  Json::object(obj)
}

///|
pub fn validation_json_string(
  ok : Bool,
  reasons : Array[@core.Reason],
) -> String {
  let sb = StringBuilder::new()
  sb.write_char('{')
  sb.write_char('\n')
  sb.write_view("  \"ok\": ")
  sb.write_view(json_bool_value(ok))
  if ok {
    sb.write_char('\n')
    sb.write_char('}')
    return sb.to_string()
  }
  sb.write_view(",\n")
  sb.write_view("  \"errorCount\": ")
  sb.write_view(reasons.length().to_string())
  sb.write_view(",\n")
  sb.write_view("  \"reasons\": [\n")
  let mut first = true
  for reason in reasons {
    if !first {
      sb.write_view(",\n")
    }
    first = false
    sb.write_view(reason_json_string_output(reason))
  }
  sb.write_char('\n')
  sb.write_view("  ]\n")
  sb.write_char('}')
  sb.to_string()
}
