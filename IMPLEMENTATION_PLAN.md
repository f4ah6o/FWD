# 実用化に向けた Implementation Plan (v1)

## 目的
- v1 プロトタイプを「現場で使える最小セット」へ引き上げる
- L1 スキーマの安定化と、検証・差分・IR 出力の再現性を担保する
- 以後の GUI / HATEOAS 実行基盤へ安全に接続できる土台を作る

## 目標スコープ (v1)
- CLI: validate / presets / IR emit が安定して動作し、JSON 出力が機械可読
- Schema: v1.0 を固定し、破壊的変更の検出と migration 要求を扱える
- IR: バージョン付き・決定的 (deterministic)・後方互換を前提とした JSON
- 参照解決・重複チェック・予約語衝突などの L1 ルールが網羅

## v1 非目標 (Non-Goals)
- GUI 実装
- 並列実行 / オーケストレーション
- 永続化 / ストレージ連携
- 認可・ユーザー管理
- 実トランザクション実行 (workflow engine 化)

## マイルストーン

### M0: 現状凍結とドキュメント整備
- v1 仕様 (schema/IR/rules) をドキュメントとして固定
- `schema/fwd_schema.yaml` と self-bootstrapping の期待動作を明記
- `just bootstrap` が常に通る状態に保つ

**DoD**
- 仕様の更新は必ず差分と理由を残す
- `just bootstrap` が CI で常時緑

### M1: Resolve/Validate の強化 (L1 準拠)
- 参照解決: states / transitions / rules / effects / boundaries / reasons
- `transitions.rules` が builtin / schema 定義のどちらかに必ず解決される
- 予約語衝突の検出 (builtin と同名ルール禁止)
- 状態・遷移の整合性 (from/to が state に存在) をチェック
- v1 での breaking change taxonomy を定義してドキュメント化
  - state の削除
  - transition 名の変更 / 削除
  - rule の semantic 変更 (挙動変更)

**DoD**
- 代表的な不正入力に対する原因付きエラー (Reason) が返る
- 解決不能な参照は必ず ValidationFailure で落ちる

### M2: IR/Emit の安定化
- IR JSON のバージョンを固定し、出力順序を決定的にする
- normalize レイヤ (必要なら) を定義し、出力との差異を最小化
- golden test で YAML -> IR の差分検出を自動化
- IR 互換の責務範囲を明記
  - v1 では IR v1.x の互換のみ保証
  - v2 以降は migration 層で対応する前提

**DoD**
- 同一入力は必ず同一 IR JSON を出力
- 主要なサンプルが golden で固定

### M3: Baseline Diff / Migration ルール
- `noBreakingChanges` の範囲を v1 定義に合わせて実装
- `noBreakingChangesOrMigrationDefined` の migrate 判定を整理
- `--baseline` を使った差分検出が JSON 出力で完結する

**DoD**
- breaking がある場合の Reason が JSON で機械処理できる
- baseline 差分のユースケースが examples に存在

### M4: 実行基盤への最小接続 (HATEOAS / Runtime)
- IR から「現在可能な遷移」を計算する API を定義
- Reason を UI / API に返す最低限のフォーマットを固定
- CLI で IR + runtime の簡易検証が可能 (サンプル実装)
- Runtime は「候補列挙 + Reason」のみに限定し、遷移実行は行わない

**DoD**
- 1 つのサンプルが CLI で遷移候補を列挙できる
- Reason が API 応答として整形可能

### M5: 配布・運用の最小整備
- CLI の usage / help を明確化
- 破壊的変更のルールを README に明記
- バージョン更新手順 (fwdVersion / schemaVersion) をドキュメント化

**DoD**
- 新規ユーザーが README だけで最小フローを実行可能

### M6: HATEOAS Scaffolding (Server Response Contract)
- runtime/CLI v1 を壊さず、UI が解釈できる Hypermedia Resource を定義
- runtime 結果 (available/blocked + Reason v1) を JSON resource に投影
- CLI: `hypermedia show` (IR + state + rule results → resource 出力)
- fixture + smoke test (expected.json を固定)

**DoD**
- fixture に対して JSON が決定的
- blocked には Reason v1 が入り、推測なし
- JSON で同一情報を表現できる

