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

## 業務担当者が扱う最小概念セット（SEFRTB・対応明確化）

| 概念 | 意味（業務担当者視点） | 内部表現 |
|------|------------------------|----------|
| **State** | 今どこか | State Tag |
| **Entity** | 何を扱うか | Entity<S> |
| **Function** | 何が起こるか | Domain Update + Effect |
| **Rule** | できるか（理由つき） | Result<_, Reason> |
| **Transition** | 何をするか | 状態遷移関数 |
| **Boundary** | 誰ができるか | Role / Actor |

※ 業務担当者は「フロー全体」を定義しない  
※ 全体の状態遷移グラフ（Workflow）は  
　State / Transition 定義から **コンパイル時に自動導出**される
