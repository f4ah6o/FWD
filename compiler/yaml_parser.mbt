///|
/// Minimal YAML parser (indent-based, block style only).
///|
priv struct Line {
  indent : Int
  text : String
  line_no : Int
}

///|
fn strip_comment(line : String) -> String {
  let sb = StringBuilder::new()
  let mut in_single = false
  let mut in_double = false
  for c in line {
    if c == '\'' && !in_double {
      in_single = !in_single
      sb.write_char(c)
      continue
    }
    if c == '"' && !in_single {
      in_double = !in_double
      sb.write_char(c)
      continue
    }
    if c == '#' && !in_single && !in_double {
      break
    }
    sb.write_char(c)
  }
  sb.to_string()
}

///|
fn count_indent(line : String, line_no : Int) -> (Int, String) raise YamlError {
  let mut count = 0
  for c in line {
    if c == ' ' {
      count += 1
    } else if c == '\t' {
      raise YamlError::new("tabs are not supported", line_no)
    } else {
      break
    }
  }
  let rest = line.view(start_offset=count).to_string()
  (count, rest)
}

///|
fn to_lines(input : String) -> Array[Line] raise YamlError {
  let lines : Array[Line] = []
  let mut line_no = 0
  for raw_view in input.split("\n") {
    line_no += 1
    let mut raw = raw_view.to_string()
    if raw.has_suffix("\r") {
      raw = raw.view(end_offset=raw.length() - 1).to_string()
    }
    let no_comment = strip_comment(raw)
    let trimmed_end = no_comment.trim_end()
    if trimmed_end.trim().is_empty() {
      continue
    }
    let (indent, rest) = count_indent(trimmed_end.to_string(), line_no)
    let text = rest.trim_end().to_string()
    lines.push({ indent, text, line_no })
  }
  lines
}

///|
fn try_split_key_value(
  text : String,
  line_no : Int,
) -> (String, String?)? raise YamlError {
  let mut in_single = false
  let mut in_double = false
  let mut offset = 0
  for c in text {
    if c == '\'' && !in_double {
      in_single = !in_single
    } else if c == '"' && !in_single {
      in_double = !in_double
    } else if c == ':' && !in_single && !in_double {
      let key_view = text.view(end_offset=offset)
      let rest_view = text.view(start_offset=offset + 1)
      let key = key_view.trim().to_string()
      if key.is_empty() {
        raise YamlError::new("empty key", line_no)
      }
      let rest = rest_view.trim().to_string()
      if rest.is_empty() {
        return Some((key, None))
      }
      return Some((key, Some(rest)))
    }
    offset += c.utf16_len()
  }
  None
}

///|
fn split_key_value(text : String, line_no : Int) -> (String, String?) raise YamlError {
  match try_split_key_value(text, line_no) {
    Some(pair) => pair
    None => raise YamlError::new("expected ':'", line_no)
  }
}

///|
fn parse_double_quoted(text : String, line_no : Int) -> String raise YamlError {
  if !text.has_prefix("\"") || !text.has_suffix("\"") {
    raise YamlError::new("unterminated double-quoted string", line_no)
  }
  let inner = text.view(start_offset=1, end_offset=text.length() - 1).to_string()
  let sb = StringBuilder::new()
  let mut escape = false
  for c in inner {
    if escape {
      let out = match c {
        'n' => '\n'
        't' => '\t'
        'r' => '\r'
        '\\' => '\\'
        '"' => '"'
        other => other
      }
      sb.write_char(out)
      escape = false
    } else if c == '\\' {
      escape = true
    } else {
      sb.write_char(c)
    }
  }
  if escape {
    raise YamlError::new("invalid escape sequence", line_no)
  }
  sb.to_string()
}

///|
fn parse_single_quoted(text : String, line_no : Int) -> String raise YamlError {
  if !text.has_prefix("'") || !text.has_suffix("'") {
    raise YamlError::new("unterminated single-quoted string", line_no)
  }
  text.view(start_offset=1, end_offset=text.length() - 1).to_string()
}

///|
fn parse_scalar(text : String, line_no : Int) -> YamlValue raise YamlError {
  let trimmed = text.trim().to_string()
  if trimmed.is_empty() {
    return YamlValue::String("")
  }
  if trimmed == "null" || trimmed == "~" {
    return YamlValue::Null
  }
  if trimmed == "true" {
    return YamlValue::Bool(true)
  }
  if trimmed == "false" {
    return YamlValue::Bool(false)
  }
  if trimmed.has_prefix("\"") {
    return YamlValue::String(parse_double_quoted(trimmed, line_no))
  }
  if trimmed.has_prefix("'") {
    return YamlValue::String(parse_single_quoted(trimmed, line_no))
  }
  YamlValue::String(trimmed)
}