### M7: tmpx による HTML partial 生成 (Server-side View)
- Hypermedia Resource を tmpx で決定的 HTML として出力
- tmpx の typed/functional HTML DSL と決定的レンダリングを採用 citeturn3view0
- mhx 連携用 `mx-*` ヘルパを前提に view を構成 citeturn3view0

**DoD**
- HTML 出力が fixture で固定
- available/blocked transitions が UI コンポーネントとして描画される
- Reason v1 の message/hint が UI に表示できる形で出る

### M8: mhx をクライアント実行基盤として接続 (Client-side Hypermedia)
- `mx-*` 属性で “押したら遷移要求” が発火し、HTML を swap する最小経路
- mhx の `mx-*` 属性 / trigger DSL / swap を採用 citeturn2view0
- client は mhx 初期化のみ、UI は “遷移候補ボタン” で成立

**DoD**
- 1 サンプルで「遷移候補の列挙 → クリック → HTML swap」が成立
- 失敗 (blocked) は Reason v1 を UI に表示 (固定フォーマット)

## Frozen Contracts (v1)
- Reason v1: `schema/reason.schema.v1.json` + CLI schema tests (Reason JSON 正規化)
- Runtime availability v1: `examples/runtime_available/` fixtures + CLI/runtime tests
- Runtime execution v1: `examples/runtime_execute/` fixtures + CLI/runtime tests
- M6 Hypermedia Resource (JSON) v1: `examples/hypermedia_show/expected.json` + hypermedia tests
- M7 tmpx Deterministic HTML v1: `examples/hypermedia_show/expected.html` + ui/views tests
- M8 mhx Client Execution v1: `examples/hypermedia_show/expected_mx.html` + ui/client harness

## Frozen Contracts (v2 / v2.1 / v2.2)
**Principle**
- v1 契約は不変 (fixture 等価がゲート)
- 新規 work は “新 surface 追加” のみ
- 変更は必ず fixture + test で固定

### v2 (Hypermedia + Forms)
- M6 Hypermedia Resource v1 (CLI surface)
  - Fixtures: `examples/hypermedia_show/expected.json`, `examples/hypermedia_show/invalid_input.json`
  - Tests: `cli/hypermedia_output_test.mbt`, `cli/app_test.mbt`
- M7 tmpx deterministic HTML (v1 view)
  - Fixtures: `examples/hypermedia_show/expected.html`
  - Tests: `ui/views/resource_view_test.mbt`
- M8 mhx MX HTML contract + client harness
  - Fixtures: `examples/hypermedia_show/expected_mx.html`
  - Tests: `ui/views/resource_view_mx_test.mbt`
- M10 HTML Form First (v2 HTML-only surface)
  - Fixtures: `examples/api_v2/input_form/expected.html`, `examples/api_v2/input_form/expected_validate_ok.html`, `examples/api_v2/input_invalid/expected.json`
  - Tests: `api_v2/api_test.mbt`
- M11 Resource v2 contract (JSON/HTML/MX aligned)
  - Fixtures: `examples/resource_v2/expected.json`, `examples/resource_v2/expected.html`, `examples/resource_v2/expected_mx.html`
  - Tests: `ui/views/resource_view_v2_test.mbt`, `api_v2/api_test.mbt`

### v2.1 (Persistence + History + UI wiring)
- M12 Snapshot store v2.1
  - Fixtures: `examples/store_v2_1/expected_snapshot.json`, `examples/store_v2_1/expected_list.json`
  - Tests: `store_v2_1/store_test.mbt`
- M13 History contract v2.1
  - Fixtures: `examples/history_v2_1/expected_history.json`, `examples/history_v2_1/expected_empty.json`
  - Tests: `history_v2_1/history_test.mbt`
- M14 v2.1 API (CRUD + history + execute-and-persist)
  - Fixtures: `examples/api_v2_1/entities_create/expected.json`, `examples/api_v2_1/entities_get/expected.json`, `examples/api_v2_1/history_get/expected.json`, `examples/api_v2_1/execute_*/expected_*.json`
  - Tests: `api_v2_1/api_test.mbt`
