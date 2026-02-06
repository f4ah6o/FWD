///|
fn read_text_metrics_v4_2(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected_metrics_v4_2(path : String) -> String raise {
  match read_text_metrics_v4_2(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

fn counts_view_v4_2(ok : Int, failed : Int, blocked : Int, denied : Int) -> V4MetricsCountsView {
  { ok, failed, blocked, denied }
}

fn sample_view_v4_2() -> V4MetricsView {
  {
    window: { entity_id: "order-1", from_logical_time: 10, to_logical_time: 12 },
    total: counts_view_v4_2(1, 1, 0, 1),
    by_kind: [
      { kind: "transition", counts: counts_view_v4_2(1, 0, 0, 0) },
      { kind: "policy", counts: counts_view_v4_2(0, 0, 0, 1) },
      { kind: "effect", counts: counts_view_v4_2(0, 1, 0, 0) },
    ],
  }
}

///|
test "v4.2 metrics html fixture" {
  let expected = load_expected_metrics_v4_2("examples/v4_2/metrics/expected.html")
  let mut output = render_metrics_html_v4_2(sample_view_v4_2())
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}

///|
test "v4.2 metrics mx html fixture" {
  let expected = load_expected_metrics_v4_2("examples/v4_2/metrics/expected_mx.html")
  let mut output = render_metrics_html_v4_2_mx(sample_view_v4_2())
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
