///|
/// Record/replay cassette format (v2.2).

///|
pub(all) struct CassetteRequest {
  http_method : String
  url : String
  headers : Map[String, String]
  body : String
}

///|
pub(all) struct CassetteResponse {
  status : Int
  headers : Map[String, String]
  body : String
}

///|
pub(all) struct CassetteEntry {
  request : CassetteRequest
  response : CassetteResponse
}

///|
pub(all) struct Cassette {
  cassette_version : String
  entries : Array[CassetteEntry]
}

///|
fn compare_string(a : String, b : String) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn headers_json(headers : Map[String, String]) -> Json {
  let keys : Array[String] = []
  for entry in headers.to_array() {
    keys.push(entry.0)
  }
  keys.sort_by(compare_string)
  let obj : Map[String, Json] = Map::new()
  for key in keys {
    obj[key] = Json::string(headers[key])
  }
  Json::object(obj)
}

///|
fn request_json(req : CassetteRequest) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["method"] = Json::string(req.http_method)
  obj["url"] = Json::string(req.url)
  obj["headers"] = headers_json(req.headers)
  obj["body"] = Json::string(req.body)
  Json::object(obj)
}

///|
fn response_json(resp : CassetteResponse) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["status"] = Json::number(resp.status.to_double())
  obj["headers"] = headers_json(resp.headers)
  obj["body"] = Json::string(resp.body)
  Json::object(obj)
}

///|
pub fn cassette_json(cassette : Cassette) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["cassetteVersion"] = Json::string(cassette.cassette_version)
  let entries : Array[Json] = []
  for entry in cassette.entries {
    let eobj : Map[String, Json] = Map::new()
    eobj["request"] = request_json(entry.request)
    eobj["response"] = response_json(entry.response)
    entries.push(Json::object(eobj))
  }
  obj["entries"] = Json::array(entries)
  Json::object(obj)
}

///|
fn invalid_cassette_reason(message : String) -> @core.Reason {
  @core.Reason::with_context(
    "INPUT_JSON_INVALID",
    message,
    [
      ("target", "runtime"),
      ("level", "error"),
      ("hint", "Provide a valid cassette JSON"),
    ],
  )
}

///|
fn extract_string(obj : Map[String, Json], name : String) -> Result[String, @core.Reason] {
  match obj.get(name) {
    Some(String(value)) => Ok(value)
    Some(_) => Err(invalid_cassette_reason("field must be string: " + name))
    None => Err(invalid_cassette_reason("missing field: " + name))
  }
}

///|
fn extract_headers(obj : Map[String, Json], name : String) -> Result[Map[String, String], @core.Reason] {
  match obj.get(name) {
    None => Ok(Map::new())
    Some(Object(m)) => {
      let headers : Map[String, String] = Map::new()
      for entry in m.to_array() {
        match entry.1 {
          String(value) => headers[entry.0] = value
          _ => return Err(invalid_cassette_reason("header must be string: " + entry.0))
        }
      }
      Ok(headers)
    }
    Some(_) => Err(invalid_cassette_reason("headers must be object"))
  }
}

///|
fn parse_request(obj : Map[String, Json]) -> Result[CassetteRequest, @core.Reason] {
  let http_method = match extract_string(obj, "method") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let url = match extract_string(obj, "url") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let headers = match extract_headers(obj, "headers") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let body = match extract_string(obj, "body") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok({ http_method, url, headers, body })
}

///|
fn parse_response(obj : Map[String, Json]) -> Result[CassetteResponse, @core.Reason] {
  let status = match obj.get("status") {
    Some(Number(value, ..)) => value.to_int()
    Some(_) => return Err(invalid_cassette_reason("status must be number"))
    None => return Err(invalid_cassette_reason("missing field: status"))
  }
  let headers = match extract_headers(obj, "headers") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let body = match extract_string(obj, "body") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok({ status, headers, body })
}

///|
pub fn parse_cassette_json(input_json : String) -> Result[Cassette, @core.Reason] {
  let parsed : Result[Json, @json.ParseError] = try? @json.parse(input_json)
  let value = match parsed {
    Ok(v) => v
    Err(err) =>
      return Err(invalid_cassette_reason("input json parse error: " + err.to_string()))
  }
  let obj = match value {
    Object(m) => m
    _ => return Err(invalid_cassette_reason("input json must be an object"))
  }
  let cassette_version = match extract_string(obj, "cassetteVersion") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let entries_value = match obj.get("entries") {
    Some(Array(values)) => values
    Some(_) => return Err(invalid_cassette_reason("entries must be array"))
    None => return Err(invalid_cassette_reason("missing field: entries"))
  }
  let entries : Array[CassetteEntry] = []
  for value in entries_value {
    match value {
      Object(m) => {
        let req_obj = match m.get("request") {
          Some(Object(v)) => v
          Some(_) => return Err(invalid_cassette_reason("request must be object"))
          None => return Err(invalid_cassette_reason("missing field: request"))
        }
        let resp_obj = match m.get("response") {
          Some(Object(v)) => v
          Some(_) => return Err(invalid_cassette_reason("response must be object"))
          None => return Err(invalid_cassette_reason("missing field: response"))
        }
        let request = match parse_request(req_obj) {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
        let response = match parse_response(resp_obj) {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
        entries.push({ request, response })
      }
      _ => return Err(invalid_cassette_reason("entry must be object"))
    }
  }
  Ok({ cassette_version, entries })
}
