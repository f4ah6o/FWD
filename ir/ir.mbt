///|
/// FWD-IR definitions (v1).
///|
pub(all) struct DirectedGraph[N, E] {
  nodes : Map[N, Unit]
  edges : Map[N, Map[N, E]]
}

///|
pub(all) struct TransitionRef {
  name : String
}

///|
pub(all) struct NormalizedEntity {
  name : String
  state : @core.StateTag
  data_schema : String?
}

///|
pub(all) struct NormalizedTransition {
  name : String
  from : @core.StateTag
  to : @core.StateTag
  rule_refs : Array[String]
  effect_refs : Array[String]
  input_schema : String?
}

///|
pub(all) enum CompiledRule {
  Preset(String)
  Custom(String)
}

///|
pub(all) struct ReasonSpec {
  code : String
  message : String
  context_schema : String?
}

///|
pub(all) struct EffectSpec {
  name : String
  kind : @core.EffectKind
}

///|
pub(all) struct FwdIR {
  version : String
  fwd_version : String
  state_graph : DirectedGraph[@core.StateTag, TransitionRef]
  entities : Map[String, NormalizedEntity]
  transitions : Map[String, NormalizedTransition]
  rules : Map[String, CompiledRule]
  reasons : Map[String, ReasonSpec]
  effects : Map[String, EffectSpec]
}
