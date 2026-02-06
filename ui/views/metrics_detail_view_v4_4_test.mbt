///|
fn read_text_metrics_detail_v4_4(path : String, label : String) -> Result[String, String] {
  let result : Result[String, @fs.IOError] = try? @fs.read_file_to_string(path)
  match result {
    Ok(text) => Ok(text)
    Err(err) => Err("read failed: " + label + ": " + err.to_string())
  }
}

///|
fn load_expected_metrics_detail_v4_4(path : String) -> String raise {
  match read_text_metrics_detail_v4_4(path, "expected") {
    Ok(text) => text
    Err(msg) => fail(msg)
  }
}

///|
test "v4.4 metrics detail html fixture" {
  let expected = load_expected_metrics_detail_v4_4("examples/v4_4/metrics_detail/expected.html")
  let view : V4_4MetricsDetailView = {
    kind: "transition",
    counts: { ok: 1, failed: 0, blocked: 0, denied: 0 },
  }
  let mut output = render_metrics_detail_html_v4_4(view)
  if expected.has_suffix("\n") {
    output = output + "\n"
  }
  inspect(output, content=expected)
}
