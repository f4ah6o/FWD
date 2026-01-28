## アイデア

一言で言うと：

- **FWD = Domain Modeling Made Functional の GUI 化 + 実行基盤**
- あるいは  
  **FWD = 関数型 DDD を業務担当者が触れる形にしたもの**

---

## FWD（Functional Work Design）の位置づけ

### 目的

FWD**既に確立した強力な概念を接続し、実装可能なフレームワークとして成立させること**を目的とする。

---

## 設計スタンス

- 中心に置くのは **Domain Modeling Made Functional（DMMF）**
- 既存理論（DDD / BPMN / Statecharts）をそのまま適用することは目的としない
- 優先順位：
  1. 実装可能性
  2. 業務担当者の認知負荷の低さ

---

## 実装言語

- **MoonBit**
  - Web（js / wasm）とネイティブを同一言語で扱える点を重視
  - FWD では以下を同一言語で実装する必要がある：
    - 業務モデルの検証・コンパイル
    - HATEOAS レスポンス生成
    - ブラウザ上で動作する検証・プレビュー
  - Rust は候補に近いが、FPではなく、システム寄りで UI / UX 側が弱い
  - **Gleam / Grain は Before LLM**
    - coding agent（LLM）との相性を優先して採用する

---

## REST の制約（思想的前提）

- Make Illegal States Unrepresentable
- DMMF と HATEOAS
- ハイパーメディアとドメイン駆動の統合

---

## HATEOAS 実装（HDA / mhx + tmpx）

- **HATEOAS を実現する HDA ライブラリを作成中**
- **FWD で利用することも目的の一つ**
- 構成（現時点）：
  - **mhx runtime（JS/Wasm）**
  - **mhx-spec（pure MoonBit）**
  - **tmpx（all targets）**

---

## レイヤー定義

- **L0: 前提**  
  FP（関数型プログラミング）

- **L1: 思想**  
  DMMF（Domain Model Made Functional）

- **L2: フレームワーク**  
  FWD

- **L3: 動作**  
  CLI / コード

- **L4: GUI**

- **L5: マジカ化**  
  業務を「触れるもの」にする  
  https://www.magicaland.org  
  - マジカは「カードで業務定義（洗い出し・改善）を行う」ツール
  - 内部的には **業務フローチャートを作ることと同値**
  - よって FWD では、Workflow の入力 UI（カードUI）として統合可能

---

## 基本方針

1. **非プログラマの業務担当者が、仕事を表すモデルを作る**
2. **モデルはコンパイルすることで実行可能になる**
3. **UI（統一インターフェース）はモデルから生成される**
   - HATEOAS により「今できる操作」を自己記述的に提示する
   - UI / API / 自動化で状態判定ロジックを共有する

---

## 業務モデルの中核：状態機械（DMMF / FP・レビュー反映版）

FWD における業務モデルの中核は **状態機械**である。  
ただし本設計では、一般的な状態機械ではなく、  
**Domain Modeling Made Functional（DMMF）に基づく関数型アーキテクチャ**として定義する。

目的は以下に集約される：

- 不正な業務状態を **型と関数で表現不能にする**
- 状態遷移・判断・副作用を **明確に分離する**
- 業務担当者・UI・API・LLM が同一モデルを安全に共有できること

---

### 状態機械の構成要素（FWD 文脈・確定）

#### State
- 業務の現在位置
- 同時に **1 つのみ**（FWD v1 の明示的制約）
- UI では単なる「状態名」として扱う
- 内部的には **Entity の型的文脈（State Tag）**として解釈される

> ※ 並行状態・階層状態は **FWD v1 ではサポートしない**  
> ※ 必要な場合は Entity を分割して表現する

---

#### Entity
- 業務データの主体
- 内部表現は概念的に `Entity<S>`（S は State Tag）
- 属性は型制約を持つ
- 振る舞いは持たず、遷移・制約は状態機械側に集約する

---

#### Transition
- State A → State B への状態遷移
- FWD では **1 操作 = 1 Transition** として UI / API に露出する
- 内部的には以下の純粋関数として表現される：

```
(Entity<S>, Input) -> Result<Entity<T>, Reason>
```

- UI 操作や API 呼び出しは **Transition を起動するコマンド**
- Transition は以下の合成として理解される：

```
Transition = Rule.check >> DomainUpdate.apply
```

---

#### Rule（Guard）
- 遷移が成立するかどうかを判定する条件
- 入力：
  - Entity のスナップショット
  - 遷移時 Input / Payload
