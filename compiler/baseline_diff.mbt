///|
fn append_reasons(dst : Array[@core.Reason], src : Array[@core.Reason]) -> Unit {
  for reason in src {
    dst.push(reason)
  }
}

///|
fn find_context_value(reason : @core.Reason, key : String) -> String? {
  for pair in reason.context() {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
fn reason_kind(reason : @core.Reason) -> String {
  match find_context_value(reason, "kind") {
    Some(kind) => kind
    None => {
      let code = reason.code()
      if code == "STATE_REMOVED" {
        "stateRemoved"
      } else if code == "TRANSITION_REMOVED" {
        "transitionRemoved"
      } else if code == "TRANSITION_MODIFIED" {
        "transitionModified"
      } else {
        "unknown"
      }
    }
  }
}

///|
fn reason_subject(reason : @core.Reason) -> String {
  match find_context_value(reason, "subject") {
    Some(subject) => subject
    None =>
      match find_context_value(reason, "state") {
        Some(state) => state
        None =>
          match find_context_value(reason, "transition") {
            Some(transition) => transition
            None => ""
          }
      }
  }
}

///|
fn reason_field(reason : @core.Reason) -> String {
  match find_context_value(reason, "field") {
    Some(field) => field
    None => ""
  }
}

///|
fn kind_rank(kind : String) -> Int {
  if kind == "stateRemoved" {
    0
  } else if kind == "transitionRemoved" {
    1
  } else if kind == "transitionModified" {
    2
  } else {
    3
  }
}

///|
fn field_rank(field : String) -> Int {
  if field == "from" {
    0
  } else if field == "to" {
    1
  } else if field == "from,to" {
    2
  } else {
    3
  }
}

///|
fn compare_int(a : Int, b : Int) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn compare_string(a : String, b : String) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn reason_rank(reason : @core.Reason) -> Int {
  let code = reason.code()
  if code == "STATE_REMOVED" || code == "TRANSITION_REMOVED" ||
      code == "TRANSITION_MODIFIED" {
    0
  } else if code == "MIGRATION_REQUIRED" {
    1
  } else {
    2
  }
}

///|
fn compare_reason(a : @core.Reason, b : @core.Reason) -> Int {
  let rank = compare_int(reason_rank(a), reason_rank(b))
  if rank != 0 {
    return rank
  }
  let kind = compare_int(kind_rank(reason_kind(a)), kind_rank(reason_kind(b)))
  if kind != 0 {
    return kind
  }
  let subject = compare_string(reason_subject(a), reason_subject(b))
  if subject != 0 {
    return subject
  }
  let field = compare_int(
    field_rank(reason_field(a)),
    field_rank(reason_field(b)),
  )
  if field != 0 {
    return field
  }
  compare_string(reason_field(a), reason_field(b))
}

///|
fn push_unique(dst : Array[String], value : String) -> Unit {
  for item in dst {
    if item == value {
      return
    }
  }
  dst.push(value)
}

///|
fn summarize_migration_required(
  reasons : Array[@core.Reason],
) -> Array[@core.Reason] {
  let summaries : Array[@core.Reason] = []
  let mut count = 0
  let kinds : Array[String] = []
  let subjects : Array[String] = []
  let scopes : Array[String] = []
  for reason in reasons {
    if reason.code() == "MIGRATION_REQUIRED" {
      count += 1
      match find_context_value(reason, "kind") {
        Some(kind) => push_unique(kinds, kind)
        None => ()
      }
      match find_context_value(reason, "subject") {
        Some(subject) => push_unique(subjects, subject)
        None => ()
      }
      match find_context_value(reason, "scope") {
        Some(scope) => push_unique(scopes, scope)
        None => ()
      }
    }
  }
  if count == 0 {
    return summaries
  }
  kinds.sort_by(compare_string)
  subjects.sort_by(compare_string)
  scopes.sort_by(compare_string)
  let context : Array[(String, String)] = []
  context.push(("count", count.to_string()))
  context.push(("kinds", kinds.join(",")))
  context.push(("subjects", subjects.join(",")))
  context.push(("scopes", scopes.join(",")))
  context.push(("target", "baseline"))
  context.push(
    ("hint", "Breaking changes detected; provide migration definitions"),
  )
  summaries.push(
    @core.Reason::with_context(
      "MIGRATION_REQUIRED", "breaking change requires migration", context,
    ),
  )
  summaries
}

///|
fn has_global_migrate(schema : @schema.Schema) -> Bool {
  for effect in schema.effects {
    if effect.name == "migrate" {
      return true
    }
  }
  false
}

///|
fn has_migrate_effect(effects : Array[String]) -> Bool {
  for name in effects {
    if name == "migrate" {
      return true
    }
  }
  false
}

///|
fn migration_required(
  kind : String,
  subject : String,
  scope : String,
  extra : Array[(String, String)],
) -> @core.Reason {
  let ctx : Array[(String, String)] = []
  ctx.push(("kind", kind))
  ctx.push(("subject", subject))
  ctx.push(("scope", scope))
  ctx.push(("target", "baseline"))
  ctx.push(
    ("hint", "Breaking changes detected; provide migration definitions"),
  )
  append_reasons_context(ctx, extra)
  @core.Reason::with_context(
    "MIGRATION_REQUIRED", "breaking change requires migration", ctx,
  )
}

///|
fn append_reasons_context(
  dst : Array[(String, String)],
  src : Array[(String, String)],
) -> Unit {
  for pair in src {
    dst.push(pair)
  }
}

///|
fn diff_states(
  candidate : @schema.Schema,
  baseline : @schema.Schema,
  has_global : Bool,
) -> Array[@core.Reason] {
  let reasons : Array[@core.Reason] = []
  let candidate_state_set : Map[String, Unit] = Map::new()
  for state in candidate.states {
    candidate_state_set[state.name] = ()
  }
  for state in baseline.states {
    if !candidate_state_set.contains(state.name) {
      reasons.push(
        @core.Reason::with_context("STATE_REMOVED", "state removed", [
          ("state", state.name),
          ("kind", "stateRemoved"),
          ("subject", state.name),
          ("target", "state"),
          ("hint", "State removed; re-add state or define migration mapping"),
        ]),
      )
      if !has_global {
        reasons.push(
          migration_required("stateRemoved", state.name, "global", []),
        )
      }
    }
  }
  reasons
}

///|
fn diff_transitions(
  candidate : @schema.Schema,
  baseline : @schema.Schema,
  has_global : Bool,
) -> Array[@core.Reason] {
  let reasons : Array[@core.Reason] = []
  let candidate_transition_set : Map[String, Unit] = Map::new()
  let candidate_transition_map : Map[String, (String, String)] = Map::new()
  let candidate_transition_effects : Map[String, Array[String]] = Map::new()
  for transition in candidate.transitions {
    candidate_transition_set[transition.name] = ()
    candidate_transition_map[transition.name] = (transition.from, transition.to)
    candidate_transition_effects[transition.name] = transition.effects
  }
  for transition in baseline.transitions {
    if !candidate_transition_set.contains(transition.name) {
      reasons.push(
        @core.Reason::with_context("TRANSITION_REMOVED", "transition removed", [
          ("transition", transition.name),
          ("kind", "transitionRemoved"),
          ("subject", transition.name),
          ("target", "transition"),
          ("hint", "Transition removed; re-add transition or define migration mapping"),
        ]),
      )
      if !has_global {
        reasons.push(
          migration_required("transitionRemoved", transition.name, "global", []),
        )
      }
      continue
    }
    let pair = candidate_transition_map[transition.name]
    let candidate_from = pair.0
    let candidate_to = pair.1
    if transition.from != candidate_from || transition.to != candidate_to {
      let field = if transition.from != candidate_from &&
        transition.to != candidate_to {
        "from,to"
      } else if transition.from != candidate_from {
        "from"
      } else {
        "to"
      }
      let baseline_value = if field == "from" {
        transition.from
      } else if field == "to" {
        transition.to
      } else {
        transition.from + "->" + transition.to
      }
      let candidate_value = if field == "from" {
        candidate_from
      } else if field == "to" {
        candidate_to
      } else {
        candidate_from + "->" + candidate_to
      }
      reasons.push(
        @core.Reason::with_context("TRANSITION_MODIFIED", "transition modified", [
          ("transition", transition.name),
          ("field", field),
          ("baseline", baseline_value),
          ("candidate", candidate_value),
          ("kind", "transitionModified"),
          ("subject", transition.name),
          ("target", "transition"),
          ("hint", "Transition modified; review compatibility and add migration if needed"),
        ]),
      )
      let effects = candidate_transition_effects[transition.name]
      if !has_migrate_effect(effects) {
        reasons.push(
          migration_required(
            "transitionModified",
            transition.name,
            "transition",
            [
              ("field", field),
              ("baseline", baseline_value),
              ("candidate", candidate_value),
            ],
          ),
        )
      }
    }
  }
  reasons
}

///|
pub fn baseline_reasons(
  candidate : @schema.Schema,
  baseline : @schema.Schema,
) -> Array[@core.Reason] {
  let reasons : Array[@core.Reason] = []
  let has_global = has_global_migrate(candidate)
  append_reasons(reasons, diff_states(candidate, baseline, has_global))
  append_reasons(reasons, diff_transitions(candidate, baseline, has_global))
  let merged : Array[@core.Reason] = []
  let summary = summarize_migration_required(reasons)
  for reason in reasons {
    if reason.code() != "MIGRATION_REQUIRED" {
      merged.push(reason)
    }
  }
  append_reasons(merged, summary)
  merged.sort_by(compare_reason)
  merged
}
