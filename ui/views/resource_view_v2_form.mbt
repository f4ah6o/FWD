///|
/// v2 form HTML projection (M10): render transition forms from IR.

///|
pub(all) struct FormTransition {
  id : String
  to : String
  input_schema : String?
}

///|
fn reason_nodes_form(reason : @core.Reason) -> Array[@tmpx.Node] {
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
fn transition_form_node(
  state : String,
  transition : FormTransition,
) -> @tmpx.Node {
  let children : Array[@tmpx.Node] = []
  children.push(@tmpx.input_([
    @tmpx.type_("hidden"),
    @tmpx.name_("state"),
    @tmpx.value_(state),
  ]))
  children.push(@tmpx.input_([
    @tmpx.type_("hidden"),
    @tmpx.name_("transition"),
    @tmpx.value_(transition.id),
  ]))
  match transition.input_schema {
    Some(schema_name) => {
      children.push(@tmpx.p([], [@tmpx.text("inputSchema: " + schema_name)]))
      children.push(@tmpx.textarea([
        @tmpx.name_("payload"),
      ], []))
    }
    None => ()
  }
  children.push(@tmpx.button([], [@tmpx.text("Validate")]))
  @tmpx.form([
    @tmpx.data_attr("transition", transition.id),
    @tmpx.mx_post("/v2/resource/validate"),
    @tmpx.mx_target(".fwd-resource"),
    @tmpx.mx_swap(@tmpx.MxSwap::OuterHTML),
    @tmpx.mx_trigger_submit(),
  ], children)
}

///|
fn blocked_reason_node(
  transition_id : String,
  reasons : Array[@core.Reason],
) -> @tmpx.Node {
  let children : Array[@tmpx.Node] = []
  for reason in reasons {
    for node in reason_nodes_form(reason) {
      children.push(node)
    }
  }
  @tmpx.div([
    @tmpx.data_attr("transition", transition_id),
  ], children)
}

///|
pub fn render_resource_html_v2_form(
  state : String,
  transitions : Array[FormTransition],
  blocked : Map[String, Array[@core.Reason]],
) -> String {
  let available_nodes : Array[@tmpx.Node] = []
  for tr in transitions {
    available_nodes.push(transition_form_node(state, tr))
  }
  let blocked_nodes : Array[@tmpx.Node] = []
  for entry in blocked.to_array() {
    blocked_nodes.push(blocked_reason_node(entry.0, entry.1))
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

///|
pub fn render_validation_result_html(
  state : String,
  transition_id : String,
  payload_json : String,
) -> String {
  let exec_vals =
    "{\"state\":\"" + state + "\",\"transition\":\"" +
    transition_id + "\",\"input\":" + payload_json + "}"
  let root = @tmpx.div(
    [@tmpx.class_("fwd-resource")],
    [
      @tmpx.section([
        @tmpx.data_attr("section", "available"),
      ], [
        @tmpx.button([
          @tmpx.data_attr("transition", transition_id),
          @tmpx.mx_post("/v2/transition/execute"),
          @tmpx.mx_target(".fwd-resource"),
          @tmpx.mx_swap(@tmpx.MxSwap::OuterHTML),
          @tmpx.mx_vals(exec_vals),
          @tmpx.mx_encoding("application/json"),
          @tmpx.mx_trigger_click(),
        ], [@tmpx.text("Execute")]),
      ]),
      @tmpx.section([
        @tmpx.data_attr("section", "blocked"),
      ], []),
    ],
  )
  @tmpx.render(root)
}