- M15-M17 UI History HTML + mx swap + empty state
  - Fixtures: `examples/history_v2_1/expected.html`, `examples/history_v2_1/expected_empty.html`, `examples/api_v2_1/history_html/expected.html`, `examples/api_v2_1/history_html/expected_empty.html`, `examples/api_v2_1/entity_html/expected.html`
  - Tests: `ui/views/history_view_v2_1_test.mbt`, `ui/views/entity_view_v2_1_test.mbt`, `api_v2_1/api_test.mbt`
  - Note: history swap target is `.fwd-history` (contract)

### v2.2 (Effects)
- M18 Effects plan (pure planner)
  - Fixtures: `examples/effects_v2_2/planned/expected.json`, `examples/effects_v2_2/skipped_blocked/expected.json`
  - Tests: `effects_v2_2/planner_test.mbt`
- M20 CLI Effects plan
  - Fixtures: `examples/effects_v2_2/cli_planned/expected.json`, `examples/effects_v2_2/cli_skipped/expected.json`
  - Tests: `cli/effects_plan_output_test.mbt`, `cli/app_test.mbt`
- M21 Effects execute stub
  - Fixtures: `examples/effects_v2_2/execute/expected_executed.json`, `examples/effects_v2_2/execute/expected_skipped.json`
  - Tests: `effects_v2_2/execution_test.mbt`, `cli/effects_execute_output_test.mbt`
- M22 Effects HTTP surface + HTTP runner scaffold
  - Fixtures: `examples/api_v2_2/effects_plan/expected.json`, `examples/api_v2_2/effects_execute/expected.json`
  - Tests: `api_v2_2/api_test.mbt`, `effects_exec_adapters_v2_2/http_runner_test.mbt`
- M23 Record/Replay harness
  - Fixtures: `examples/effects_v2_2/record_replay/cassette_example.json`, `examples/effects_v2_2/record_replay/expected_executed.json`
  - Tests: `effects_exec_rr_v2_2/rr_test.mbt`
- M24 fwdc effects record
  - Fixtures: `examples/effects_v2_2/record_cli/expected_cassette.json`, `examples/effects_v2_2/record_cli/expected_execution.json`
  - Tests: `cli/effects_record_output_test.mbt`
- M25 fwdc effects run (config-based)
  - Fixtures: `examples/effects_v2_2/real_runner/config.json`, `examples/effects_v2_2/real_runner/expected_execution.json`
  - Tests: `effects_exec_real_v2_2/runner_test.mbt`, CLI run test in `cli/app_test.mbt`
- M26 Real HTTP transport (implementation-only)
  - CI is replay-only; transport wiring must not change frozen JSON surfaces

## クロスカット (常時実施)
- テスト: parse / resolve / validate / baseline のユニット + golden
- CI: `just ci` を品質ゲートにする
- ドキュメント: 仕様変更は必ず diff と理由を残す
- 仕様 → 実装 → golden の順序をスプリントの標準ループにする
- fixture-first: expected.json/html を先に固定
- no inference: resource 層は runtime/compiler の出力を投影するだけ

## Reason 最低限スキーマ (v1)
```json
{
  "code": "STATE_NOT_FOUND",
  "level": "error",
  "target": "transition.from",
  "message": "...",
  "hint": "..."
}
```

## 直近 1-2 スプリントの具体タスク案
- Resolve/Validate 強化 (M1)
- IR JSON の決定性 + golden テスト (M2)
- baseline 差分の Reason 整備 (M3 の一部)

---

# v2.2 Implementation Plan (Effects)

## 目的
- Effects を **pure/deterministic** な “計画(Plan)” として導入する
- v1/v2/v2.1 の凍結契約を壊さず、**新 surface** として追加する
- Reason v1 を維持し、診断は no-inference で返す

## v2.2 非目標 (Non-Goals)
- 実行時の副作用（I/O, network, DB）を行う
- 自動リトライ / 分散実行 / オーケストレーション
- Effects を永続化する正式なストア契約

## 前提
- v1/v2/v2.1 は **完全に維持**（契約・fixture 変更なし）
- v2.2 は **新しい CLI / API surface** のみ追加

## マイルストーン

