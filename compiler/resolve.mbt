///|
/// Rule registry + resolve stage.
///|
pub(all) enum RuleOrigin {
  Builtin
  Schema
}

///|
pub(all) struct ResolvedSchema {
  schema : @schema.Schema
  rule_index : Map[String, RuleOrigin]
}

///|
pub fn builtin_rule_names() -> Array[String] {
  [
    "hasAtLeastOneState",
    "hasAtLeastOneTransition",
    "allReferencesResolved",
    "noBreakingChanges",
    "noBreakingChangesOrMigrationDefined",
  ]
}

///|
pub fn resolve_schema(schema : @schema.Schema) -> Result[ResolvedSchema, CompileError] {
  let rule_index : Map[String, RuleOrigin] = Map::new()
  for name in builtin_rule_names() {
    rule_index[name] = Builtin
  }

  let schema_rule_set : Map[String, Unit] = Map::new()
  for rule in schema.rules {
    if rule.name.length() == 0 {
      return Err(ResolveFailure("rule name is required"))
    }
    if schema_rule_set.contains(rule.name) {
      return Err(ResolveFailure("duplicate rule name: " + rule.name))
    }
    if rule_index.contains(rule.name) {
      return Err(ResolveFailure("rule name conflicts with builtin: " + rule.name))
    }
    schema_rule_set[rule.name] = ()
    rule_index[rule.name] = Schema
  }

  Ok({ schema, rule_index })
}
