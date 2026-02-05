///|
/// v3.9 timeline event detail HTML projection with paging.

fn timeline_kind_label_v3_9(kind : @timeline_v3.TimelineKind) -> String {
  match kind {
    @timeline_v3.TimelineKind::Transition => "Transition"
    @timeline_v3.TimelineKind::Effect => "Effect"
    @timeline_v3.TimelineKind::Policy => "Policy"
  }
}

fn timeline_reason_nodes_v3_9(reason : @core.Reason) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text(reason.message())]))
  for pair in reason.context() {
    if pair.0 == "hint" {
      nodes.push(@tmpx.p([], [@tmpx.text(pair.1)]))
    }
  }
  nodes
}

fn event_detail_node_v3_9(event : @timeline_v3.TimelineEvent) -> @tmpx.Node {
  let kind_text = timeline_kind_label_v3_9(event.kind)
  let children : Array[@tmpx.Node] = []
  children.push(@tmpx.p([], [@tmpx.text("kind: " + kind_text)]))
  children.push(@tmpx.p([], [@tmpx.text("ref: " + event.ref_id)]))
  children.push(@tmpx.p([], [@tmpx.text("status: " + event.status)]))
  for reason in event.reasons {
    for node in timeline_reason_nodes_v3_9(reason) {
      children.push(node)
    }
  }
  @tmpx.div([
    @tmpx.class_("fwd-timeline-event"),
    @tmpx.data_attr("event-id", @timeline_event_v3_4.event_id(event)),
    @tmpx.data_attr("logical-time", event.logical_time.to_string()),
    @tmpx.data_attr("sequence", event.sequence.to_string()),
    @tmpx.data_attr("kind", kind_text),
  ], children)
}

fn pager_button(label : String, event_id : String) -> @tmpx.Node {
  @tmpx.button([
    @tmpx.mx_get("/v3.9/timeline/event/" + event_id + "?format=html"),
    @tmpx.mx_target(".fwd-timeline-event"),
    @tmpx.mx_swap(@tmpx.MxSwap::OuterHTML),
  ], [@tmpx.text(label)])
}

///|
pub fn render_timeline_event_page_v3_9(page : @timeline_event_v3_9.TimelineEventPage) -> String {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(event_detail_node_v3_9(page.detail.event))
  let pager : Array[@tmpx.Node] = []
  match page.prev_event_id {
    Some(value) => pager.push(pager_button("Prev", value))
    None => ()
  }
  match page.next_event_id {
    Some(value) => pager.push(pager_button("Next", value))
    None => ()
  }
  if pager.length() > 0 {
    nodes.push(@tmpx.div([
      @tmpx.class_("fwd-timeline-pager"),
    ], pager))
  }
  let root = @tmpx.div([
    @tmpx.class_("fwd-timeline-page"),
  ], nodes)
  @tmpx.render(root)
}
