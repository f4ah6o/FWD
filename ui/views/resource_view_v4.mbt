///|
/// v4 resource HTML projection (canonical JSON projection).

pub(all) struct V4ReasonView {
  message : String
  hint : String?
}

pub(all) struct V4FieldErrorView {
  path : String
  reason : V4ReasonView
}

pub(all) struct V4EntityView {
  id : String
  state : String
  logical_time : Int
}

pub(all) struct V4PolicyView {
  decision : String
  reasons : Array[V4ReasonView]
}

pub(all) struct V4EffectsView {
  plan_status : String
  execution_status : String
  reasons : Array[V4ReasonView]
}

pub(all) struct V4TimelineEventView {
  event_id : String
  kind : String
  ref_id : String
  status : String
  reasons : Array[V4ReasonView]
}

pub(all) struct V4TimelineView {
  cursor : String
  events : Array[V4TimelineEventView]
}

pub(all) struct V4ResourceView {
  entity : V4EntityView
  draft_reason : String
  field_errors : Array[V4FieldErrorView]
  policy : V4PolicyView
  effects : V4EffectsView
  timeline : V4TimelineView
}

fn reason_nodes_v4(reason : V4ReasonView) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text(reason.message)]))
  match reason.hint {
    Some(value) => nodes.push(@tmpx.p([], [@tmpx.text(value)]))
    None => ()
  }
  nodes
}

fn field_error_node_v4(error : V4FieldErrorView) -> @tmpx.Node {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("path: " + error.path)]))
  for node in reason_nodes_v4(error.reason) {
    nodes.push(node)
  }
  @tmpx.div([
    @tmpx.class_("fwd-field-error"),
    @tmpx.data_attr("path", error.path),
  ], nodes)
}

fn policy_node_v4(policy : V4PolicyView) -> @tmpx.Node {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("decision: " + policy.decision)]))
  for reason in policy.reasons {
    for node in reason_nodes_v4(reason) {
      nodes.push(node)
    }
  }
  @tmpx.div([
    @tmpx.class_("fwd-policy"),
  ], nodes)
}

fn effects_node_v4(effects : V4EffectsView) -> @tmpx.Node {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("plan.status: " + effects.plan_status)]))
  nodes.push(@tmpx.p([], [@tmpx.text("execution.status: " + effects.execution_status)]))
  for reason in effects.reasons {
    for node in reason_nodes_v4(reason) {
      nodes.push(node)
    }
  }
  @tmpx.div([
    @tmpx.class_("fwd-effects"),
  ], nodes)
}

fn resource_timeline_event_node_v4(event : V4TimelineEventView) -> @tmpx.Node {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("kind: " + event.kind)]))
  nodes.push(@tmpx.p([], [@tmpx.text("ref: " + event.ref_id)]))
  nodes.push(@tmpx.p([], [@tmpx.text("status: " + event.status)]))
  for reason in event.reasons {
    for node in reason_nodes_v4(reason) {
      nodes.push(node)
    }
  }
  @tmpx.div([
    @tmpx.class_("fwd-timeline-event"),
    @tmpx.data_attr("event-id", event.event_id),
  ], nodes)
}

fn timeline_node_v4(timeline : V4TimelineView) -> @tmpx.Node {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("cursor: " + timeline.cursor)]))
  for event in timeline.events {
    nodes.push(resource_timeline_event_node_v4(event))
  }
  @tmpx.div([
    @tmpx.class_("fwd-timeline"),
  ], nodes)
}

fn resource_nodes_v4(view : V4ResourceView) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.div([
    @tmpx.class_("fwd-entity"),
  ], [
    @tmpx.p([], [@tmpx.text("id: " + view.entity.id)]),
    @tmpx.p([], [@tmpx.text("state: " + view.entity.state)]),
    @tmpx.p([], [@tmpx.text("logicalTime: " + view.entity.logical_time.to_string())]),
  ]))
  nodes.push(@tmpx.div([
    @tmpx.class_("fwd-input"),
  ], [
    @tmpx.p([], [@tmpx.text("draft.reason: " + view.draft_reason)]),
  ]))
  for error in view.field_errors {
    nodes.push(field_error_node_v4(error))
  }
  nodes.push(policy_node_v4(view.policy))
  nodes.push(effects_node_v4(view.effects))
  nodes.push(timeline_node_v4(view.timeline))
  nodes
}

///|
pub fn render_resource_html_v4(view : V4ResourceView) -> String {
  let nodes = resource_nodes_v4(view)
  let root = @tmpx.div([
    @tmpx.class_("fwd-resource"),
  ], nodes)
  @tmpx.render(root)
}

///|
pub fn render_resource_html_v4_mx(view : V4ResourceView) -> String {
  let root = @tmpx.div([
    @tmpx.class_("fwd-resource"),
    @tmpx.mx_target(".fwd-resource"),
    @tmpx.mx_swap(@tmpx.MxSwap::OuterHTML),
  ], resource_nodes_v4(view))
  @tmpx.render(root)
}
