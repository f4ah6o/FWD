///|
fn read_text_metrics_v4_4(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected_metrics_v4_4(path : String) -> String raise {
  match read_text_metrics_v4_4(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

fn counts_view_v4_4(ok : Int, failed : Int, blocked : Int, denied : Int) -> V4_4MetricsCountsView {
  { ok, failed, blocked, denied }
}

fn sample_view_v4_4() -> V4_4MetricsView {
  {
    window: { entity_id: "order-1", from_logical_time: 10, to_logical_time: 12 },
    total: counts_view_v4_4(1, 1, 0, 1),
    by_kind: [
      { kind: "transition", counts: counts_view_v4_4(1, 0, 0, 0) },
      { kind: "policy", counts: counts_view_v4_4(0, 0, 0, 1) },
      { kind: "effect", counts: counts_view_v4_4(0, 1, 0, 0) },
    ],
  }
}

///|
test "v4.4 metrics html fixture" {
  let expected = load_expected_metrics_v4_4("examples/v4_4/metrics/expected.html")
  let mut output = render_metrics_html_v4_4(sample_view_v4_4())
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "v4.4 metrics mx html fixture" {
  let expected = load_expected_metrics_v4_4("examples/v4_4/metrics/expected_mx.html")
  let mut output = render_metrics_html_v4_4_mx(sample_view_v4_4())
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
