///|
/// Timeline event list contract (v3.8).

///|
pub(all) struct TimelineEventQuery {
  entity_id : String
  kind : String?
  from_logical_time : Int?
  to_logical_time : Int?
  limit : Int
  cursor : String?
}

///|
pub(all) struct TimelineEventCursor {
  entity_id : String
  offset : Int
  limit : Int
  kind : String?
  from_logical_time : Int?
  to_logical_time : Int?
}
