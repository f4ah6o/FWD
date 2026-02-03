///|
/// Hypermedia resource projection (v1).

///|
pub(all) struct ResourceTransition {
  id : String
  to : String
}

///|
pub(all) struct ResourceBlockedTransition {
  id : String
  reasons : Array[@core.Reason]
}

///|
pub(all) struct Resource {
  available_transitions : Array[ResourceTransition]
  blocked_transitions : Array[ResourceBlockedTransition]
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
pub fn resource_from_runtime(result : @runtime.RuntimeResult) -> Resource {
  let available : Array[ResourceTransition] = []
  for tr in result.available_transitions {
    available.push({ id: tr.id, to: tr.to })
  }
  let blocked : Array[ResourceBlockedTransition] = []
  for tr in result.blocked_transitions {
    blocked.push({ id: tr.id, reasons: tr.reasons })
  }
  available.sort_by((a, b) => compare_string(a.id, b.id))
  blocked.sort_by((a, b) => compare_string(a.id, b.id))
  {
    available_transitions: available,
    blocked_transitions: blocked,
  }
}
