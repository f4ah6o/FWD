///|
/// tmpx HTML projection for Hypermedia Resource (v1).

///|
fn find_context_value(reason : @core.Reason, key : String) -> String? {
  for pair in reason.context() {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
fn reason_nodes(reason : @core.Reason) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text(reason.message())]))
  match find_context_value(reason, "hint") {
    Some(hint) => nodes.push(@tmpx.p([], [@tmpx.text(hint)]))
    None => ()
  }
  nodes
}

///|
fn blocked_transition_node(
  blocked : @hypermedia.ResourceBlockedTransition,
) -> @tmpx.Node {
  let children : Array[@tmpx.Node] = []
  for reason in blocked.reasons {
    for node in reason_nodes(reason) {
      children.push(node)
    }
  }
  @tmpx.div([
    @tmpx.data_attr("transition", blocked.id),
  ], children)
}

///|
fn available_transition_node(
  available : @hypermedia.ResourceTransition,
) -> @tmpx.Node {
  @tmpx.button(
    [@tmpx.data_attr("transition", available.id)],
    [@tmpx.text(available.to)],
  )
}

///|
pub fn render_resource_html(resource : @hypermedia.Resource) -> String {
  let available_nodes : Array[@tmpx.Node] = []
  for tr in resource.available_transitions {
    available_nodes.push(available_transition_node(tr))
  }
  let blocked_nodes : Array[@tmpx.Node] = []
  for tr in resource.blocked_transitions {
    blocked_nodes.push(blocked_transition_node(tr))
  }
  let root = @tmpx.div(
    [@tmpx.class_("fwd-resource")],
    [
      @tmpx.section([
        @tmpx.data_attr("section", "available"),
      ], available_nodes),
      @tmpx.section([
        @tmpx.data_attr("section", "blocked"),
      ], blocked_nodes),
    ],
  )
  @tmpx.render(root)
}
