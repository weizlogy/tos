see [https://blog.weizlogy.com/pages/tos-addon/#showhiddenmap](https://blog.weizlogy.com/pages/tos-addon/#showhiddenmap)

### v1.0.1

#### マップ更新ロジック修正

FPS_UPDATE->RunUpdateScript(0.2)に変更することでスムーズ具合が向上しました。（ぬるぬるとは言ってない）

### v1.0.0

#### 新規作成

アドオンがロードされると、（ミニ）マップが表示されないマップで（ミニ）マップが表示されるようになります。
とある事情で、通常マップに比べるとちょっとマップ位置更新がスムーズではありませんが...

というのも、MAP_CHARACTER_UPDATEのイベントが発生しないっぽいので、FPS_UPDATEで代用しているためだったり。
