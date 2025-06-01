see [https://blog.weizlogy.com/pages/tos-addon/#slotmac](https://blog.weizlogy.com/pages/tos-addon/#slotmac)

## settings.

Nexon\TreeofSaviorJP\addons\slotmac フォルダーを作成します。

slotmac フォルダー配下に自キャラの[cid]のフォルダーを作成します。

操作中のキャラクターのcidが不明な場合は、F3キーで[スキルと特性]ダイアログを開き、右下の[slmc]Reloadボタンを右クリックしてください。

slotmac フォルダー配下に操作キャラの[cid]のファイルが作成されますので、コピー > ファイル削除 > 新しいフォルダー作成 > フォルダー名変更 > ペースト　としてください。

## descriptions.

### v1.3.0

#### ターゲット情報タグ追加

ターゲット中の敵に関する情報を表示するタグを追加しました。

詳細はマクロタグ一覧参照。

#### 自キャラ情報タグ追加

自キャラに関する情報を表示するタグを追加しました。

詳細はマクロタグ一覧参照。

#### スロット情報タグ追加

マクロを実行したスロットに関する情報を表示するタグを追加しました。

詳細はマクロタグ一覧参照。

### v1.2.0

#### オーバーヒート対応

オーバーヒートのあるスキルでは、通常マクロファイルに加えてオーバーヒート用のマクロファイルを
用意できるようになりました。

例えばオーバーヒート3のスキルでは、以下のようになります。
```
初撃 => オーバーヒート用マクロファイル
二撃 => オーバーヒート用マクロファイル
三撃 => 通常マクロファイル
```

オーバーヒート用マクロファイルがない場合は、
マクロファイルのない通常動作（スキル発動のみ）となります。

オーバーヒート用マクロファイルの詳細はusage参照。

### v1.1.0

#### equipコマンド追加

equipコマンドにより、クイックスロット実行に合わせて装備を変更できます。

詳細はマクロコマンド一覧参照。

#### unequipコマンド追加

unequipコマンドにより、クイックスロット実行に合わせて装備を外せます。

詳細はマクロコマンド一覧参照。

### v1.0.0

#### 新規作成

アドオンがロードされると、クイックスロットにセットしたスキルやアイテムを実行時に指定したマクロを実行できるようになります。

また、[スキルと特性]ダイアログの右下の[slmc]Reloadボタンが追加されます。左クリックでマクロを再読み込みします。

## usage.

### マクロファイル作成

キーボード、マウスモードの場合、クイックスロットは左下が1、右上が40となります。(ジョイスティックは...？)

cidフォルダー配下に、必要に応じてマクロファイル(slot1.txt ～ slot40.txt)を**UTF8-BOM無**で作成します。
マクロファイルがない場合は、今まで通りスロットにセットされたものを実行します。

UTF8-BOM無がよく分からない人は、下記テンプレートをダウンロードして使ってください。

[slotN.txt](https://github.com/weizlogy/tos/releases/download/slotmac-v1.0.0/slotN.txt)

slot1.txtなら、[A]キーに割り当てのクイックスロットという感じです。

**マクロは一行に一コマンドとなります。**

### オーバーヒート用マクロファイル

オーバーヒートのあるスキルでは、通常マクロファイルに加えてオーバーヒート用のマクロファイルを
用意できます。

オーバーヒート用のマクロファイルの命名規則は以下の通りです。
```
slot1-oh.txt ～ slot40-oh.txt
```

### マクロコマンド一覧

#### クイックスロット呼び出し

自身または他のクイックスロットを呼び出します。

```lua
#skill# 0  -- 操作したクイックスロット自身を実行する。
#skill# 10 -- 10番目のクイックスロット(つまり[;]キー割り当てのもの)を実行する。
```

#### チャットコマンド

[/]から始まるチャットコマンドはすべて使用可能です。

```lua
/s test -- 一般チャットで[test]と発言する。
/p test -- PTチャットで[test]と発言する。
/indun  -- インスタンスダンジョンダイアログを呼び出す。
e.t.c...
```

#### エコー

systemチャットで自分にしか見えない発言ができます。

```lua
#system# test -- systemチャット[test]と発言する。
```

#### ポーズ

任意のポーズができます。

```lua
#pose# LOVE -- [ラブ]のポーズをする。
```

ポーズはクラス名を指定します。
data\ies.ipf\pose.ies に載っていますが、以下に抜粋しておきます。

```
ClassName
--
LOVE
WIN
BEST
FOLLOW
HELP
HELLO
NO
SORRY
THANKS
YES
BOW1
BOW2
CLENCHFIST
DOUBLEGUNS
HADOUKEN
SURPRISE
CRYING
BIRDPOSE
OUTCAST
QUESTION
CRAP
JUMPING
CUTE
HULAHULA
IDK
NONO
OUCH
POPCORN
JIANGSHI
CHEERS
OTL
POLLEN
THANKS2
DANCE
KICK
```

#### タイマー

クイックスロット実行後一定時間経過で任意のマクロコマンドを呼び出します。

```lua
#timer# 3 #pose# LOVE -- クイックスロット実行後3秒経過で[ラブ]のポーズをする。
```

タイマーは複数張れますが、全て[クイックスロット実行後一定時間経過]換算で、waitではありません。[#timer# 3 xxx]を二行書いても、xxxが3秒後同時に行われることになります。

#### 装備

指定部位の装備を、指定した装備に変更します。

```lua
#equip# RH ターネットソード -- メインウエポンをターネットソードにする。
#timer# 1 #skill# 0 -- クイックスロット実行1秒後、スロットスキルを実行する。
#timer# 2 #equip# RH フィフスハンマー -- クイックスロット実行2秒後、メインウエポンをフィフスハンマーにする。
```

装備変更には少々時間がかかるため、その後のスキル実行はタイマーで調整してください。

装備部位は以下の通りです。

```
HAT
HAT_L
HAIR
SHIRT
GLOVES
BOOTS
HELMET
ARMBAND
RH
LH
OUTER
OUTERADD1
OUTERADD2
BODY
PANTS
PANTSADD1
PANTSADD2
RING1
RING2
NECK
HAT_T
LENDS
```

#### 装備解除

指定部位の装備を外します。

```lua
#unequip# RH -- メインウエポンを外す。
```

### マクロタグ一覧

#### エモティコン

チャットコマンドやエコーでエモティコンを表示できます。

```lua
/s <emoticon_0009> -- 一般チャット[脱力エモ]と発言する。
```

エモティコンはクラス名で指定します。
data\jp.ipf\xml\chat_emoticons.xml に載っていますが、以下に抜粋しておきます。

```xml
<Class ClassID="1"  ClassName="emoticon_0001" IconTokken="幸せ"/>
<Class ClassID="2"  ClassName="emoticon_0002" IconTokken="ケッピー好き"/>
<Class ClassID="3"  ClassName="emoticon_0003" IconTokken="ケッピー泣く"/>
<Class ClassID="4"  ClassName="emoticon_0004" IconTokken="コラッ"/>
<Class ClassID="5"  ClassName="emoticon_0005" IconTokken="怒り"/>
<Class ClassID="6"  ClassName="emoticon_0006" IconTokken="満足"/>
<Class ClassID="7"  ClassName="emoticon_0007" IconTokken="コンパ"/>
<Class ClassID="8"  ClassName="emoticon_0008" IconTokken="笑み"/>
<Class ClassID="9"  ClassName="emoticon_0009" IconTokken="脱力"/>
<Class ClassID="10" ClassName="emoticon_0010" IconTokken="えっ！"/>
<Class ClassID="11" ClassName="emoticon_0011" IconTokken="えっ!!!"/>
<Class ClassID="12" ClassName="emoticon_0012" IconTokken="おえっ"/>
<Class ClassID="13" ClassName="emoticon_0013" IconTokken="イケイケ"/>
<Class ClassID="14" ClassName="emoticon_0014" IconTokken="怒り"/>
<Class ClassID="15" ClassName="emoticon_0015" IconTokken="爆破"/>
<Class ClassID="16" ClassName="emoticon_0016" IconTokken="悲しみ"/>
<Class ClassID="17" ClassName="emoticon_0017" IconTokken="左"/>
<Class ClassID="18" ClassName="emoticon_0018" IconTokken="右"/>
<Class ClassID="19" ClassName="emoticon_0019" IconTokken="狙い"/>
<Class ClassID="20" ClassName="emoticon_0020" IconTokken="王子"/>
<Class ClassID="21" ClassName="emoticon_0021" IconTokken="疲れた"/>
<Class ClassID="22" ClassName="emoticon_0022" IconTokken="ダラッ"/>
<Class ClassID="23" ClassName="emoticon_0023" IconTokken="キャーッ"/>
<Class ClassID="24" ClassName="emoticon_0024" IconTokken="hi"/>
<Class ClassID="25" ClassName="emoticon_0025" IconTokken="bye"/>
<Class ClassID="26" ClassName="emoticon_0026" IconTokken="ok"/>
<Class ClassID="27" ClassName="emoticon_0027" IconTokken="gg"/>
<Class ClassID="28" ClassName="emoticon_0028" IconTokken="暑い"/>
<Class ClassID="29" ClassName="emoticon_0029" IconTokken="寒い"/>
<Class ClassID="30" ClassName="emoticon_0030" IconTokken="頑張れ1"/>
<Class ClassID="31" ClassName="emoticon_0031" IconTokken="頑張れ2"/>
<Class ClassID="32" ClassName="emoticon_0032" IconTokken="お腹すいた1"/>
<Class ClassID="33" ClassName="emoticon_0033" IconTokken="お腹いっぱい"/>
<Class ClassID="34" ClassName="emoticon_0034" IconTokken="えっへん"/>
<Class ClassID="35" ClassName="emoticon_0035" IconTokken="感謝"/>
<Class ClassID="36" ClassName="emoticon_0036" IconTokken="はて？"/>
<Class ClassID="37" ClassName="emoticon_0037" IconTokken="おやすみ"/>
<Class ClassID="38" ClassName="emoticon_0038" IconTokken="オッケー"/>
<Class ClassID="39" ClassName="emoticon_0039" IconTokken="やだ1"/>
<Class ClassID="40" ClassName="emoticon_0040" IconTokken="やだ2"/>
<Class ClassID="41" ClassName="emoticon_0041" IconTokken="愛してる"/>
<Class ClassID="42" ClassName="emoticon_0042" IconTokken="眠い"/>
<Class ClassID="43" ClassName="emoticon_0043" IconTokken="お腹すいた2"/>
<Class ClassID="44" ClassName="emoticon_0044" IconTokken="痛い"/>
<Class ClassID="45" ClassName="emoticon_0045" IconTokken="ごめん"/>
<Class ClassID="46" ClassName="emoticon_0046" IconTokken="グッドラック"/>
```

#### ターゲット情報

ターゲット中の敵の名前やステータスを表示できます。

```lua
/s <t> 発見！ -- 一般チャットで[ターゲット名称] 発見！と発言する。
/s <thp>(<thpp>) -- 一般チャットで[ターゲット残HP(残HP%)]と発言する。
```

#### 自キャラ情報

自キャラの名前やステータスを表示できます。

```lua
/s <me> -- 一般チャットで[自キャラ名 自チーム名]と発言する。
/s <mec> -- 一般チャットで[自キャラ名]と発言する。
/s <met> -- 一般チャットで[自チーム名]と発言する。
/s <hp>(<hpp>) -- 一般チャットで[自キャラ残HP(残HP%)]と発言する。
/s <sp>(<spp>) -- 一般チャットで[自キャラ残HP(残HP%)]と発言する。
/s <pos> -- 一般チャットで[自キャラ座標(x,y,z)]と発言する。
```

#### スロット情報

マクロ実行スロットスキル/アイテムの名前やクールダウンタイムを表示できます。

```lua
/s <sn> recast in <scdt> sec. -- 一般チャットで[スロットスキル/アイテム名 recast in [スロットスキル/アイテムクールダウンタイム] sec.]と発言する。
```

## cautions.

マクロファイルがUTF8-BOM付の場合、BOMが邪魔で一行目のマクロが認識されません。UTF8以外(MS932など)は、全マクロが認識できません。

連打するようなクイックスロットにはマクロつけても。。。