### M18: Effect Spec + Plan (pure)
- `effects_v2_2/` 新規パッケージ
  - `effect_spec.mbt`（Effect/Kind/Result 型）
  - `effect_plan.mbt`（pure planner）
- Reason code（v1）を拡張
  - `EFFECT_UNSUPPORTED`
  - `EFFECT_INPUT_INVALID`
  - `EFFECT_BLOCKED_POLICY`（必要時のみ）

**DoD**
- IR + transition + input から **決定的な plan** を返す
- Reason v1 を source-site で生成
- 副作用は発生しない

### M19: Effect Plan JSON Contract
- `effects_v2_2/effect_plan_json.mbt`
- fixtures:
  - `examples/effects_v2_2/expected.json`
  - `examples/effects_v2_2/expected_blocked.json`

**DoD**
- JSON shape が fixture で固定
- Reason v1 を含む
- 出力順序が決定的

### M20: CLI surface (plan-only)
- `fwd effects plan <schema.yaml> --state <state> --transition <id> --input <json>`
- exit code は既存 CLI と整合:
  - `0`: valid request（plan が返る）
  - `1`: not_found / not_available
  - `2`: invalid input JSON

**DoD**
- CLI 出力が fixtures と完全一致
- schema/Reason の検証が通る

### M21: Optional Execution Adapter (stub)
- `effects_v2_2/executor_stub.mbt`（dry-run / no-op）
- 必要なら API surface:
  - `POST /v2.2/effects/execute`（new surface）

**DoD**
- 実行は明示的・分離された surface
- plan と execution は独立
- v1/v2/v2.1 を一切変更しない

## クロスカット (v2.2)
- fixture-first: expected.json を先に固定
- no inference: projection 層は推測しない
- deterministic: ソート順・出力順は固定
- Reason v1 を維持（必要なら v2 を別 surface で追加）

---

# v3 Implementation Plan (Concise)

## Principles
- v1/v2/v2.1/v2.2 の凍結契約は不変
- v3 は “新 surface 追加” のみ
- fixture-first + deterministic + no-inference を維持

## Themes (priority)
1) Effects Execution Hardening
2) Policy / Authorization layer
3) Resource v3 (canonical JSON + HTML/MX projection)
4) Timeline v3 (unified audit)
5) Server Adapter v3 (pure router)

## Non-Goals (v3)
- v2.2 effects surface の置き換え
- v2.1 persistence/history の置き換え
- Reason v1 の変更

## Milestones (v3)

### M30a: Retry/Backoff Policy Contract
- retry policy の JSON 契約 (決定的)
- backoff 計算は pure/deterministic

**DoD**
- fixtures で policy 決定を固定
- jitter は v3 では禁止（必要なら seed 注入 + fixture 固定の surface を別途追加）
- jitter surface を追加する場合は seed 必須・seed なしは拒否

### M30b: Idempotency Store Contract
- key tracking / TTL semantics を契約化
- append-only or deterministic state transitions

**DoD**
- fixtures で idempotency 状態を固定

### M30c: Execution Audit Contract
- per-item status/timing/result を append-only で記録
- effects 実行の監査ログ契約

**DoD**
- fixtures で audit event を固定
- 時間は logicalTime (monotonic counter) または外部注入の固定値のみを使用 (wall-clock 禁止)

### M31: Policy Gate (pre-execution)
- policy input/output の JSON 契約
- Reason v1 を利用（policy prefix の code: `POLICY_*`)
- decision shape は `allow|deny` + reasons を固定

**DoD**
- policy decision が決定的
- failures は Reason v1 で返す

### M32: Resource v3 (JSON/HTML/MX aligned)
- v3 canonical JSON に policy + effects preview + draft + field errors を内包
- HTML/MX は v3 JSON の純投影

**DoD**
- JSON/HTML/MX の fixtures を固定

### M33: Timeline v3
- transition / effects / policy の統合タイムライン契約
- ordering は `(entityId, logicalTime, sequence)` で決定

**DoD**
- append-only + deterministic order を fixture で固定
- 同一 logicalTime 内の sequence は 1,2,3... の単調増加で固定
- sequence の採番は event 生成時に確定し、投影層で並べ替えない

