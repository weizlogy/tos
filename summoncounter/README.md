## Latest Release Note.

### v2.0.0

#### 管理対象追加

以下のスキルに対応しました。

##### ネクロマンサー

- レイズスカルウィザード
- コープスタワー

##### ソーサラー

- サモンサラミオン
- サモンサーヴァント

##### フェザーフット

- ボーンポインティング

##### 陰陽師

- 狐火式神

##### ティルドルビー

- ジェミナ女神像
- ライマ女神像
- フクロウの彫像
- 世界樹の彫刻
- アウシュリネ女神像

#### パーティー表示形式追加

対象の召喚物をPT欄風のUIで表示します。

HPBARモードは集約しますがこちらは集約しません。そして召喚物へのバフが見えます。

##### 使い方

```lua
Necromancer_RaiseSkullwizard = {
  mode = "party",
},
Sorcerer_SummonSalamion = {
  mode = "party",
  title = "サラミオン" -- 任意の名称を表示できます。未指定でも大丈夫です。
},
```

#### トークモード追加

対象の召喚物がフキダシ表示でしゃべります。

##### 使い方

talk = {...} があれば機能が有効になります。

- data

しゃべらせる内容の一覧テキストです。(文字コードはUTF-8だよ！)

addons\summoncounter\ 配下においてください。(settings.txtと同じ場所)

- format

dataのフォーマットを指定します。list_dicid.txt のようにID指定の場合は dicid にしてください。

通常の文字列の場合は custom にしてください。

- freq

しゃべる頻度を指定します。だいたいパーセンテージなんですが、諸事情により5とか10でもそこそこ出ます。

```lua
Necromancer_RaiseDead = {
  mode = "party",
  talk = {
    data = "list_dicid.txt",
    format = 'dicid',
    freq = 10
  }
},
Sorcerer_SummonSalamion = {
  mode = "party",
  title = "サラミオン",
  talk = {
    data = "waganeko.txt",
    format = 'custom',
    freq = 5
  }
},
```

#### 右クリックで設定ファイル読み込み

パーティー表示とHPバー表示のUIで右クリックすると設定ファイルを再読込できます。

see [http://www.weizlogy.gq/tos/addon/summoncounter/](http://www.weizlogy.gq/tos/addon/summoncounter/)