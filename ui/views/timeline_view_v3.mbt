///|
/// v3 timeline HTML projection.

fn timeline_reason_nodes(reason : @core.Reason) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text(reason.message())]))
  for pair in reason.context() {
    if pair.0 == "hint" {
      nodes.push(@tmpx.p([], [@tmpx.text(pair.1)]))
    }
  }
  nodes
}

fn event_node_v3(event : @timeline_v3.TimelineEvent) -> @tmpx.Node {
  let children : Array[@tmpx.Node] = []
  let kind_text = match event.kind {
    @timeline_v3.TimelineKind::Transition => "Transition"
    @timeline_v3.TimelineKind::Effect => "Effect"
    @timeline_v3.TimelineKind::Policy => "Policy"
  }
  children.push(@tmpx.p([], [@tmpx.text("kind: " + kind_text)]))
  children.push(@tmpx.p([], [@tmpx.text("ref: " + event.ref_id)]))
  children.push(@tmpx.p([], [@tmpx.text("status: " + event.status)]))
  for reason in event.reasons {
    for node in timeline_reason_nodes(reason) {
      children.push(node)
    }
  }
  @tmpx.div([
    @tmpx.data_attr("logical-time", event.logical_time.to_string()),
    @tmpx.data_attr("sequence", event.sequence.to_string()),
    @tmpx.data_attr("kind", kind_text),
  ], children)
}

///|
pub fn render_timeline_html_v3(events : Array[@timeline_v3.TimelineEvent]) -> String {
  let nodes : Array[@tmpx.Node] = []
  for event in events {
    nodes.push(event_node_v3(event))
  }
  let root = @tmpx.div(
    [@tmpx.class_("fwd-timeline")],
    nodes,
  )
  @tmpx.render(root)
}
