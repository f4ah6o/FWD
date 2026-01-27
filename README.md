## 仮定

## レイヤー定義

L0: 前提（FP）
L1: 思想（DMMF）
L2: フレームワーク（FWD）
L3: 動作（CLI、コード）
L4: GUI
L5: ゲーミフィケーションとは、ちょっと違うけど、マジカ化 https://www.magicaland.org

## L4

### BPMNから輸入する概念
* レーン
* フロー
* アクティビティ（ゲートウェイを内包）
* イベント
* 詳細度のレベル
  * レベル 1: 同じレーンにアクティビティが並ばない
  * レベル 2: 
  * レベル 3: レーンが1つ

## Workの7つの概念`EFWRTB`

| 概念 | 問い | DMMF 対応 |
|------|------|----------|
| **Entity** | 何を扱う？ | Product Type |
| **Function** | どう変換する？ | Function |
| **Workflowlow** | どう繋がる？ | Pipeline / Composition |
| **Rule** | どう判断する？ | Decision Function |
| **Transition** | 何が許される？ | Make Illegal States Unrepresentable |
| **Boundary** | 誰と/何と接する？ | I/O at the edges |

## FWD

* FWD: Functional Work Design
* pronounced "Forward"
* Work Desing tool on Domain Model Made Functional

## keyword

* Domain Model Made Functional
* HATEOAS