- 出力：
  - `Ok`（遷移可能）
  - `Err(Reason)`（遷移不可・理由つき）
- 純関数・副作用なし
- Rule が `Err` を返した場合、Transition は実行されない
- UI では「実行可否」と「不可理由」の表示に利用される

---

#### Reason
- 遷移不可・失敗理由を表す構造化データ
- Bool ではなく **意味を持つ値**として扱う
- 例（概念）：
  - ValidationFailure
  - PermissionDenied
  - BusinessRuleViolation
  - Conflict
- UI 表示、ログ、監査、i18n に利用可能

---

#### Boundary（Role）
- 遷移を実行できる主体（Actor / Role）
- BPMN のレーンと対応
- 遷移の正当性判定ではなく、
  **「どの Transition を候補として提示するか」**を決定するために用いる
- HATEOAS により UI / API に反映される

---

#### Function（Domain Update / Effect）
- Transition の結果として「何が起こるか」を表す
- 内部的に以下を分離する：

**Domain Update**
- Entity の更新
- 状態確定
- 純粋関数
- Transition の本体に相当

**Effect**
- 通知・外部 API 呼び出し等の副作用
- 非同期処理として分離可能（Outbox / Saga 等）
- 失敗しても状態はロールバックしない

---

### 実行フロー（明示）

1. Boundary により候補 Transition を列挙
2. Rule を評価
   - `Err` → 遷移不可（理由提示）
3. Transition 実行（Domain Update）
4. Effect を発火（必要に応じて非同期）

---

## 業務担当者が扱う最小概念セット（SEFRTB）

| 概念 | 意味（業務担当者視点） | 内部表現 |
|------|------------------------|----------|
| **State** | 今どこか | State Tag |
| **Entity** | 何を扱うか | Entity<S> |
| **Function** | 何が起こるか | Domain Update + Effect |
| **Rule** | できるか（理由つき） | Result<_, Reason> |
| **Transition** | 何をするか | 状態遷移関数 |
| **Boundary** | 誰ができるか | Role / Actor |

* 全体の状態遷移グラフ（Workflow）は  
　State / Transition 定義から **コンパイル時に自動導出**される

---

## Entity 設計（DMMF 観点）

- 業務データの主体
- State を属性として保持する
- 属性は型制約を持つ
- 振る舞いは持たず、遷移・制約は状態機械側に寄せる

※ Aggregate / Repository 等の DDD 用語は導入しない

---

## Function（現実的再定義）

Function は遷移に伴って起きることを表し、2種類に分ける。

### Command（同期）
- 状態遷移と同一トランザクション
- Entity 更新・状態確定
- 失敗時は遷移自体が成立しない

### Effect（非同期）
- 通知・外部 API 等
- Eventually Consistent
- Outbox / Job / Saga 等で分離可能

---

## Rule（Guard）

- `(EntitySnapshot, Input) -> Bool` の純関数
- 業務担当者はコードを書かない
- 表現手段：
  - 条件ビルダー UI
  - 決定表（Decision Table）
- 暗黙的な外部参照は禁止

---

## Workflow（可視化と逆変換）

- Workflow は **内部正規形**
- State + Transition から自動生成される
- BPMN 風、またはレーン付きフローチャートとして可視化

### 逆変換
- 図から以下を抽出可能にする：
  - State
  - Transition
  - Boundary（Lane）
- 既存業務図・マジカとの統合を可能にする

---

## HATEOAS レスポンス（最小返却要素）

HATEOAS レスポンスは **主に UI 向け**に設計されるが、  
同一情報を **API 契約の補助情報としても利用可能**とする。

- **Entity**
- **State**
- **Actions（実行可能な Transition 群）**
  - name
  - href / method
  - role
  - inputSchema
  - uiHints（optional）

※ 固定 API（OpenAPI 等）と併存させる

---

## L5: マジカとの統合

- マジカはカードで業務を洗い出すツール
- 内部的には業務フローチャートと同値
- FWD では：
  - Workflow 入力 UI の一形態として位置づける
  - カード → 図 → SEFRTB → コンパイル
  の流れを作る

---

## FWD の設計要点まとめ

- 業務モデルの中心は **状態機械**
- 正しさを人に委ねない
- フローは導出されるもの
- 局所的な正しさから全体を導出する
- Make Illegal States Unrepresentable を
  - モデル構造
  - コンパイル
  - UI/HATEOAS
  の三層で保証する