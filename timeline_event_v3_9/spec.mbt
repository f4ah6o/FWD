///|
/// Timeline event paging contract (v3.9).

///|
pub(all) struct TimelineEventPage {
  detail : @timeline_event_v3_4.TimelineEventDetail
  prev_event_id : String?
  next_event_id : String?
}