///|
fn parse_block(
  lines : Array[Line],
  start : Int,
  indent : Int,
) -> (YamlValue, Int) raise YamlError {
  if start >= lines.length() {
    raise YamlError::new("unexpected end of input", 0)
  }
  let first = lines[start]
  if first.indent != indent {
    raise YamlError::new("unexpected indentation", first.line_no)
  }
  if first.text.has_prefix("-") {
    parse_list(lines, start, indent)
  } else {
    parse_map(lines, start, indent)
  }
}

///|
fn parse_list(
  lines : Array[Line],
  start : Int,
  indent : Int,
) -> (YamlValue, Int) raise YamlError {
  let items : Array[YamlValue] = []
  let mut idx = start
  while idx < lines.length() {
    let line = lines[idx]
    if line.indent != indent {
      break
    }
    if !line.text.has_prefix("-") {
      raise YamlError::new("expected list item", line.line_no)
    }
    let mut rest = line.text.view(start_offset=1)
    if rest.has_prefix(" ") {
      rest = rest.view(start_offset=1)
    }
    let rest_text = rest.trim().to_string()
    if rest_text.is_empty() {
      if idx + 1 >= lines.length() {
        raise YamlError::new("expected nested block", line.line_no)
      }
      let next_indent = lines[idx + 1].indent
      if next_indent <= indent {
        raise YamlError::new("expected indented block", line.line_no)
      }
      let (value, next) = parse_block(lines, idx + 1, next_indent)
      items.push(value)
      idx = next
      continue
    }
    match try_split_key_value(rest_text, line.line_no) {
      Some((key, value_opt)) => {
        let entries : Array[(String, YamlValue)] = []
        let value = if value_opt is Some(v) {
          parse_scalar(v, line.line_no)
        } else {
          if idx + 1 >= lines.length() {
            raise YamlError::new("expected nested block", line.line_no)
          }
          let next_indent = lines[idx + 1].indent
          if next_indent <= indent {
            raise YamlError::new("expected indented block", line.line_no)
          }
          let (nested, next) = parse_block(lines, idx + 1, next_indent)
          idx = next
          entries.push((key, nested))
          items.push(YamlValue::Map(entries))
          continue
        }
        entries.push((key, value))
        let mut next_idx = idx + 1
        if next_idx < lines.length() && lines[next_idx].indent > indent {
          let next_indent = lines[next_idx].indent
          let (nested, next) = parse_block(lines, next_idx, next_indent)
          match nested {
            Map(more) => {
              for entry in more {
                entries.push(entry)
              }
            }
            _ => raise YamlError::new("expected map block", line.line_no)
          }
          next_idx = next
        }
        items.push(YamlValue::Map(entries))
        idx = next_idx
      }
      None => {
        let value = parse_scalar(rest_text, line.line_no)
        items.push(value)
        idx += 1
      }
    }
  }
  (YamlValue::Seq(items), idx)
}

///|
fn parse_map(
  lines : Array[Line],
  start : Int,
  indent : Int,
) -> (YamlValue, Int) raise YamlError {
  let entries : Array[(String, YamlValue)] = []
  let mut idx = start
  while idx < lines.length() {
    let line = lines[idx]
    if line.indent != indent {
      break
    }
    if line.text.has_prefix("-") {
      raise YamlError::new("unexpected list item", line.line_no)
    }
    let (key, value_opt) = split_key_value(line.text, line.line_no)
    if value_opt is Some(raw) {
      let value = parse_scalar(raw, line.line_no)
      entries.push((key, value))
      idx += 1
    } else {
      if idx + 1 >= lines.length() {
        raise YamlError::new("expected nested block", line.line_no)
      }
      let next_indent = lines[idx + 1].indent
      if next_indent <= indent {
        raise YamlError::new("expected indented block", line.line_no)
      }
      let (value, next) = parse_block(lines, idx + 1, next_indent)
      entries.push((key, value))
      idx = next
    }
  }
  (YamlValue::Map(entries), idx)
}

///|
/// Parse YAML input into YamlValue AST.
///|
pub fn parse_yaml_value(input : String) -> YamlValue raise YamlError {
  let lines = to_lines(input)
  if lines.is_empty() {
    raise YamlError::new("empty document", 0)
  }
  let (value, _) = parse_block(lines, 0, lines[0].indent)
  value
}
