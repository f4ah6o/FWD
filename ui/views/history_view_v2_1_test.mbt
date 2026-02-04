///|
fn read_text_history_view(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_history_events() -> Array[@history_v2_1.HistoryEvent] {
  let store = @history_v2_1.HistoryStore::new()
  ignore(store.append(
    "order-1",
    "submit",
    "Draft",
    "Approved",
    {
      "note": Json::string("ok")
    },
    @history_v2_1.HistoryResult::Executed,
    [],
  ))
  ignore(store.append(
    "order-1",
    "reject",
    "Approved",
    "Approved",
    {
      "note": Json::string("blocked")
    },
    @history_v2_1.HistoryResult::Blocked,
    [@core.Reason::with_context(
      "RULE_NOT_SATISFIED",
      "Rule not satisfied",
      [
        ("target", "rule"),
        ("level", "info"),
        ("hint", "Provide rule result true for this transition"),
      ],
    )],
  ))
  store.get("order-1")
}

///|
test "history html fixture" {
  let expected = match read_text_history_view(
    "examples/history_v2_1/expected.html",
    "expected history html",
  ) {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
  let events = load_history_events()
  let mut output = render_history_html(events)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
