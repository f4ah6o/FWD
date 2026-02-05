///|
/// v3.4 timeline HTML projection with mx drilldown wiring.

fn timeline_kind_label_v3_4_mx(kind : @timeline_v3.TimelineKind) -> String {
  match kind {
    @timeline_v3.TimelineKind::Transition => "Transition"
    @timeline_v3.TimelineKind::Effect => "Effect"
    @timeline_v3.TimelineKind::Policy => "Policy"
  }
}

fn event_row_v3_4_mx(event : @timeline_v3.TimelineEvent) -> @tmpx.Node {
  let kind_text = timeline_kind_label_v3_4_mx(event.kind)
  let event_id = @timeline_event_v3_4.event_id(event)
  let children : Array[@tmpx.Node] = []
  children.push(@tmpx.p([], [@tmpx.text("kind: " + kind_text)]))
  children.push(@tmpx.p([], [@tmpx.text("ref: " + event.ref_id)]))
  children.push(@tmpx.p([], [@tmpx.text("status: " + event.status)]))
  let button = @tmpx.button([
    @tmpx.mx_get("/v3.4/timeline/event/" + event_id + "?format=html"),
    @tmpx.mx_target(".fwd-timeline-detail-" + event_id),
    @tmpx.mx_swap(@tmpx.MxSwap::OuterHTML),
  ], [@tmpx.text("Details")])
  children.push(button)
  children.push(@tmpx.div([
    @tmpx.class_("fwd-timeline-detail-" + event_id),
  ], []))
  @tmpx.div([
    @tmpx.class_("fwd-timeline-entry"),
    @tmpx.data_attr("event-id", event_id),
  ], children)
}

///|
pub fn render_timeline_html_v3_4_mx(
  entity_id : String,
  events : Array[@timeline_v3.TimelineEvent],
) -> String {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("entity: " + entity_id)]))
  for event in events {
    nodes.push(event_row_v3_4_mx(event))
  }
  let root = @tmpx.div([
    @tmpx.class_("fwd-timeline"),
  ], nodes)
  @tmpx.render(root)
}
