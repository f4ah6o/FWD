///|
/// Timeline job execution helpers (v4.7).

fn apply_time_filter(
  events : Array[@timeline_v3.TimelineEvent],
  from_time : Int?,
  to_time : Int?,
) -> Array[@timeline_v3.TimelineEvent] {
  let filtered : Array[@timeline_v3.TimelineEvent] = []
  for event in events {
    let ok_from = match from_time {
      Some(value) => event.logical_time >= value
      None => true
    }
    let ok_to = match to_time {
      Some(value) => event.logical_time <= value
      None => true
    }
    if ok_from && ok_to {
      filtered.push(event)
    }
  }
  filtered
}

fn cursor_offset(value : String?) -> Int {
  match value {
    Some(cursor) => match @timeline_event_v3_8.decode_cursor(cursor) {
      Some(v) => v
      None => 0
    }
    None => 0
  }
}

fn build_next_cursor(
  input : @export_job_v4_7.TimelineJobInput,
  offset : Int,
) -> String? {
  Some(@timeline_event_v3_8.encode_cursor(@timeline_event_v3_8.cursor_from_query({
    entity_id: input.entity_id,
    kind: None,
    from_logical_time: input.from_logical_time,
    to_logical_time: input.to_logical_time,
    limit: input.limit,
    cursor: None,
  }, offset)))
}

///|
pub fn export_page(
  input : @export_job_v4_7.TimelineJobInput,
) -> (String, String?) {
  let events = @timeline_source_v4_5.events_for_entity(input.entity_id)
  let filtered = apply_time_filter(events, input.from_logical_time, input.to_logical_time)
  let offset = cursor_offset(input.cursor)
  let page : Array[@timeline_v3.TimelineEvent] = []
  let mut idx = 0
  for event in filtered {
    if idx >= offset && page.length() < input.limit {
      page.push(event)
    }
    idx = idx + 1
  }
  let next_cursor = if offset + input.limit < filtered.length() {
    build_next_cursor(input, offset + input.limit)
  } else {
    None
  }
  (@timeline_export_v4_5.export_jsonl(page), next_cursor)
}
