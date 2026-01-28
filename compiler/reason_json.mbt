///|
fn reason_json_string(value : String) -> Json {
  Json::string(value)
}

///|
fn context_json(context : Array[(String, String)]) -> Json {
  let obj : Map[String, Json] = Map::new()
  for pair in context {
    obj[pair.0] = reason_json_string(pair.1)
  }
  Json::object(obj)
}

///|
fn reason_json(reason : @core.Reason) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["code"] = reason_json_string(reason.code())
  obj["message"] = reason_json_string(reason.message())
  obj["context"] = context_json(reason.context())
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
