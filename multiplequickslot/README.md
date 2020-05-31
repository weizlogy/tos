# Release Note.

クイックスロットの保存、復元できるようになります。

# 使い方

## 準備

ipfファイルをインストールします。

addons/multiplequickslotフォルダを作成します。

## 概要

![概要](https://raw.githubusercontent.com/weizlogy/tos/master/multiplequickslot/usage.png "概要")

## ◆メニュー

- AddNew

指定した名前のクイックスロットセットを登録します。（メニュー選択後、入力ダイアログがでます。

- Delete

指定した名前のクイックスロットセットを削除します。（メニュー選択後、入力ダイアログがでます。

- Reload (v1.0.2)

各種設定を再読み込みします。

- ClearAll

現在のクイックスロットを空にします。（メニュー選択後、確認ダイアログがでます。

- Cancel

メニューを閉じます。

## クイックスロットセット名ラベル

最後に選択したクイックスロットセット名を表示します。
右クリックで表示するメニューから別のセットに切り替えることができます。

### ラベル表示位置調整

Settings.txtをダウンロードしてaddons/multiplequickslot下に置きます。

[Settings.txt](https://github.com/weizlogy/tos/releases/download/multiplequickslot/Settings.txt)

labelX、labelY の数値を変えつつ、◆メニューのReloadで反映させて確認してください。（これはキャラ共通です

```lua
local s = {
  ['labelX'] = '0',  -- ラベルのX座標を調整する
  ['labelY'] = '0',  -- ラベルのY座標を調整する
}
return s
```
