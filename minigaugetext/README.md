## Release Note.

## v1.1.1

### 変更内容

- HP/SPでカラーを個別設定可能に

### 何をするもの？

キャラクター下のHP/SPバー上下に現在値と最大値を表示します。

### どうすれば？

ipfファイルをインストールして、addons/minigaugetext/settings.txt を用意します。

settings.txt
```lua
local s = {}
---
s['size'] = 13            -- 自キャラフォントサイズ
s['color'] = '#FFFFFF'    -- 自キャラHPフォントカラー
s['spcolor'] = '#FFFFFF'    -- 自キャラSPフォントカラー
s['ptsize'] = 12          -- PTメンバーフォントサイズ
s['ptcolor'] = '#CCCCCC'  -- PTメンバーHPフォントカラー
s['ptspcolor'] = '#CCCCCC'  -- PTメンバーSPフォントカラー
---
return s
```

- size / ptsize

フォントサイズを変更します。最大値はだいたい20くらいで見切れてくると思います。
デフォルトは11です。

- color / ptcolor / spcolor / ptspcolor

フォントカラーを変更します。「# + RGB」の形式です。
デフォルトは #FFFFFF です。（白）

### いつ動くの？

- HP/SPに変化があったとき。

### 注意事項

ないよ！

###

[http://www.weizlogy.gq/tos/addon/minigaugetext/](http://www.weizlogy.gq/tos/addon/minigaugetext/)