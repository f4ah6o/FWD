///|
/// v4.2 metrics HTML projection (read-only).

pub(all) struct V4MetricsWindowView {
  entity_id : String
  from_logical_time : Int
  to_logical_time : Int
}

pub(all) struct V4MetricsCountsView {
  ok : Int
  failed : Int
  blocked : Int
  denied : Int
}

pub(all) struct V4MetricsByKindView {
  kind : String
  counts : V4MetricsCountsView
}

pub(all) struct V4MetricsView {
  window : V4MetricsWindowView
  total : V4MetricsCountsView
  by_kind : Array[V4MetricsByKindView]
}

fn counts_nodes_v4_2(counts : V4MetricsCountsView) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("ok: " + counts.ok.to_string())]))
  nodes.push(@tmpx.p([], [@tmpx.text("failed: " + counts.failed.to_string())]))
  nodes.push(@tmpx.p([], [@tmpx.text("blocked: " + counts.blocked.to_string())]))
  nodes.push(@tmpx.p([], [@tmpx.text("denied: " + counts.denied.to_string())]))
  nodes
}

fn window_node_v4_2(window : V4MetricsWindowView) -> @tmpx.Node {
  @tmpx.div([
    @tmpx.class_("fwd-metrics-window"),
  ], [
    @tmpx.p([], [@tmpx.text("entityId: " + window.entity_id)]),
    @tmpx.p([], [@tmpx.text("fromLogicalTime: " + window.from_logical_time.to_string())]),
    @tmpx.p([], [@tmpx.text("toLogicalTime: " + window.to_logical_time.to_string())]),
  ])
}

fn total_node_v4_2(total : V4MetricsCountsView) -> @tmpx.Node {
  let nodes = counts_nodes_v4_2(total)
  @tmpx.div([
    @tmpx.class_("fwd-metrics-total"),
  ], nodes)
}

fn by_kind_node_v4_2(item : V4MetricsByKindView) -> @tmpx.Node {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(@tmpx.p([], [@tmpx.text("kind: " + item.kind)]))
  for node in counts_nodes_v4_2(item.counts) {
    nodes.push(node)
  }
  @tmpx.div([
    @tmpx.class_("fwd-metrics-kind"),
    @tmpx.data_attr("kind", item.kind),
  ], nodes)
}

fn metrics_nodes_v4_2(view : V4MetricsView) -> Array[@tmpx.Node] {
  let nodes : Array[@tmpx.Node] = []
  nodes.push(window_node_v4_2(view.window))
  nodes.push(total_node_v4_2(view.total))
  for item in view.by_kind {
    nodes.push(by_kind_node_v4_2(item))
  }
  nodes
}

///|
pub fn render_metrics_html_v4_2(view : V4MetricsView) -> String {
  let root = @tmpx.div([
    @tmpx.class_("fwd-metrics"),
  ], metrics_nodes_v4_2(view))
  @tmpx.render(root)
}

///|
pub fn render_metrics_html_v4_2_mx(view : V4MetricsView) -> String {
  let root = @tmpx.div([
    @tmpx.class_("fwd-metrics"),
    @tmpx.mx_target(".fwd-metrics"),
    @tmpx.mx_swap(@tmpx.MxSwap::OuterHTML),
  ], metrics_nodes_v4_2(view))
  @tmpx.render(root)
}
