///|
fn read_text_export(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected(path : String) -> String raise {
  match read_text_export(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
test "metrics export jsonl fixture" {
  let expected = load_expected("examples/v3_7/metrics_export/expected.jsonl")
  let snapshot : @metrics_v3_6.MetricsSnapshot = {
    window: {
      entity_id: "order-1",
      from_logical_time: Some(10),
      to_logical_time: Some(12),
    },
    total: {
      ok: 1,
      failed: 1,
      blocked: 0,
      denied: 1,
    },
    by_kind: [
      {
        kind: @metrics_v3_6.MetricKind::Transition,
        counts: { ok: 1, failed: 0, blocked: 0, denied: 0 },
      },
      {
        kind: @metrics_v3_6.MetricKind::Policy,
        counts: { ok: 0, failed: 0, blocked: 0, denied: 1 },
      },
      {
        kind: @metrics_v3_6.MetricKind::Effect,
        counts: { ok: 0, failed: 1, blocked: 0, denied: 0 },
      },
    ],
  }
  let mut output = export_jsonl(snapshot)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
