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
