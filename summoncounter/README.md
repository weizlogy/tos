see [https://blog.weizlogy.com/pages/tos-addon/#summoncounter](https://blog.weizlogy.com/pages/tos-addon/#summoncounter)

## settings.

Nexon\TreeofSaviorJP\addons\summoncounter\settings.txt を作成します。

以下の初期設定を[settings.txt](https://github.com/weizlogy/tos/blob/master/summoncounter/settings.txt)コピペします。

```lua
suco.config = {
  Bokor_Zombify = {
    mode = "hpbar",
    loc_frame = { x = 450, y = 80 },
    loc_bar = { x = 0, y = 0 }
  },
  Necromancer_RaiseDead = {
    mode = "icon1",
    loc  = "left",
    loc1 = { x = 0, y = 30 },
    loc2 = { x = 0, y = 70 },
    loc3 = { x = 0, y = 110 },
    loc4 = { x = -40, y = 50 },
    loc5 = { x = -40, y = 90 }
  },
  Necromancer_RaiseSkullarcher = {
    mode = "icon1",
    loc  = "right",
    loc1 = { x = 0, y = 30 },
    loc2 = { x = 0, y = 70 },
    loc3 = { x = 0, y = 110 },
    loc4 = { x = 40, y = 50 },
    loc5 = { x = 40, y = 90 }
  },
  Necromancer_CreateShoggoth = {
    mode = "icon2",
    loc  = "down",
    loc1 = { x = 0, y = 0 }
  }
};
```

### explanation.

この設定は召喚物発生スキルごとのアイコン表示設定です。

#### mode

##### icon1

髑髏アイコン（小）を表示します。

locはleft（キャラ左）,right（キャラ右）が指定できます。

loc＋数字は召喚物ごとの相対的なアイコン表示位置を指定します。

##### icon2

魔法陣アイコン（大）を表示します。

locはup（キャラ上）,down（キャラ下）が指定できます。

loc＋数字は召喚物ごとの相対的なアイコン表示位置を指定します。

##### hpbar

紫色のHPバーを表示します。

HPバーは召喚物のHP合計とMaxHPの合計で構成されます。
つまり、HPが0になると召喚物は全て消滅したということになります。

loc_frameはHPバーを表示するフレームの表示位置です。
HPバーを複数用意する場合はすべて同じ位置で統一してください。

loc_barはHPバーの表示位置をloc_frameからの相対位置で示します。

### explanation of initial parameters.

#### Bokor_Zombify

ボコルのゾンビフィーはHPバーで画面左上のスタミナゲージ右近辺に表示します。
ゾンビがいない場合はHPバーは消えます。

#### Necromancer_RaiseDead

ネクロマンサーの骸骨兵は髑髏アイコンでキャラ左に表示します。

#### Necromancer_RaiseSkullarcher

ネクロマンサーの骸骨弓兵は髑髏アイコンでキャラ右に表示します。

#### Necromancer_CreateShoggoth

ネクロマンサーのショゴスは魔法陣アイコンでキャラ下に表示します。

## descriptions.

### v1.0.4

#### 6/27アップデート対応

### v1.0.3

#### ジョイスティック対応

ジョイスティック使用時に動かない問題を修正しました。

### v1.0.2

#### オブジェクトクリック阻害修正

マウスモード時、召喚アイコン周辺にあるオブジェクトがクリックできない問題を修正しました。

### v1.0.1

#### ショゴス召喚最大値修正

ショゴスの召喚最大値がスキルレベルになっていたのを1固定に修正しました。

#### 設定ファイルリロード機能追加

チャットコマンドで設定ファイルをリロードできるようになります。

```lua
/summonc reload
```

### v1.0.0

#### 新規作成

アドオンがロードされると、クイックスロットにセットしている召喚系スキルスロット右上に、召喚数/最大値を追加で表示します。

さらに設定をすることで召喚物の状態をGUIで表示します。
GUI表示が不要な場合は、各設定のmodeを空文字にしてください。

## cautions.

- エリアチェンジ、ログイン直後で既に存在する召喚物はカウントできません。
- ゾンビカプセル産のゾンビはカウントできません。
- コープスタワー特性産の骸骨兵士はカウントできません。
