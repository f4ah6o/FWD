## アイデア

一言で言うと：

- **FWD = Domain Modeling Made Functional の GUI 化 + 実行基盤**
- あるいは  
  **FWD = 関数型 DDD を業務担当者が触れる形にしたもの**

---

## FWD（Functional Work Design）の位置づけ

### 目的

FWD は思想文ではなく、  
**既に確立した強力な概念を接続し、実装可能なフレームワークとして成立させること**を目的とする。

---

## 実装言語

- **MoonBit**
  - Web（js/wasm）を含む **マルチランタイム**を前提にできる言語の不在を埋める存在
  - Rust は候補に近いが、システムプログラミング向き

---

## REST の制約（思想的前提）

- Make Illegal States Unrepresentable
- DMMF と HATEOAS
- ハイパーメディアとドメイン駆動のインターフェース

---

## HATEOAS 実装（HDA / mhx + tmpx）

- **HATEOAS を実現する HDA ライブラリを作成中**
- **FWD で利用することも目的の一つ**
- 構成（現時点の方向性）
  - **mhx runtime（JS/Wasm）**：ブラウザ側で `mx-*` 属性を解釈・実行するランタイム
  - **mhx-spec（pure MoonBit）**：trigger/swap/sync/selector 等の型付き定義＋パーサ（単一ソース）
  - **tmpx（all targets）**：サーバ側 HTML DSL。mhx-spec の型を一級に扱い、mhx 互換 HTML を生成する
- 期待する開発体験
  - アプリの主要ロジックを **MoonBit だけで完結**
  - JS は「mhx runtime の配布・実行」のために存在し、アプリ固有 JS を極力不要にする
  - htmx 相当の実用機能をまず揃えた上で、MoonBit 由来の拡張（型安全トリガ等）を追加する

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
  ゲーミフィケーションとは少し違うが、  
  業務を「触れるもの」にする  
  https://www.magicaland.org

---

## 基本方針（ここまでで合意できた点）

1. **非プログラマの業務担当者が、仕事を表すモデルを作るためのフレームワークである**
   - 業務担当者はコードを書かない
   - 正しさは人に期待せず、モデルと制約で担保する
   - BPMN / DMMF / EFWRTB は内部の正規形・語彙として用いる

2. **モデルはコンパイルすることで実行可能になる**
   - モデルは単なるデータではなく「プログラム」とみなす
   - コンパイルは以下を含む：
     - 検証
     - 正規化
     - 制約付与
     - 実行形式への変換
   - Make Illegal States Unrepresentable はコンパイル規則として扱う
   - 不正な業務状態は実行時ではなく定義時（コンパイル時）に失敗させる

3. **UI（統一インターフェース）はモデルから生成される**
   - UI を自由設計させない
   - モデルが「今できる操作」「次に許される遷移」を規定する
   - 実行時 UI はモデルが自己記述的に説明する
   - HATEOAS は UI 契約として機能する
   - この HATEOAS/UI 契約の実装基盤として **HDA（mhx/tmpx）** を利用する

---

## L4: GUI に持ち込む BPMN の概念

### 構成要素

- レーン
- フロー
- アクティビティ（ゲートウェイを内包）
- イベント

### 詳細度のレベル

- **レベル 1**  
  同じレーンにアクティビティが並ばない

- **レベル 2**  
  （※後で定義）

- **レベル 3**  
  レーンが 1 つ

---

## Work の 7 つの概念（EFWRTB）

| 概念 | 問い | DMMF 対応 |
|------|------|----------|
| **Entity** | 何を扱う？ | Product Type |
| **Function** | どう変換する？ | Function |
| **Workflow** | どう繋がる？ | Pipeline / Composition |
| **Rule** | どう判断する？ | Decision Function |
| **Transition** | 何が許される？ | Make Illegal States Unrepresentable |
| **Boundary** | 誰と / 何と接する？ | I/O at the edges |

---

## FWD の役割整理

- 業務担当者に対して：
  - 制約付きで業務モデルを定義させるフレームワーク

- システムに対して：
  - 実行可能で破綻しない形にモデルをコンパイルするフレームワーク

---

## 既存概念との接続（整理）

| 概念 | FWD における役割 |
|------|------------------|
| FP | 制約・合成の基盤 |
| DMMF | モデルの正規形 |
| Make Illegal States Unrepresentable | コンパイル規則 |
| BPMN | 業務構造の語彙（ユーザーには直接見せない） |
| HATEOAS | 実行時 UI / API の契約（HDA で具現化） |
| EFWRTB | Work モデルの最小構成単位 |
| GUI | モデル編集器 |
| 実行基盤 | コンパイル成果物のランタイム（Web/JS/Wasm/Native） |
| HDA（mhx/tmpx） | HATEOAS/UI 契約の実装・配布・型安全化 |

---

## FWD

- **FWD: Functional Work Design**
- pronounced **"Forward"**
- Work Design tool on **Domain Model Made Functional**

---

## Keywords

- Domain Model Made Functional
- HATEOAS

---

## 現時点で未決定（意図的に保留）

- コンパイル成果物の正体
  - 状態機械
  - API 定義
  - UI スキーマ
  - もしくはそれらの組み合わせ
