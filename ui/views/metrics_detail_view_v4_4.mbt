///|
/// v4.4 metrics detail HTML projection.

pub(all) struct V4_4MetricsCountsDetailView {
  ok : Int
  failed : Int
  blocked : Int
  denied : Int
}

pub(all) struct V4_4MetricsDetailView {
  kind : String
  counts : V4_4MetricsCountsDetailView
}

fn counts_nodes_v4_4_detail(counts : V4_4MetricsCountsDetailView) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("ok: " + counts.ok.to_string())]))
  nodes.push(@tmpx.p([], [@tmpx.text("failed: " + counts.failed.to_string())]))
  nodes.push(@tmpx.p([], [@tmpx.text("blocked: " + counts.blocked.to_string())]))
  nodes.push(@tmpx.p([], [@tmpx.text("denied: " + counts.denied.to_string())]))
  nodes
}

///|
pub fn render_metrics_detail_html_v4_4(view : V4_4MetricsDetailView) -> String {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("kind: " + view.kind)]))
  for node in counts_nodes_v4_4_detail(view.counts) {
    nodes.push(node)
  }
  let root = @tmpx.div([
    @tmpx.class_("fwd-metrics-detail"),
    @tmpx.data_attr("kind", view.kind),
  ], nodes)
  @tmpx.render(root)
}
