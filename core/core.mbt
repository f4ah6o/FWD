///|
/// L0 core primitives: types only, no schema knowledge.
///|
pub(all) struct StateTag {
  value : String
} derive(Eq, Hash)

///|
pub fn StateTag::new(value : String) -> StateTag {
  { value, }
}

///|
pub fn StateTag::value(self : StateTag) -> String {
  self.value
}

///|
pub(all) struct Boundary {
  name : String
}

///|
pub fn Boundary::new(name : String) -> Boundary {
  { name, }
}

///|
pub fn Boundary::name(self : Boundary) -> String {
  self.name
}

///|
pub(all) struct Reason {
  code : String
  message : String
  context : Array[(String, String)]
}

///|
pub fn Reason::new(code : String, message : String) -> Reason {
  { code, message, context: [] }
}

///|
pub fn Reason::with_context(
  code : String,
  message : String,
  context : Array[(String, String)],
) -> Reason {
  { code, message, context }
}

///|
pub fn Reason::code(self : Reason) -> String {
  self.code
}

///|
pub fn Reason::message(self : Reason) -> String {
  self.message
}

///|
pub fn Reason::context(self : Reason) -> Array[(String, String)] {
  self.context
}

///|
pub(all) struct Entity[S, D] {
  state : S
  data : D
}

///|
pub fn[S, D] Entity::new(state : S, data : D) -> Entity[S, D] {
  { state, data }
}

///|
pub fn[S, D] Entity::state(self : Entity[S, D]) -> S {
  self.state
}

///|
pub fn[S, D] Entity::data(self : Entity[S, D]) -> D {
  self.data
}

///|
/// Effect execution kind used by schema and IR.
///|
pub(all) enum EffectKind {
  Sync
  Async
}
