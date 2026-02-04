///|
fn read_text_store(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn make_payload(amount : Int) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["amount"] = Json::number(amount.to_double())
  Json::object(obj)
}

///|
test "snapshot store fixture" {
  let expected = match read_text_store(
    "examples/store_v2_1/expected_snapshot.json",
    "expected snapshot",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let store = Store::new()
  let snapshot = Snapshot::new(
    "order-1",
    "Draft",
    Some(make_payload(10)),
    1,
  )
  store.save(snapshot)
  let loaded = match store.get("order-1") {
    Some(value) => value
    None => fail("snapshot missing")
  }
  let mut output = snapshot_json(loaded).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "snapshot store list fixture" {
  let expected = match read_text_store(
    "examples/store_v2_1/expected_list.json",
    "expected list",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let store = Store::new()
  store.save(Snapshot::new("order-2", "Approved", None, 2))
  store.save(Snapshot::new("order-1", "Draft", None, 1))
  let ids = store.list_ids()
  let mut output = snapshot_list_json(ids).stringify(indent=2)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
