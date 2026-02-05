///|
/// v4 timeline list HTML projection (canonical JSON projection).

pub(all) struct V4TimelineEvent {
  event_id : String
  kind : String
  ref_id : String
  status : String
  reasons : Array[String]
}

pub(all) struct V4TimelineListView {
  cursor : String
  next_cursor : String?
  events : Array[V4TimelineEvent]
}

fn timeline_list_event_node_v4(event : V4TimelineEvent) -> @tmpx.Node {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("kind: " + event.kind)]))
  nodes.push(@tmpx.p([], [@tmpx.text("ref: " + event.ref_id)]))
  nodes.push(@tmpx.p([], [@tmpx.text("status: " + event.status)]))
  for message in event.reasons {
    nodes.push(@tmpx.p([], [@tmpx.text(message)]))
  }
  @tmpx.div([
    @tmpx.class_("fwd-timeline-event"),
    @tmpx.data_attr("event-id", event.event_id),
  ], nodes)
}

///|
pub fn render_timeline_list_html_v4(view : V4TimelineListView) -> String {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("cursor: " + view.cursor)]))
  match view.next_cursor {
    Some(value) => nodes.push(@tmpx.p([], [@tmpx.text("nextCursor: " + value)]))
    None => ()
  }
  for event in view.events {
    nodes.push(timeline_list_event_node_v4(event))
  }
  let root = @tmpx.div([
    @tmpx.class_("fwd-timeline"),
  ], nodes)
  @tmpx.render(root)
}

///|
pub fn render_timeline_list_html_v4_mx(view : V4TimelineListView) -> String {
  let root_nodes : Array[@tmpx.Node] = []
  root_nodes.push(@tmpx.p([], [@tmpx.text("cursor: " + view.cursor)]))
  match view.next_cursor {
    Some(value) => root_nodes.push(@tmpx.p([], [@tmpx.text("nextCursor: " + value)]))
    None => ()
  }
  for event in view.events {
    root_nodes.push(timeline_list_event_node_v4(event))
  }
  let root = @tmpx.div([
    @tmpx.class_("fwd-timeline"),
    @tmpx.mx_target(".fwd-timeline"),
    @tmpx.mx_swap(@tmpx.MxSwap::OuterHTML),
  ], root_nodes)
  @tmpx.render(root)
}
