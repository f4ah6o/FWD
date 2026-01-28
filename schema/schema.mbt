///|
/// L1 schema types (self-describing meta model).
///|
pub(all) struct Schema {
  fwd_version : String
  schema_version : String
  states : Array[StateDefinition]
  entities : Array[EntityDefinition]
  transitions : Array[TransitionDefinition]
  rules : Array[RuleDefinition]
  reasons : Array[ReasonDefinition]
  boundaries : Array[BoundaryDefinition]
  effects : Array[EffectDefinition]
}

///|
pub(all) struct StateDefinition {
  name : String
}

///|
pub(all) struct AttributeDefinition {
  name : String
  type_ref : String
  optional : Bool
}

///|
pub(all) struct EntityDefinition {
  name : String
  initial_state : String
  attributes : Array[AttributeDefinition]
}

///|
pub(all) enum RuleExpression {
  Preset(String)
  Custom(String)
}

///|
pub(all) struct RuleDefinition {
  name : String
  expr : RuleExpression
  description : String?
}

///|
pub(all) struct ReasonDefinition {
  code : String
  message : String
  context_schema : String?
}

///|
pub(all) struct BoundaryDefinition {
  name : String
}

///|
pub(all) struct EffectDefinition {
  name : String
  kind : @core.EffectKind
}

///|
pub(all) struct TransitionDefinition {
  name : String
  from : String
  to : String
  rules : Array[RuleExpression]
  effects : Array[String]
  input_schema : String?
}
