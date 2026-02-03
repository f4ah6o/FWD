///|
/// tmpx HTML projection for Hypermedia Resource with mx-* attributes (v1).

///|
fn find_context_value_mx(reason : @core.Reason, key : String) -> String? {
  for pair in reason.context() {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
fn reason_nodes_mx(reason : @core.Reason) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text(reason.message())]))
  match find_context_value_mx(reason, "hint") {
    Some(hint) => nodes.push(@tmpx.p([], [@tmpx.text(hint)]))
    None => ()
  }
  nodes
}

///|
fn transition_action_url(id : String) -> String {
  "/hypermedia/transition/" + id
}

///|
fn resource_target_selector() -> String {
  ".fwd-resource"
}

///|
fn blocked_transition_node_mx(
  blocked : @hypermedia.ResourceBlockedTransition,
) -> @tmpx.Node {
  let children : Array[@tmpx.Node] = []
  for reason in blocked.reasons {
    for node in reason_nodes_mx(reason) {
      children.push(node)
    }
  }
  @tmpx.div([
    @tmpx.data_attr("transition", blocked.id),
  ], children)
}

///|
fn available_transition_node_mx(
  available : @hypermedia.ResourceTransition,
) -> @tmpx.Node {
  @tmpx.button(
    [
      @tmpx.data_attr("transition", available.id),
      @tmpx.mx_post(transition_action_url(available.id)),
      @tmpx.mx_target(resource_target_selector()),
      @tmpx.mx_swap(@tmpx.MxSwap::OuterHTML),
      @tmpx.mx_trigger_click(),
    ],
    [@tmpx.text(available.to)],
  )
}

///|
pub fn render_resource_html_mx(resource : @hypermedia.Resource) -> String {
  let available_nodes : Array[@tmpx.Node] = []
  for tr in resource.available_transitions {
    available_nodes.push(available_transition_node_mx(tr))
  }
  let blocked_nodes : Array[@tmpx.Node] = []
  for tr in resource.blocked_transitions {
    blocked_nodes.push(blocked_transition_node_mx(tr))
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
