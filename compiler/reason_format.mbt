///|
fn rf_compare_string(a : String, b : String) -> Int {
  let len_a = a.length()
  let len_b = b.length()
  let min_len = if len_a < len_b { len_a } else { len_b }
  for i in 0..<min_len {
    let ca = a[i].to_int()
    let cb = b[i].to_int()
    if ca < cb {
      return -1
    } else if ca > cb {
      return 1
    }
  }
  if len_a < len_b {
    -1
  } else if len_a > len_b {
    1
  } else {
    0
  }
}

///|
fn find_last_value(
  context : Array[(String, String)],
  key : String,
) -> String? {
  for i in 0..<context.length() {
    let index = context.length() - 1 - i
    let pair = context[index]
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
pub fn reason_context_pairs(reason : @core.Reason) -> Array[(String, String)] {
  let context = reason.context()
  let keys : Array[String] = []
  for pair in context {
    let key = pair.0
    if !keys.contains(key) {
      keys.push(key)
    }
  }
  keys.sort_by(rf_compare_string)
  let pairs : Array[(String, String)] = []
  for key in keys {
    match find_last_value(context, key) {
      Some(value) => pairs.push((key, value))
      None => ()
    }
  }
  pairs
}

///|
pub fn reason_to_human_line(reason : @core.Reason) -> String {
  let pairs = reason_context_pairs(reason)
  if pairs.length() == 0 {
    return reason.code() + ": " + reason.message()
  }
  let sb = StringBuilder::new()
  sb.write_view(reason.code())
  sb.write_view(": ")
  sb.write_view(reason.message())
  sb.write_view(" (")
  let mut first = true
  for pair in pairs {
    if !first {
      sb.write_char(' ')
    }
    first = false
    sb.write_view(pair.0)
    sb.write_char('=')
    sb.write_view(pair.1)
  }
  sb.write_char(')')
  sb.to_string()
}
