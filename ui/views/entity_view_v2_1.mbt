///|
/// v2.1 entity HTML projection with history wiring.

///|
fn payload_text(payload : Json?) -> String {
  match payload {
    Some(value) => value.stringify(indent=2)
    None => "{}"
  }
}

///|
pub fn render_entity_html(snapshot : @store_v2_1.Snapshot) -> String {
  let history_url =
    "/v2.1/entities/" + snapshot.entity_id + "/history?format=v2_1_html"
  let root = @tmpx.div(
    [@tmpx.class_("fwd-entity")],
    [
      @tmpx.p([], [@tmpx.text("entityId: " + snapshot.entity_id)]),
      @tmpx.p([], [@tmpx.text("state: " + snapshot.state)]),
      @tmpx.p([], [@tmpx.text("version: " + snapshot.version.to_string())]),
      @tmpx.pre([], [@tmpx.text(payload_text(snapshot.payload))]),
      @tmpx.button([
        @tmpx.mx_get(history_url),
        @tmpx.mx_target(".fwd-history"),
        @tmpx.mx_swap(@tmpx.MxSwap::OuterHTML),
        @tmpx.mx_trigger_click(),
      ], [@tmpx.text("Load history")]),
      @tmpx.div([@tmpx.class_("fwd-history")], []),
    ],
  )
  @tmpx.render(root)
}
