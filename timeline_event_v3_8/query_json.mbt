///|
/// JSON projection for timeline event list query/cursor (v3.8).

fn option_number(value : Int?) -> Json {
  match value {
    Some(v) => Json::number(v.to_double())
    None => Json::null()
  }
}

fn option_string(value : String?) -> Json {
  match value {
    Some(v) => Json::string(v)
    None => Json::null()
  }
}

///|
pub fn cursor_from_query(query : TimelineEventQuery, offset : Int) -> TimelineEventCursor {
  {
    entity_id: query.entity_id,
    offset,
    limit: query.limit,
    kind: query.kind,
    from_logical_time: query.from_logical_time,
    to_logical_time: query.to_logical_time,
  }
}

///|
pub fn cursor_json(cursor : TimelineEventCursor) -> Json {
  let obj : Map[String, Json] = Map::new()
  obj["entityId"] = Json::string(cursor.entity_id)
  obj["offset"] = Json::number(cursor.offset.to_double())
  obj["limit"] = Json::number(cursor.limit.to_double())
  obj["kind"] = option_string(cursor.kind)
  obj["fromLogicalTime"] = option_number(cursor.from_logical_time)
  obj["toLogicalTime"] = option_number(cursor.to_logical_time)
  Json::object(obj)
}

fn parse_uint_from(value : String, start : Int) -> Int? {
  if start >= value.length() {
    return None
  }
  let mut acc = 0
  for i in start..<value.length() {
    let ch = value[i].to_int()
    if ch < 48 || ch > 57 {
      return None
    }
    acc = acc * 10 + (ch - 48)
  }
  Some(acc)
}

///|
pub fn encode_cursor(cursor : TimelineEventCursor) -> String {
  "offset:" + cursor.offset.to_string()
}

///|
pub fn decode_cursor(value : String) -> Int? {
  if value.has_prefix("offset:") {
    parse_uint_from(value, 7)
  } else {
    None
  }
}
