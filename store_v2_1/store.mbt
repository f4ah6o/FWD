///|
/// In-memory snapshot store (v2.1).

///|
pub(all) struct Snapshot {
  entity_id : String
  state : String
  payload : Json?
  version : Int
}

///|
pub fn Snapshot::new(
  entity_id : String,
  state : String,
  payload : Json?,
  version : Int,
) -> Snapshot {
  { entity_id, state, payload, version }
}

///|
pub(all) struct Store {
  mut snapshots : Map[String, Snapshot]
}

///|
pub fn Store::new() -> Store {
  { snapshots: Map::new() }
}

///|
pub fn Store::save(self : Store, snapshot : Snapshot) -> Unit {
  self.snapshots[snapshot.entity_id] = snapshot
}

///|
pub fn Store::get(self : Store, entity_id : String) -> Snapshot? {
  self.snapshots.get(entity_id)
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
pub fn Store::list_ids(self : Store) -> Array[String] {
  let ids : Array[String] = []
  for entry in self.snapshots.to_array() {
    ids.push(entry.0)
  }
  ids.sort_by(compare_string)
  ids
}

///|
pub fn snapshot_json(snapshot : Snapshot) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["entityId"] = Json::string(snapshot.entity_id)
  obj["state"] = Json::string(snapshot.state)
  obj["version"] = Json::number(snapshot.version.to_double())
  match snapshot.payload {
    Some(value) => obj["payload"] = value
    None => ()
  }
  Json::object(obj)
}

///|
pub fn snapshot_list_json(ids : Array[String]) -> Json {
  let arr : Array[Json] = []
  for id in ids {
    arr.push(Json::string(id))
  }
  let obj : Map[String, Json] = Map::new()
  obj["entityIds"] = Json::array(arr)
  Json::object(obj)
}
