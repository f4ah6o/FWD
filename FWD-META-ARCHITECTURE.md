# FWD メタアーキテクチャ：自己記述とコンパイルパイプライン（再レビュー反映・v1確定）

## 設計原則（不変）

FWD は **自己言及可能なメタフレームワーク**として設計される。

- FWD のスキーマ定義自体が **FWD の状態機械（L0）で記述**される
- 具体ドメインモデルは FWD 定義から **コンパイル（導出）**される
- フレームワーク自身の進化も **型安全・Reason付き**で管理される


---

## レイヤ構造（L0 / L1 / L2）

┌─────────────────────────────────────────────┐
│  L0: FWD Core（プリミティブ・固定点）      │
└─────────────────────────────────────────────┘
                    ↓ bootstrap
┌─────────────────────────────────────────────┐
│  L1: FWD Schema（メタモデル・自己記述）    │
└─────────────────────────────────────────────┘
                    ↓ compile
┌─────────────────────────────────────────────┐
│  L2: Domain Model（ユーザー定義）           │
└─────────────────────────────────────────────┘


---

## 1. L0 / L1 境界の明示（確定）

| 概念 | L0（プリミティブ） | L1（メタモデル） |
|---|---|---|
| State | `StateTag`（識別子型） | `StateDefinition` |
| Entity | `Entity<S>` 型コンストラクタ | `EntityDefinition` |
| Transition | 関数シグネチャ | `TransitionDefinition` |
| Rule | `(E, I) -> Result<void, Reason>` | `RuleDefinition + RuleExpression` |
| Reason | `{ code, message, context }` | `ReasonDefinition（コード体系）` |
| Boundary | Role / Actor 型 | `BoundaryDefinition` |

- **L0 は意味論のみ**を提供（凍結・自己記述しない）
- **L1 は構造と制約**を定義（自己記述対象）
- この分離により無限後退を回避する


---

## 2. RuleExpression の定義（v1確定）

v1 では **二層構え**とする。

### 2.1 宣言的プリセット（標準）

- あらかじめ定義された Rule 群を参照
- 検証可能・可視化可能・移植可能

```yaml
rules:
  - type: hasAtLeastOneState
  - type: allReferencesResolved
  - type: noBreakingChanges
```

対応する L0 実装は **純粋関数**。

### 2.2 Escape Hatch（実装関数）

- 宣言的ルールで表現不能な場合のみ使用
- v1 では **MoonBit 関数参照**に限定
- スキーマ上は「不透明な Rule」として扱う

```yaml
rules:
  - type: custom
    impl: schemaRules::checkMigrationCompleteness
```

#### 設計判断
- v1で汎用式言語（CEL等）は導入しない
- 表現力と実装コストのバランスを優先
- v2以降で DSL / 式言語を検討可能


---

## 3. L1: FWD Schema の状態機械（自己記述の実体）

### SchemaState

```yaml
states:
  - Draft
  - Reviewing
  - Released
  - Deprecated
```

### Schema Transitions（確定例）

```yaml
transitions:
  - name: submitForReview
    from: Draft
    to: Reviewing
    rules:
      - hasAtLeastOneState
      - hasAtLeastOneTransition
      - allReferencesResolved

  - name: approve
    from: Reviewing
    to: Released
    rules:
      - noBreakingChangesOrMigrationDefined

  - name: deprecate
    from: Released
    to: Deprecated
    effects:
      - notifyDependentSchemas
```

- **L1 自身が FWD の管理対象**
- スキーマ変更はすべて Transition として記録される


---

## 4. コンパイルパイプライン（v1）

### ステージ

1. Parse  
2. Resolve  
3. Validate（L1準拠・Reason付き）
4. Normalize  
5. Infer（任意）
6. Emit  
7. Package  

v1 実装では **Parse → Validate → Emit** から開始可能。


---

## 5. FWD-IR 定義（具体化）

### DirectedGraph（自前定義）

```ts
type DirectedGraph<N, E> = {
  nodes: Set<N>
  edges: Map<N, Map<N, E>>  // from -> to -> edge
}
```

### FWD-IR（v1）

```ts
type FwdIR = {
  version: string          // IR version
  fwdVersion: string       // L0 dependency

  stateGraph: DirectedGraph<StateTag, TransitionRef>

  entities: Map<string, NormalizedEntity>
  transitions: Map<string, NormalizedTransition>
  rules: Map<string, CompiledRule>
  reasons: Map<string, ReasonSpec>
  effects: Map<string, EffectSpec>
}
```

- IR は **後方互換前提**
- 正規形 Transition:

```
(Entity<S>, Input) -> Result<Entity<T>, Reason>
```


---

## 6. バージョニング戦略（確定）

### L0（Core）
- SemVer
- 破壊的変更はメジャーのみ

### L1 / L2
- スキーマ先頭で依存宣言必須

```yaml
fwdVersion: "1.0"
schemaVersion: "1.2"
```

- L0 破壊的変更時は **Migration Transition** を L1 に定義


---

## 7. Effect の v1 スコープ（確定）

| Effect種別 | v1対応 | 実装方式 |
|---|---|---|
| 同期Effect | ○ | Transition後に即時実行 |
| 非同期Effect | △ | Outbox + ポーリング |
| Saga | × | v2以降 |

