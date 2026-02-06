///|
/// v4.4 metrics HTML projection (with drilldown wiring).

pub(all) struct V4_4MetricsWindowView {
  entity_id : String
  from_logical_time : Int
  to_logical_time : Int
}

pub(all) struct V4_4MetricsCountsView {
  ok : Int
  failed : Int
  blocked : Int
  denied : Int
}

pub(all) struct V4_4MetricsByKindView {
  kind : String
  counts : V4_4MetricsCountsView
}

pub(all) struct V4_4MetricsView {
  window : V4_4MetricsWindowView
  total : V4_4MetricsCountsView
  by_kind : Array[V4_4MetricsByKindView]
}

fn counts_nodes_v4_4(counts : V4_4MetricsCountsView) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("ok: " + counts.ok.to_string())]))
  nodes.push(@tmpx.p([], [@tmpx.text("failed: " + counts.failed.to_string())]))
  nodes.push(@tmpx.p([], [@tmpx.text("blocked: " + counts.blocked.to_string())]))
  nodes.push(@tmpx.p([], [@tmpx.text("denied: " + counts.denied.to_string())]))
  nodes
}

fn window_node_v4_4(window : V4_4MetricsWindowView) -> @tmpx.Node {
  @tmpx.div([
    @tmpx.class_("fwd-metrics-window"),
  ], [
    @tmpx.p([], [@tmpx.text("entityId: " + window.entity_id)]),
    @tmpx.p([], [@tmpx.text("fromLogicalTime: " + window.from_logical_time.to_string())]),
    @tmpx.p([], [@tmpx.text("toLogicalTime: " + window.to_logical_time.to_string())]),
  ])
}

fn total_node_v4_4(total : V4_4MetricsCountsView) -> @tmpx.Node {
  let nodes = counts_nodes_v4_4(total)
  @tmpx.div([
    @tmpx.class_("fwd-metrics-total"),
  ], nodes)
}

fn by_kind_node_v4_4(item : V4_4MetricsByKindView) -> @tmpx.Node {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("kind: " + item.kind)]))
  for node in counts_nodes_v4_4(item.counts) {
    nodes.push(node)
  }
  @tmpx.div([
    @tmpx.class_("fwd-metrics-kind"),
    @tmpx.data_attr("kind", item.kind),
  ], nodes)
}

fn by_kind_node_v4_4_mx(item : V4_4MetricsByKindView) -> @tmpx.Node {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("kind: " + item.kind)]))
  for node in counts_nodes_v4_4(item.counts) {
    nodes.push(node)
  }
  let button = @tmpx.button([
    @tmpx.mx_get("/v4.4/metrics/kind/" + item.kind + "?format=html"),
    @tmpx.mx_target(".fwd-metrics-detail-" + item.kind),
    @tmpx.mx_swap(@tmpx.MxSwap::OuterHTML),
  ], [@tmpx.text("Details")])
  nodes.push(button)
  nodes.push(@tmpx.div([
    @tmpx.class_("fwd-metrics-detail-" + item.kind),
  ], []))
  @tmpx.div([
    @tmpx.class_("fwd-metrics-kind"),
    @tmpx.data_attr("kind", item.kind),
  ], nodes)
}

fn metrics_nodes_v4_4(view : V4_4MetricsView) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(window_node_v4_4(view.window))
  nodes.push(total_node_v4_4(view.total))
  for item in view.by_kind {
    nodes.push(by_kind_node_v4_4(item))
  }
  nodes
}

fn metrics_nodes_v4_4_mx(view : V4_4MetricsView) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(window_node_v4_4(view.window))
  nodes.push(total_node_v4_4(view.total))
  for item in view.by_kind {
    nodes.push(by_kind_node_v4_4_mx(item))
  }
  nodes
}

///|
pub fn render_metrics_html_v4_4(view : V4_4MetricsView) -> String {
  let root = @tmpx.div([
    @tmpx.class_("fwd-metrics"),
  ], metrics_nodes_v4_4(view))
  @tmpx.render(root)
}

///|
pub fn render_metrics_html_v4_4_mx(view : V4_4MetricsView) -> String {
  let root = @tmpx.div([
    @tmpx.class_("fwd-metrics"),
    @tmpx.mx_target(".fwd-metrics"),
    @tmpx.mx_swap(@tmpx.MxSwap::OuterHTML),
  ], metrics_nodes_v4_4_mx(view))
  @tmpx.render(root)
}
