///|
pub enum CompileError {
  ParseFailure(String)
  ResolveFailure(String)
  ValidationFailure(@core.Reason)
}

///|
pub fn describe_error(err : CompileError) -> String {
  match err {
    ParseFailure(msg) => "parse error: " + msg
    ResolveFailure(msg) => "resolve error: " + msg
    ValidationFailure(reason) =>
      "validation error: " + reason.code() + ": " + reason.message()
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
/// Validate schema against L1 rules (minimal v1 checks).
///|
pub fn validate_schema(resolved : ResolvedSchema) -> Result[Unit, @core.Reason] {
  let schema = resolved.schema
  let rule_index = resolved.rule_index
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
    if state.name.length() == 0 {
      return Err(@core.Reason::new("empty_state_name", "state name is required"))
    }
    if state_set.contains(state.name) {
      return Err(@core.Reason::with_context(
        "duplicate_state",
        "state name must be unique",
        [("name", state.name)],
      ))
    }
    state_set[state.name] = ()
  }

  let transition_set : Map[String, Unit] = Map::new()
  for transition in schema.transitions {
    if transition.name.length() == 0 {
      return Err(@core.Reason::new("empty_transition_name", "transition name is required"))
    }
    if transition_set.contains(transition.name) {
      return Err(@core.Reason::with_context(
        "duplicate_transition",
        "transition name must be unique",
        [("name", transition.name)],
      ))
    }
    transition_set[transition.name] = ()
    if transition.from.length() == 0 || transition.to.length() == 0 {
      return Err(@core.Reason::new("empty_transition_state", "transition from/to is required"))
    }
  }

  let entity_set : Map[String, Unit] = Map::new()
  for entity in schema.entities {
    if entity.name.length() == 0 {
      return Err(@core.Reason::new("empty_entity_name", "entity name is required"))
    }
    if entity_set.contains(entity.name) {
      return Err(@core.Reason::with_context(
        "duplicate_entity",
        "entity name must be unique",
        [("name", entity.name)],
      ))
    }
    entity_set[entity.name] = ()
    if entity.initial_state.length() == 0 {
      return Err(@core.Reason::new("empty_entity_state", "entity initialState is required"))
    }
  }

  let effect_set : Map[String, Unit] = Map::new()
  for effect in schema.effects {
    if effect.name.length() == 0 {
      return Err(@core.Reason::new("empty_effect_name", "effect name is required"))
    }
    if effect_set.contains(effect.name) {
      return Err(@core.Reason::with_context(
        "duplicate_effect",
        "effect name must be unique",
        [("name", effect.name)],
      ))
    }
    effect_set[effect.name] = ()
  }

  let rule_set : Map[String, Unit] = Map::new()
  for rule in schema.rules {
    if rule.name.length() == 0 {
      return Err(@core.Reason::new("empty_rule_name", "rule name is required"))
    }
    if rule_set.contains(rule.name) {
      return Err(@core.Reason::with_context(
        "duplicate_rule",
        "rule name must be unique",
        [("name", rule.name)],
      ))
    }
    rule_set[rule.name] = ()
  }

  let reason_set : Map[String, Unit] = Map::new()
  for reason in schema.reasons {
    if reason.code.length() == 0 {
      return Err(@core.Reason::new("empty_reason_code", "reason code is required"))
    }
    if reason_set.contains(reason.code) {
      return Err(@core.Reason::with_context(
        "duplicate_reason",
        "reason code must be unique",
        [("code", reason.code)],
      ))
    }
    reason_set[reason.code] = ()
  }

  let boundary_set : Map[String, Unit] = Map::new()
  for boundary in schema.boundaries {
    if boundary.name.length() == 0 {
      return Err(@core.Reason::new("empty_boundary_name", "boundary name is required"))
    }
    if boundary_set.contains(boundary.name) {
      return Err(@core.Reason::with_context(
        "duplicate_boundary",
        "boundary name must be unique",
        [("name", boundary.name)],
      ))
    }
    boundary_set[boundary.name] = ()
  }

  for entity in schema.entities {
    if !state_set.contains(entity.initial_state) {
      return Err(@core.Reason::with_context(
        "unknown_state",
        "entity initialState is not defined in states",
        [("state", entity.initial_state)],
      ))
    }
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
    for expr in transition.rules {
      match expr {
        @schema.RuleExpression::Preset(name) => {
          if !rule_index.contains(name) {
            return Err(@core.Reason::with_context(
              "unknown_rule",
              "rule is not defined",
              [("rule", name)],
            ))
          }
        }
        @schema.RuleExpression::Custom(impl_name) => {
          if impl_name.length() == 0 {
            return Err(@core.Reason::new(
              "empty_custom_rule",
              "custom rule impl is required",
            ))
          }
        }
      }
    }
    for effect_name in transition.effects {
      if !effect_set.contains(effect_name) {
        return Err(@core.Reason::with_context(
          "unknown_effect",
          "transition effect is not defined",
          [("effect", effect_name)],
        ))
      }
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
      match resolve_schema(schema) {
        Ok(resolved) => {
          match validate_schema(resolved) {
            Ok(_) => emit_ir(resolved.schema)
            Err(reason) => Err(ValidationFailure(reason))
          }
        }
        Err(err) => Err(err)
      }
    }
    Err(err) => Err(err)
  }
}
