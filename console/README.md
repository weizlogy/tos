see [https://blog.weizlogy.com/pages/tos-addon/#console](https://blog.weizlogy.com/pages/tos-addon/#console)

### v1.2.0

#### GUI除去

GUIがなくなり、settings.txtは無効化されました。

#### チャットコマンド追加

GUIに代わり、チャットコマンド[/console]で処理を実行できます。

#### 抽出フォーマット変更

lua定義関数は引数を表示するようにしました。

c定義関数はcfunc.txtに定義することで引数を表示できます。

### v1.1.0

設定[ボタン表示状態]を追加しました。

アドオンがロードされるとボタン表示状態が1の場合のみ、[Console]ボタンが表示されます。
ボタンを押すと抽出を開始します。 
ボタン表示状態はエリアチェンジの度に読み込まれるため、ゲーム起動中にボタン表示を切り替えることも可能です。

### v1.0.0

新規作成。

アドオンがロードされると[Console]ボタンが表示されます。ボタンを押すと抽出を開始します。 Nexon\TreeofSaviorJP\data\console.txt に抽出結果が出力されます。
実際の抽出結果は[別記事]({% post_url 2016-12-31-ies-format %})にあります。

