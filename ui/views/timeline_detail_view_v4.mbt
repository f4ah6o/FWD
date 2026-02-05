///|
/// v4 timeline detail HTML projection (canonical JSON projection).

pub(all) struct V4TimelineDetailView {
  event_id : String
  kind : String
  ref_id : String
  status : String
  reasons : Array[String]
  prev_event_id : String?
  next_event_id : String?
}

fn detail_event_node_v4(view : V4TimelineDetailView) -> @tmpx.Node {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("kind: " + view.kind)]))
  nodes.push(@tmpx.p([], [@tmpx.text("ref: " + view.ref_id)]))
  nodes.push(@tmpx.p([], [@tmpx.text("status: " + view.status)]))
  for message in view.reasons {
    nodes.push(@tmpx.p([], [@tmpx.text(message)]))
  }
  @tmpx.div([
    @tmpx.class_("fwd-timeline-event"),
    @tmpx.data_attr("event-id", view.event_id),
  ], nodes)
}

fn pager_node_v4(label : String, event_id : String) -> @tmpx.Node {
  @tmpx.button([
    @tmpx.mx_get("/v4/timeline/event/" + event_id + "?format=html"),
    @tmpx.mx_target(".fwd-timeline-event"),
    @tmpx.mx_swap(@tmpx.MxSwap::OuterHTML),
  ], [@tmpx.text(label)])
}

fn detail_nodes_v4(view : V4TimelineDetailView) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(detail_event_node_v4(view))
  let pager : Array[@tmpx.Node] = []
  match view.prev_event_id {
    Some(value) => pager.push(pager_node_v4("Prev", value))
    None => ()
  }
  match view.next_event_id {
    Some(value) => pager.push(pager_node_v4("Next", value))
    None => ()
  }
  if pager.length() > 0 {
    nodes.push(@tmpx.div([
      @tmpx.class_("fwd-timeline-pager"),
    ], pager))
  }
  nodes
}

///|
pub fn render_timeline_detail_html_v4(view : V4TimelineDetailView) -> String {
  let nodes = detail_nodes_v4(view)
  let root = @tmpx.div([
    @tmpx.class_("fwd-timeline-detail"),
  ], nodes)
  @tmpx.render(root)
}

///|
pub fn render_timeline_detail_html_v4_mx(view : V4TimelineDetailView) -> String {
  let root = @tmpx.div([
    @tmpx.class_("fwd-timeline-detail"),
    @tmpx.mx_target(".fwd-timeline-detail"),
    @tmpx.mx_swap(@tmpx.MxSwap::OuterHTML),
  ], detail_nodes_v4(view))
  @tmpx.render(root)
}