- Effect 失敗でも **状態はロールバックしない**


---

## 8. 結論（表現調整）

FWD は

> **業務モデル・スキーマ・その進化を  
> 同一の状態機械原理で扱うための基盤**

である。

具体的には：

- **スキーマ変更のレビュー・承認**が Transition
- **互換性違反**が Reason として可視化
- **移行手順**が Effect として分離される

この構造により、  
フレームワーク自身と業務ドメインの進化が  
**同じ型・同じ検証原理で管理可能**になる。

---

## Bootstrap Strategy (v1)

本章は、FWD の自己記述（L1 を L0 上で運用し、以後の進化を型安全に管理する）を成立させるための **root of trust** と **初回コンパイル手順**、および **以後の変更正当化ルール**を明文化する。

### 目的
- 「最初の L1 スキーマ YAML は誰が/どう信頼するか」を明確化する
- 「その YAML をどう検証・固定するか（golden IR の扱い）」を定義する
- 「以後の変更をどう正当化するか（Transition とルール運用）」を規定する

---

### 1) Seed Artifact（Root of Trust）

#### Seed の定義
- `schema/fwd_schema.yaml` を **手書きの Seed Artifact** として用意する。
- Seed は **L1 スキーマそのもの**（FWD の書き方）を表現する最初の入力である。

#### Root of Trust
- Seed の信頼は、以下の2点により成立する：
  1. **L0 実装（固定点）**が提供する validator によって検証されること
  2. Seed がリポジトリにコミットされ、レビュー・署名（運用）により保護されること

> v1 では Seed は「自己記述で生成される」のではなく、自己記述を開始するための **初期値**として扱う。

---

### 2) Seed Validation（初回検証）

Seed は `fwdc validate` により検証される。

- 成功：`ok`（exit code 0）
- 失敗：Reason を表示し、exit code 1

Seed Validation の責務（v1最小）：
- 必須フィールド（`fwdVersion` / `schemaVersion` 等）の存在
- 重複（state / transition / rule / effect 等）の検出
- 参照整合性（transition の from/to、rule/effect 参照、entity 初期 state 等）

L1との一貫性確保のためのRule名
```
rules:
  - hasRequiredFields
  - noDuplicateDefinitions
  - allReferencesResolved
```

---

### 3) First Compile（初回コンパイル）

初回検証に成功した Seed から、初回の IR を生成する。

- 入力：`schema/fwd_schema.yaml`
- 実行：`fwdc compile schema/fwd_schema.yaml schema/fwd_schema.ir.json`
- 出力：`schema/fwd_schema.ir.json`

この IR は **Seed の機械可読な固定結果**であり、以後の golden として扱う。

---

### 4) Golden Check（固定と差分レビュー）

#### Golden Artifact
- `schema/fwd_schema.ir.json` を **Golden Artifact** としてリポジトリにコミットする。

#### Golden Check の規則
- 以後の変更では、CI で常に以下を実行する：
  - `fwdc compile schema/fwd_schema.yaml` の出力 IR
  - committed な `schema/fwd_schema.ir.json`
  - 両者を **完全一致**で比較する（差分があれば失敗）

#### 例外（Golden Update）
- `schema/fwd_schema.ir.json` の更新は許可されるが、必ず以下を満たす：
  - 差分が PR 上でレビュー可能な形で提示される
  - 変更理由が Change Policy（後述）により正当化されている

> v1 の golden は「正しさの証明」ではなく、**root of trust の固定点を破壊しないための検知装置**である。

---

### 5) Change Policy（正当化：Transition による変更管理）

L1 スキーマ変更は「編集」ではなく、**状態遷移（Transition）としてのみ正当化**される。

#### L1 SchemaState（運用状態）
- `Draft`
- `Reviewing`
- `Released`
- `Deprecated`

#### 許可される遷移（例）
- `submitForReview`: Draft → Reviewing
- `approve`: Reviewing → Released
- `deprecate`: Released → Deprecated

#### 運用規則（v1）
- `Released` なスキーマは、直接編集しない
- 変更は必ず Draft として提案され、Reviewing を経て Released に至る
- レビューでは Rule/Reason により以下を判定する：
  - 参照整合性（Resolve/Validate）
  - 破壊的変更の有無
  - 移行手順（Migration/Effect）の提示有無（v1では最小要件）

> 変更の正当化は「人の判断」ではなく、**Rule による判定と Reason による説明可能性**を前提とする。

---

### 6) まとめ（v1の自己記述成立条件）

v1 における自己記述の成立は、次の条件で定義する：

- Seed（`schema/fwd_schema.yaml`）が存在する
- Seed が L0 validator で検証可能である
- Seed から IR を生成できる（First Compile）
- 生成 IR が golden として固定され、差分がレビュー対象になる（Golden Check）
- L1 の変更が Transition とルール運用により正当化される（Change Policy）

この時点で「FWD が FWD を処理できる」ための **bootstrap が完了**している。


---

## 次の実装ステップ（推奨）

1. **L0 Core の最小実装（MoonBit）**
2. **L1 スキーマを YAML / MoonBit 定義で記述**
3. **最小コンパイラ（Parse → Validate → Emit）**
4. 「FWD が FWD を処理できる」ことを実証

→ ここまでで **自己記述が実際に動く**。