### M34: v3 HTTP Adapter
- `/v3/resource`
- `/v3/execute`
- `/v3/effects`
- `/v3/timeline`

**DoD**
- pure router + fixtures で JSON を固定
- HTTP status / envelope / Reason code を fixture で固定

## Frozen Contracts (v3)
- M30a: `examples/v3/retry_policy/expected*.json` + `retry_policy_v3/retry_policy_test.mbt`
- M30b: `examples/v3/idempotency/expected*.json` + `idempotency_v3/idempotency_test.mbt`
- M30c: `examples/v3/execution_audit/expected*.json` + `execution_audit_v3/audit_test.mbt`
- M31: `examples/v3/policy/expected*.json` + `policy_v3/policy_test.mbt`
- M32: `examples/resource_v3/expected.json|html|mx.html` + `hypermedia/resource_v3_test.mbt`, `ui/views/resource_view_v3_test.mbt`
- M33: `examples/v3/timeline/expected*.json` + `timeline_v3/timeline_test.mbt`
- M34: `examples/api_v3/**/expected*.json` + `api_v3/api_test.mbt`

## Frozen Contracts (v3.1)
- M35: `examples/v3_1/executor/expected_*.json` + `executor_v3_1/executor_test.mbt`
- M36: `executor_v3_1/runner.mbt` + `executor_v3_1/executor_test.mbt`
- M37: `examples/api_v3_1/execute/expected_*.json` + `api_v3_1/api_test.mbt`

## Frozen Contracts (v3.2)
- Timeline HTML projection: `examples/v3/timeline/expected.html` + `ui/views/timeline_view_v3_test.mbt`
- v3.2 timeline endpoint: `examples/api_v3_2/timeline/expected.html`, `examples/api_v3_2/timeline/expected_missing_entity.json` + `api_v3_2/api_test.mbt`

## Frozen Contracts (v3.3)
- Timeline query contract: `examples/v3_3/timeline_query/expected_cursor.json` + `timeline_v3_3/query_test.mbt`
- v3.3 timeline view: `examples/api_v3_3/timeline/expected_*.html` + `ui/views/timeline_view_v3_3_test.mbt`
- v3.3 timeline endpoint: `examples/api_v3_3/timeline/expected_*.html`, `examples/api_v3_3/timeline/expected_invalid_query.json` + `api_v3_3/api_test.mbt`

## Frozen Contracts (v3.4)
- Timeline event detail contract: `examples/v3_4/timeline_event_detail/expected.json` + `timeline_event_v3_4/detail_test.mbt`
- v3.4 timeline event view: `examples/v3_4/timeline_event_detail/expected.html` + `ui/views/timeline_event_view_v3_4_test.mbt`
- v3.4 timeline event endpoint: `examples/api_v3_4/timeline_event/expected*.json`, `examples/api_v3_4/timeline_event/expected.html` + `api_v3_4/api_test.mbt`
- v3.4 timeline mx view: `examples/v3_4/timeline_mx/expected.html` + `ui/views/timeline_view_v3_4_mx_test.mbt`

## Frozen Contracts (v3.5)
- Timeline export contract: `examples/v3_5/timeline_export/expected.jsonl` + `timeline_export_v3_5/export_test.mbt`
- v3.5 timeline export endpoint: `examples/api_v3_5/timeline_export/expected*.jsonl`, `examples/api_v3_5/timeline_export/expected_invalid_query.json` + `api_v3_5/api_test.mbt`

## Frozen Contracts (v3.6)
- Metrics contract: `examples/v3_6/metrics/expected.json` + `metrics_v3_6/metrics_test.mbt`
- v3.6 metrics endpoint: `examples/api_v3_6/metrics/expected.json`, `examples/api_v3_6/metrics/expected_invalid_query.json` + `api_v3_6/api_test.mbt`

## Frozen Contracts (v3.7)
- Metrics export contract: `examples/v3_7/metrics_export/expected.jsonl` + `metrics_export_v3_7/export_test.mbt`
- v3.7 metrics export endpoint: `examples/api_v3_7/metrics_export/expected.jsonl`, `examples/api_v3_7/metrics_export/expected_invalid_query.json` + `api_v3_7/api_test.mbt`

