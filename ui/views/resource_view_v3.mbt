///|
/// v3 HTML projection from ResourceV3.

///|
fn reason_nodes_v3(reason : @core.Reason) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text(reason.message())]))
  for pair in reason.context() {
    if pair.0 == "hint" {
      nodes.push(@tmpx.p([], [@tmpx.text(pair.1)]))
    }
  }
  nodes
}

fn policy_label(policy : @policy_v3.PolicyDecision?) -> String {
  match policy {
    Some(value) => {
      match value.decision {
        @policy_v3.PolicyDecisionKind::Allow => "allow"
        @policy_v3.PolicyDecisionKind::Deny => "deny"
      }
    }
    None => "none"
  }
}

fn json_text(value : Json?) -> String {
  match value {
    Some(v) => v.stringify()
    None => Json::null().stringify()
  }
}

fn effects_text(plan : @effects_v2_2.EffectsPlan?) -> String {
  match plan {
    Some(p) => @effects_v2_2.effect_plan_json(p).stringify()
    None => Json::null().stringify()
  }
}

///|
fn transition_node_v3(tr : @hypermedia.ResourceTransitionV3) -> @tmpx.Node {
  let children : Array[@tmpx.Node] = []
  children.push(@tmpx.p([], [@tmpx.text("transition: " + tr.id + " -> " + tr.to)]))
  match tr.input_schema {
    Some(schema_name) => {
      children.push(@tmpx.p([], [@tmpx.text("inputSchema: " + schema_name)]))
    }
    None => ()
  }
  children.push(@tmpx.pre([
    @tmpx.data_attr("field", "draftPayload"),
  ], [@tmpx.text(json_text(tr.draft_payload))]))
  children.push(@tmpx.p([
    @tmpx.data_attr("field", "policyDecision"),
  ], [@tmpx.text("policy: " + policy_label(tr.policy_decision))]))
  match tr.policy_decision {
    Some(policy) => {
      for reason in policy.reasons {
        for node in reason_nodes_v3(reason) {
          children.push(node)
        }
      }
    }
    None => ()
  }
  children.push(@tmpx.pre([
    @tmpx.data_attr("field", "effectsPreview"),
  ], [@tmpx.text(effects_text(tr.effects_preview))]))
  children.push(@tmpx.p([
    @tmpx.data_attr("field", "canExecute"),
  ], [@tmpx.text("canExecute: " + tr.can_execute.to_string())]))
  @tmpx.div([
    @tmpx.data_attr("transition", tr.id),
  ], children)
}

///|
pub fn render_resource_html_v3(resource : @hypermedia.ResourceV3) -> String {
  let nodes : Array[@tmpx.Node] = []
  for tr in resource.transitions {
    nodes.push(transition_node_v3(tr))
  }
  let root = @tmpx.div(
    [@tmpx.class_("fwd-resource")],
    [
      @tmpx.section([
        @tmpx.data_attr("section", "available"),
      ], nodes),
      @tmpx.section([
        @tmpx.data_attr("section", "blocked"),
      ], []),
    ],
  )
  @tmpx.render(root)
}

///|
pub fn render_resource_html_v3_mx(resource : @hypermedia.ResourceV3) -> String {
  render_resource_html_v3(resource)
}
