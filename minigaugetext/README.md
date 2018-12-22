## Release Note.

## v1.1.0

### 変更内容

- フォントサイズ、カラーを設定可能に
- PTメンバー表示対応

### 何をするもの？

キャラクター下のHP/SPバー上下に現在値と最大値を表示します。

### どうすれば？

ipfファイルをインストールして、addons/minigaugetext/settings.txt を用意します。

settings.txt
```lua
local s = {}
---
s['size'] = 13            -- 自キャラフォントサイズ
s['color'] = '#FFFFFF'    -- 自キャラフォントカラー
s['ptsize'] = 12          -- PTメンバーフォントサイズ
s['ptcolor'] = '#CCCCCC'  -- PTメンバーフォントカラー
---
return s
```

- size / ptsize

フォントサイズを変更します。最大値はだいたい20くらいで見切れてくると思います。
デフォルトは11です。

- color / ptcolor

フォントカラーを変更します。「# + RGB」の形式です。
デフォルトは #FFFFFF です。（白）

### いつ動くの？

- HP/SPに変化があったとき。

### 注意事項

ないよ！

###

[http://www.weizlogy.gq/tos/addon/minigaugetext/](http://www.weizlogy.gq/tos/addon/minigaugetext/)