///|
/// Compiler pipeline skeleton (v1: Parse -> Validate -> Emit).
///|
pub enum Stage {
  Parse
  Resolve
  Validate
  Normalize
  Emit
  Package
}

///|
pub enum CompileError {
  Unimplemented(Stage)
  ParseFailure(String)
  ValidationFailure(@core.Reason)
  EmitFailure(String)
}

///|
pub fn stage_to_string(stage : Stage) -> String {
  match stage {
    Parse => "parse"
    Resolve => "resolve"
    Validate => "validate"
    Normalize => "normalize"
    Emit => "emit"
    Package => "package"
  }
}

///|
pub fn describe_error(err : CompileError) -> String {
  match err {
    Unimplemented(stage) => "unimplemented: " + stage_to_string(stage)
    ParseFailure(msg) => "parse error: " + msg
    ValidationFailure(reason) =>
      "validation error: " + reason.code() + ": " + reason.message()
    EmitFailure(msg) => "emit error: " + msg
  }
}

///|
/// Parse YAML into a Schema.
///|
pub fn parse_yaml(input : String) -> Result[@schema.Schema, CompileError] {
  let value_result : Result[YamlValue, YamlError] = try? parse_yaml_value(input)
  match value_result {
    Ok(value) => {
      let schema_result : Result[@schema.Schema, DecodeError] =
        try? schema_from_yaml(value)
      match schema_result {
        Ok(schema) => Ok(schema)
        Err(err) => Err(ParseFailure(err.to_string()))
      }
    }
    Err(err) => Err(ParseFailure(err.to_string()))
  }
}

///|
/// Resolve references (stub). This is a no-op in the minimal pipeline.
///|
pub fn resolve_schema(schema : @schema.Schema) -> Result[@schema.Schema, CompileError] {
  Ok(schema)
}

///|
/// Validate schema against L1 rules (minimal v1 checks).
///|
pub fn validate_schema(schema : @schema.Schema) -> Result[Unit, @core.Reason] {
  if schema.fwd_version.length() == 0 {
    return Err(@core.Reason::new("missing_fwd_version", "fwdVersion is required"))
  }
  if schema.schema_version.length() == 0 {
    return Err(@core.Reason::new("missing_schema_version", "schemaVersion is required"))
  }
  if schema.states.length() == 0 {
    return Err(@core.Reason::new("no_states", "states must not be empty"))
  }
  if schema.transitions.length() == 0 {
    return Err(@core.Reason::new("no_transitions", "transitions must not be empty"))
  }
  let state_set : Map[String, Unit] = Map::new()
  for state in schema.states {
    state_set[state.name] = ()
  }
  for transition in schema.transitions {
    if !state_set.contains(transition.from) {
      return Err(@core.Reason::with_context(
        "unknown_state",
        "transition.from is not defined in states",
        [("state", transition.from)],
      ))
    }
    if !state_set.contains(transition.to) {
      return Err(@core.Reason::with_context(
        "unknown_state",
        "transition.to is not defined in states",
        [("state", transition.to)],
      ))
    }
  }
  Ok(())
}

///|
/// Emit IR from schema.
///|
pub fn emit_ir(schema : @schema.Schema) -> Result[@ir.FwdIR, CompileError] {
  Ok(emit_ir_from_schema(schema))
}

///|
/// Compile YAML text to FWD-IR.
///|
pub fn compile_yaml(input : String) -> Result[@ir.FwdIR, CompileError] {
  match parse_yaml(input) {
    Ok(schema) => {
      match validate_schema(schema) {
        Ok(_) => emit_ir(schema)
        Err(reason) => Err(ValidationFailure(reason))
      }
    }
    Err(err) => Err(err)
  }
}
