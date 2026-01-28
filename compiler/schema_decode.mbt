///|
/// Decode YAML AST into L1 Schema.
///|
pub(all) suberror DecodeError {
  DecodeError(String)
}

///|
fn DecodeError::new(message : String) -> DecodeError {
  DecodeError::DecodeError(message)
}

///|
pub impl Show for DecodeError with output(self, logger) {
  match self {
    DecodeError::DecodeError(message) => logger.write_string(message)
  }
}

///|
fn map_find(items : Array[(String, YamlValue)], key : String) -> YamlValue? {
  for item in items {
    if item.0 == key {
      return Some(item.1)
    }
  }
  None
}

///|
fn first_value(a : YamlValue?, b : YamlValue?) -> YamlValue? {
  match a {
    Some(v) => Some(v)
    None => b
  }
}

///|
fn as_map(value : YamlValue, ctx : String) -> Array[(String, YamlValue)] raise DecodeError {
  match value {
    Map(items) => items
    _ => raise DecodeError::new("expected map for " + ctx)
  }
}

///|
fn as_seq(value : YamlValue, ctx : String) -> Array[YamlValue] raise DecodeError {
  match value {
    Seq(items) => items
    _ => raise DecodeError::new("expected list for " + ctx)
  }
}

///|
fn as_string(value : YamlValue, ctx : String) -> String raise DecodeError {
  match value {
    String(s) => s
    Bool(b) => if b { "true" } else { "false" }
    Null => ""
    _ => raise DecodeError::new("expected string for " + ctx)
  }
}

///|
fn as_bool(value : YamlValue, ctx : String) -> Bool raise DecodeError {
  match value {
    Bool(b) => b
    String(s) => {
      if s == "true" {
        true
      } else if s == "false" {
        false
      } else {
        raise DecodeError::new("expected bool for " + ctx)
      }
    }
    _ => raise DecodeError::new("expected bool for " + ctx)
  }
}

///|
fn optional_string(map : Array[(String, YamlValue)], key : String) -> String? raise DecodeError {
  match map_find(map, key) {
    Some(v) => Some(as_string(v, key))
    None => None
  }
}

///|
fn optional_seq(map : Array[(String, YamlValue)], key : String) -> Array[YamlValue] raise DecodeError {
  match map_find(map, key) {
    Some(v) => as_seq(v, key)
    None => []
  }
}

///|
fn decode_state(value : YamlValue) -> @schema.StateDefinition raise DecodeError {
  match value {
    String(name) => { name, }
    Map(items) => {
      let name_value = map_find(items, "name").unwrap_or(YamlValue::String(""))
      let name = as_string(name_value, "states.name")
      { name, }
    }
    _ => raise DecodeError::new("invalid state definition")
  }
}

///|
fn decode_attribute(value : YamlValue) -> @schema.AttributeDefinition raise DecodeError {
  let items = as_map(value, "attribute")
  let name_value = map_find(items, "name").unwrap_or(YamlValue::String(""))
  let name = as_string(name_value, "attribute.name")
  let type_value = first_value(map_find(items, "type"), map_find(items, "type_ref"))
  let type_ref = as_string(type_value.unwrap_or(YamlValue::String("")), "attribute.type")
  let optional = match map_find(items, "optional") {
    Some(v) => as_bool(v, "attribute.optional")
    None => false
  }
  { name, type_ref, optional }
}

///|
fn decode_entity(value : YamlValue) -> @schema.EntityDefinition raise DecodeError {
  let items = as_map(value, "entity")
  let name_value = map_find(items, "name").unwrap_or(YamlValue::String(""))
  let name = as_string(name_value, "entity.name")
  let init_value = first_value(map_find(items, "initialState"), map_find(items, "initial_state"))
  let initial_state = as_string(init_value.unwrap_or(YamlValue::String("")), "entity.initialState")
  let attrs_raw = optional_seq(items, "attributes")
  let attrs : Array[@schema.AttributeDefinition] = []
  for raw in attrs_raw {
    attrs.push(decode_attribute(raw))
  }
  { name, initial_state, attributes: attrs }
}

///|
fn decode_rule_expr_from_map(
  items : Array[(String, YamlValue)],
) -> @schema.RuleExpression raise DecodeError {
  let type_value = optional_string(items, "type")
  let preset_value = optional_string(items, "preset")
  let impl_value = optional_string(items, "impl")
  match type_value {
    Some(t) => {
      if t == "custom" {
        match impl_value {
          Some(impl_name) => @schema.RuleExpression::Custom(impl_name)
          None => raise DecodeError::new("custom rule requires impl")
        }
      } else if t == "preset" {
        match preset_value {
          Some(name) => @schema.RuleExpression::Preset(name)
          None => raise DecodeError::new("preset rule requires preset")
        }
      } else {
        @schema.RuleExpression::Preset(t)
      }
    }
    None => {
      match preset_value {
        Some(name) => @schema.RuleExpression::Preset(name)
        None => {
          match impl_value {
            Some(impl_name) => @schema.RuleExpression::Custom(impl_name)
            None => raise DecodeError::new("rule expression missing type/preset/impl")
          }
        }
      }
    }
  }
}

///|
fn decode_rule_expr(value : YamlValue) -> @schema.RuleExpression raise DecodeError {
  match value {
    String(name) => @schema.RuleExpression::Preset(name)
    Map(items) => decode_rule_expr_from_map(items)
    _ => raise DecodeError::new("invalid rule expression")
  }
}