## Frozen Contracts (v3.8)
- Timeline event list query contract: `examples/v3_8/timeline_event_list/expected_cursor.json` + `timeline_event_v3_8/query_test.mbt`
- v3.8 timeline event list view: `examples/api_v3_8/timeline_event_list/expected_page*.html` + `ui/views/timeline_event_view_v3_8_test.mbt`
- v3.8 timeline event list endpoint: `examples/api_v3_8/timeline_event_list/expected_page*.html`, `examples/api_v3_8/timeline_event_list/expected_invalid_query.json` + `api_v3_8/api_test.mbt`

## Frozen Contracts (v3.9)
- Timeline event page contract: `examples/v3_9/timeline_event_page/expected.json` + `timeline_event_v3_9/page_test.mbt`
- v3.9 timeline event page view: `examples/v3_9/timeline_event_page/expected.html` + `ui/views/timeline_event_view_v3_9_test.mbt`
- v3.9 timeline event page endpoint: `examples/api_v3_9/timeline_event_page/expected*.json`, `examples/api_v3_9/timeline_event_page/expected.html` + `api_v3_9/api_test.mbt`

## Frozen Contracts (v4)
- Canonical fixtures: `examples/v4/canonical/*.json` + `canonical_v4/fixtures_test.mbt`
- v4 HTML fixtures: `examples/v4/html/*` + `ui/views/resource_view_v4_test.mbt`, `ui/views/timeline_view_v4_test.mbt`, `ui/views/timeline_detail_view_v4_test.mbt`
- v4 HTTP adapter: `examples/api_v4/**` + `api_v4/api_test.mbt`

## Frozen Contracts (v4.2)
- v4.2 metrics view: `examples/v4_2/metrics/expected*.html` + `ui/views/metrics_view_v4_2_test.mbt`
- v4.2 metrics endpoint: `examples/api_v4_2/metrics/expected*.html`, `examples/api_v4_2/metrics/expected_invalid_query.json` + `api_v4_2/api_test.mbt`

## Frozen Contracts (v4.3)
- v4.3 metrics export contract: `examples/v4_3/metrics_export/expected.jsonl`, `examples/v4_3/metrics_export/expected.csv` + `metrics_export_v4_3/export_test.mbt`
- v4.3 metrics export endpoints: `examples/api_v4_3/metrics_export/expected.jsonl`, `examples/api_v4_3/metrics_export/expected.csv`, `examples/api_v4_3/metrics_export/expected_invalid_query.json` + `api_v4_3/api_test.mbt`

## Frozen Contracts (v4.4)
- v4.4 metrics drilldown view: `examples/v4_4/metrics/expected*.html`, `examples/v4_4/metrics_detail/expected.html` + `ui/views/metrics_view_v4_4_test.mbt`, `ui/views/metrics_detail_view_v4_4_test.mbt`
- v4.4 metrics drilldown endpoints: `examples/api_v4_4/metrics/expected*.html`, `examples/api_v4_4/metrics_detail/expected.html`, `examples/api_v4_4/metrics_detail/expected_invalid_kind.json` + `api_v4_4/api_test.mbt`

## Frozen Contracts (v4.5)
- v4.5 metrics export contract: `examples/v4_5/metrics_export/expected.jsonl`, `examples/v4_5/metrics_export/expected.csv` + `metrics_export_v4_5/export_test.mbt`
- v4.5 metrics export endpoints: `examples/api_v4_5/metrics_export/expected.jsonl`, `examples/api_v4_5/metrics_export/expected.csv`, `examples/api_v4_5/metrics_export/expected_invalid_query.json` + `api_v4_5/api_test.mbt`
- v4.5 timeline export contract: `examples/v4_5/timeline_export/expected.jsonl` + `timeline_export_v4_5/export_test.mbt`
- v4.5 timeline export endpoint: `examples/api_v4_5/timeline_export/expected_page*.jsonl`, `examples/api_v4_5/timeline_export/expected_invalid_query.json`, `examples/api_v4_5/timeline_export/expected_invalid_cursor.json` + `api_v4_5/api_test.mbt`

## Frozen Contracts (v4.6)
- v4.6 export jobs endpoints: `examples/api_v4_6/**` + `api_v4_6/api_test.mbt`
