///|
/// JSON projection for Hypermedia Resource (v1).

///|
fn reason_json(reason : @core.Reason) -> Json {
  @compiler.reason_json(reason)
}

///|
pub fn resource_json(resource : Resource) -> Json {
  let obj : Map[String, Json] = Map::new()
  let available : Array[Json] = []
  for tr in resource.available_transitions {
    let tr_obj : Map[String, Json] = Map::new()
    tr_obj["id"] = Json::string(tr.id)
    tr_obj["to"] = Json::string(tr.to)
    available.push(Json::object(tr_obj))
  }
  let blocked : Array[Json] = []
  for tr in resource.blocked_transitions {
    let tr_obj : Map[String, Json] = Map::new()
    tr_obj["id"] = Json::string(tr.id)
    let reasons : Array[Json] = []
    for reason in tr.reasons {
      reasons.push(reason_json(reason))
    }
    tr_obj["reasons"] = Json::array(reasons)
    blocked.push(Json::object(tr_obj))
  }
  obj["availableTransitions"] = Json::array(available)
  obj["blockedTransitions"] = Json::array(blocked)
  Json::object(obj)
}