///|
fn decode_rule_def(value : YamlValue) -> @schema.RuleDefinition raise DecodeError {
  match value {
    String(name) => {
      { name, expr: @schema.RuleExpression::Preset(name), description: None }
    }
    Map(items) => {
      let name_value = map_find(items, "name").unwrap_or(YamlValue::String(""))
      let name = as_string(name_value, "rule.name")
      let type_value = optional_string(items, "type")
      let preset_value = optional_string(items, "preset")
      let impl_value = optional_string(items, "impl")
      let expr = match type_value {
        Some(t) => {
          if t == "preset" && preset_value is None && impl_value is None {
            @schema.RuleExpression::Preset(name)
          } else {
            decode_rule_expr_from_map(items)
          }
        }
        None => decode_rule_expr_from_map(items)
      }
      let description = optional_string(items, "description")
      { name, expr, description }
    }
    _ => raise DecodeError::new("invalid rule definition")
  }
}

///|
fn decode_reason(value : YamlValue) -> @schema.ReasonDefinition raise DecodeError {
  let items = as_map(value, "reason")
  let code_value = map_find(items, "code").unwrap_or(YamlValue::String(""))
  let code = as_string(code_value, "reason.code")
  let message_value = map_find(items, "message").unwrap_or(YamlValue::String(""))
  let message = as_string(message_value, "reason.message")
  let context_schema = match optional_string(items, "contextSchema") {
    Some(v) => Some(v)
    None => optional_string(items, "context_schema")
  }
  { code, message, context_schema }
}

///|
fn decode_boundary(value : YamlValue) -> @schema.BoundaryDefinition raise DecodeError {
  match value {
    String(name) => { name, }
    Map(items) => {
      let name_value = map_find(items, "name").unwrap_or(YamlValue::String(""))
      let name = as_string(name_value, "boundary.name")
      { name, }
    }
    _ => raise DecodeError::new("invalid boundary definition")
  }
}

///|
fn decode_effect(value : YamlValue) -> @schema.EffectDefinition raise DecodeError {
  let items = as_map(value, "effect")
  let name_value = map_find(items, "name").unwrap_or(YamlValue::String(""))
  let name = as_string(name_value, "effect.name")
  let kind_value = map_find(items, "kind").unwrap_or(YamlValue::String("sync"))
  let kind_raw = as_string(kind_value, "effect.kind")
  let kind = if kind_raw == "async" {
    @core.EffectKind::Async
  } else {
    @core.EffectKind::Sync
  }
  { name, kind }
}

///|
fn decode_transition(value : YamlValue) -> @schema.TransitionDefinition raise DecodeError {
  let items = as_map(value, "transition")
  let name_value = map_find(items, "name").unwrap_or(YamlValue::String(""))
  let name = as_string(name_value, "transition.name")
  let from_value = map_find(items, "from").unwrap_or(YamlValue::String(""))
  let from = as_string(from_value, "transition.from")
  let to_value = map_find(items, "to").unwrap_or(YamlValue::String(""))
  let to = as_string(to_value, "transition.to")
  let rules_raw = optional_seq(items, "rules")
  let rules : Array[@schema.RuleExpression] = []
  for raw in rules_raw {
    rules.push(decode_rule_expr(raw))
  }
  let effects_raw = optional_seq(items, "effects")
  let effects : Array[String] = []
  for raw in effects_raw {
    effects.push(as_string(raw, "transition.effects"))
  }
  let input_schema = match optional_string(items, "inputSchema") {
    Some(v) => Some(v)
    None => optional_string(items, "input_schema")
  }
  { name, from, to, rules, effects, input_schema }
}

///|
/// Decode a YAML AST into Schema.
///|
pub fn schema_from_yaml(value : YamlValue) -> @schema.Schema raise DecodeError {
  let root = as_map(value, "root")
  let fwd_value = first_value(map_find(root, "fwdVersion"), map_find(root, "fwd_version"))
  let fwd_version = as_string(fwd_value.unwrap_or(YamlValue::String("")), "fwdVersion")
  let schema_value = first_value(map_find(root, "schemaVersion"), map_find(root, "schema_version"))
  let schema_version = as_string(schema_value.unwrap_or(YamlValue::String("")), "schemaVersion")
  let states_raw = optional_seq(root, "states")
  let states : Array[@schema.StateDefinition] = []
  for raw in states_raw {
    states.push(decode_state(raw))
  }
  let entities_raw = optional_seq(root, "entities")
  let entities : Array[@schema.EntityDefinition] = []
  for raw in entities_raw {
    entities.push(decode_entity(raw))
  }
  let transitions_raw = optional_seq(root, "transitions")
  let transitions : Array[@schema.TransitionDefinition] = []
  for raw in transitions_raw {
    transitions.push(decode_transition(raw))
  }
  let rules_raw = optional_seq(root, "rules")
  let rules : Array[@schema.RuleDefinition] = []
  for raw in rules_raw {
    rules.push(decode_rule_def(raw))
  }
  let reasons_raw = optional_seq(root, "reasons")
  let reasons : Array[@schema.ReasonDefinition] = []
  for raw in reasons_raw {
    reasons.push(decode_reason(raw))
  }
  let boundaries_raw = optional_seq(root, "boundaries")
  let boundaries : Array[@schema.BoundaryDefinition] = []
  for raw in boundaries_raw {
    boundaries.push(decode_boundary(raw))
  }
  let effects_raw = optional_seq(root, "effects")
  let effects : Array[@schema.EffectDefinition] = []
  for raw in effects_raw {
    effects.push(decode_effect(raw))
  }
  {
    fwd_version,
    schema_version,
    states,
    entities,
    transitions,
    rules,
    reasons,
    boundaries,
    effects,
  }
}
