///|
fn build_ir() -> @ir.FwdIR {
  let nodes : Map[@core.StateTag, Unit] = Map::new()
  nodes[@core.StateTag::new("Draft")] = ()
  nodes[@core.StateTag::new("Approved")] = ()
  nodes[@core.StateTag::new("Rejected")] = ()
  let edges : Map[@core.StateTag, Map[@core.StateTag, @ir.TransitionRef]] = Map::new()
  let state_graph : @ir.DirectedGraph[@core.StateTag, @ir.TransitionRef] = {
    nodes,
    edges,
  }
  let transitions : Map[String, @ir.NormalizedTransition] = Map::new()
  transitions["approve"] = {
    name: "approve",
    from: @core.StateTag::new("Draft"),
    to: @core.StateTag::new("Approved"),
    rule_refs: ["canApprove"],
    effect_refs: [],
    input_schema: None,
  }
  transitions["reject"] = {
    name: "reject",
    from: @core.StateTag::new("Draft"),
    to: @core.StateTag::new("Rejected"),
    rule_refs: ["canReject"],
    effect_refs: [],
    input_schema: None,
  }
  {
    version: "1.0",
    fwd_version: "1.0",
    state_graph,
    entities: Map::new(),
    transitions,
    rules: Map::new(),
    reasons: Map::new(),
    effects: Map::new(),
  }
}

///|
fn find_context(reason : @core.Reason, key : String) -> String? {
  for pair in reason.context() {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
test "compute available transitions" {
  let ir = build_ir()
  let rule_results : Map[String, Bool] = Map::new()
  rule_results["canApprove"] = true
  rule_results["canReject"] = false
  match compute_available_transitions(ir, "Draft", rule_results) {
    Ok(result) => {
      inspect(result.available_transitions.length(), content="1")
      inspect(result.available_transitions[0].id, content="approve")
      inspect(result.blocked_transitions.length(), content="1")
      inspect(result.blocked_transitions[0].id, content="reject")
      let reasons = result.blocked_transitions[0].reasons
      inspect(reasons.length(), content="1")
      inspect(reasons[0].code(), content="RULE_NOT_SATISFIED")
      inspect(find_context(reasons[0], "target"), content="Some(\"rule\")")
      inspect(find_context(reasons[0], "level"), content="Some(\"info\")")
    }
    Err(reason) => fail(reason.message())
  }
}

///|
test "state not found" {
  let ir = build_ir()
  let rule_results : Map[String, Bool] = Map::new()
  match compute_available_transitions(ir, "Missing", rule_results) {
    Ok(_) => fail("expected state not found")
    Err(reason) => inspect(reason.code(), content="STATE_NOT_FOUND")
  }
}
