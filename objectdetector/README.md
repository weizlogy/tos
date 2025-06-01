## settings.

Nexon\TreeofSaviorJP\addons\objectdetector\settings.txt を作成します。

以下の初期設定を[settings.txt](https://github.com/weizlogy/tos/blob/master/objectdetector/settings.txt)にコピペします。

```lua
-- for monster and npcs.
obde.config.mon = {
  color = "FF000000",
  isVisible = 1
};
obde.config.mon.Monster = {
  color = "FF660000",
  isVisible = 1
};
obde.config.mon.Monster_Chaos1 = obde.config.mon.Monster;
obde.config.mon.Monster_Chaos2 = obde.config.mon.Monster;

obde.config.mon.Pet = {
  isVisible = 0
};
obde.config.mon.RootCrystal = {
  color = "FF330033",
  isVisible = 1
};
obde.config.mon.Neutral = {
  color = "FFFF9900",
  isVisible = 1,
};
obde.config.mon.Peaceful = obde.config.mon.Neutral;
obde.config.mon.Our_Forces = obde.config.mon.Neutral;
obde.config.mon.Hidden_tgt = obde.config.mon.Neutral;

-- for players.
obde.config.pc = {
  color = "FF0000FF",
  isVisible = 1
};

-- for dropitems.
obde.config.item = {
  color = "FF999999",
  isVisible = 1
};

-- for treasures.
obde.config.treasure = {
  color = "FFFF9900",
  isVisible = 1,
  isBlink = 1
};

-- for clover buffs.
obde.config.clover = {
  color = "FF330000",
  isVisible = 1,
  isBlink = 1
};

obde.config.clover.EliteMonsterBuff = {
  color = "FFFF3333",
  isVisible = 1
};
```

### explanation.

#### params

##### color

アイコン色をARGBで指定します。

Aは（実装の関係上）FF推奨です。
透明に近づけると黒くなっていきます。

##### isVisible

アイコンの表示を制御します。
1を指定した場合のみ表示します。

##### isBlink

アイコンの点滅を制御します。
1を指定した場合のみ点滅します。

本設定は[obde.config.mon]以下のみ有効です。

#### obde.config.mon

モンスターやNPCなどほぼ全てのオブジェクトの基本設定です。

後述のfaction指定設定にない場合、本設定が有効となります。

##### obde.config.mon.[faction]

オブジェクトのfaction属性毎に用意する設定です。
factionはアイコンのツールチップ[f=]で確認できます。

#### obde.config.pc

他PCの基本設定です。

#### obde.config.item

ドロップアイテムの基本設定です。

#### obde.config.treasure

宝箱の基本設定です。

#### obde.config.clover

クローバーバフ持ちの基本設定です。

後述のclassname指定設定にない場合、本設定が有効となります。

##### obde.config.clover.[classname]

クローバーバフのclassname毎に用意する設定です。
classnameはアイコンのツールチップ[b=]で確認できます。

### explanation of initial parameters.

| 色 | オブジェクト |
|:---|:---|
|赤|モンスター|
|赤点滅|クローバーバフモンスター（エリートは除く）|
|桃|エリートクローバーバフモンスター|
|青|PC|
|橙|NPC|
|橙点滅|宝箱|
|紫|ルーツクリスタル|
|白|ドロップアイテム|
|黒|その他|
|非表示|ペット|

## descriptions.

### v1.3.1

#### PVPマップ動作停止対応

PVPマップでは動きません。

### v1.3.0

#### ボス系サイズ拡大対応

ボス系のドットが通常より大きく表示されます。

### v1.2.0

#### 検索機能追加

チャットコマンドにて、「/detector search xxx」とすると、xxxに完全一致する名前を持つオブジェクトを探して点滅させます。

#### オブジェクトサイズ反映対応

マップに表示するドットがオブジェクトのサイズに応じて変化します。

### v1.1.0

#### アイコン表示処理の設定ファイル化

アイコンの表示、配色、点滅を設定ファイルでカスタマイズできるようにしました。

設定ファイルがないと動かないので注意してください。

### v1.0.1

#### 性能改善

### v1.0.0

#### 新規作成

アドオンがロードされると、マップとミニマップに四角形のアイコン[*1]が表示されます。

[*1] アイコン配色とオブジェクトの関係は以下の通りです。

| 色 | オブジェクト |
|:---|:---|
|赤|モンスター|
|赤点滅|クローバーバフモンスター|
|青|PC|
|橙|NPC|
|橙点滅|宝箱|
|紫|ルーツクリスタル|
|白|ドロップアイテム|
|黒|その他|
|非表示|ペット|

某レーダーと違いマップにオーバーレイせず直接描画しているため、既存UIの邪魔をしません。
