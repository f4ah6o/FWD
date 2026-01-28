///|
fn rj_json_string(value : String) -> Json {
  Json::string(value)
}

///|
fn context_json(pairs : Array[(String, String)]) -> Json {
  let obj : Map[String, Json] = Map::new()
  for pair in pairs {
    obj[pair.0] = rj_json_string(pair.1)
  }
  Json::object(obj)
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
fn json_context_string(pairs : Array[(String, String)]) -> String {
  let sb = StringBuilder::new()
  sb.write_char('{')
  let mut first = true
  for pair in pairs {
    if !first {
      sb.write_char(',')
    }
    first = false
    sb.write_char('\n')
    sb.write_view("        ")
    sb.write_view(json_string_value(pair.0))
    sb.write_view(": ")
    sb.write_view(json_string_value(pair.1))
  }
  if !first {
    sb.write_char('\n')
    sb.write_view("      ")
  }
  sb.write_char('}')
  sb.to_string()
}

///|
fn reason_json_string_output(reason : @core.Reason) -> String {
  let pairs = reason_context_pairs(reason)
  let sb = StringBuilder::new()
  sb.write_view("    {\n")
  sb.write_view("      \"code\": ")
  sb.write_view(json_string_value(reason.code()))
  sb.write_view(",\n")
  sb.write_view("      \"message\": ")
  sb.write_view(json_string_value(reason.message()))
  sb.write_view(",\n")
  sb.write_view("      \"context\": ")
  sb.write_view(json_context_string(pairs))
  sb.write_char('\n')
  sb.write_view("    }")
  sb.to_string()
}

///|
fn reason_json(reason : @core.Reason) -> Json {
  let pairs = reason_context_pairs(reason)
  let obj : Map[String, Json] = Map::new()
  obj["code"] = rj_json_string(reason.code())
  obj["message"] = rj_json_string(reason.message())
  obj["context"] = context_json(pairs)
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
pub fn validation_json_string(ok : Bool, reasons : Array[@core.Reason]) -> String {
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
