///|
/// JSON projection for timeline event paging (v3.9).

fn option_string(value : String?) -> Json {
  match value {
    Some(v) => Json::string(v)
    None => Json::null()
  }
}

fn kind_string(kind : @timeline_v3.TimelineKind) -> String {
  match kind {
    @timeline_v3.TimelineKind::Transition => "transition"
    @timeline_v3.TimelineKind::Effect => "effect"
    @timeline_v3.TimelineKind::Policy => "policy"
  }
}

///|
pub fn page_json(page : TimelineEventPage) -> Json {
  let detail = page.detail
  let event = detail.event
  let obj : Map[String, Json] = Map::new()
  obj["eventId"] = Json::string(detail.event_id)
  obj["entityId"] = Json::string(event.entity_id)
  obj["logicalTime"] = Json::number(event.logical_time.to_double())
  obj["sequence"] = Json::number(event.sequence.to_double())
  obj["kind"] = Json::string(kind_string(event.kind))
  obj["refId"] = Json::string(event.ref_id)
  obj["status"] = Json::string(event.status)
  let reasons : Array[Json] = []
  for reason in event.reasons {
    reasons.push(@compiler.reason_json(reason))
  }
  obj["reasons"] = Json::array(reasons)
  obj["prevEventId"] = option_string(page.prev_event_id)
  obj["nextEventId"] = option_string(page.next_event_id)
  Json::object(obj)
}
