///|
/// v2.1 history HTML projection.

///|
fn reason_nodes_history(reason : @core.Reason) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text(reason.message())]))
  for pair in reason.context() {
    if pair.0 == "hint" {
      nodes.push(@tmpx.p([], [@tmpx.text(pair.1)]))
    }
  }
  nodes
}

///|
fn history_event_node(event : @history_v2_1.HistoryEvent) -> @tmpx.Node {
  let result_text = match event.result {
    @history_v2_1.HistoryResult::Executed => "executed"
    @history_v2_1.HistoryResult::Blocked => "blocked"
    @history_v2_1.HistoryResult::NotFound => "not_found"
    @history_v2_1.HistoryResult::NotAvailable => "not_available"
  }
  let header = @tmpx.p([], [
    @tmpx.text("#" + event.event_id.to_string() + " " + event.transition + " " +
      event.from_state + "->" + event.to_state + " " + result_text)
  ])
  let payload_node = @tmpx.pre([], [@tmpx.text(event.payload.stringify(indent=2))])
  let reasons_nodes : Array[@tmpx.Node] = []
  for reason in event.reasons {
    for node in reason_nodes_history(reason) {
      reasons_nodes.push(node)
    }
  }
  @tmpx.div([
    @tmpx.data_attr("event", event.event_id.to_string()),
  ], [header, payload_node, @tmpx.div([], reasons_nodes)])
}

///|
pub fn render_history_html(events : Array[@history_v2_1.HistoryEvent]) -> String {
  let nodes : Array[@tmpx.Node] = []
  for event in events {
    nodes.push(history_event_node(event))
  }
  let root = @tmpx.div([
    @tmpx.class_("fwd-history"),
  ], nodes)
  @tmpx.render(root)
}
