# Release Note.

## v1.1.3

### 動かなくなってたのを修正 その２

## v1.1.2

### 動かなくなってたのを修正

## v1.1.1

### コメント機能追加

チャットで"/hpm comment on"または"/hpm comment off"で、コメント表示UIのON/OFFができます。

settings.txtにおいても、"comment='on'"または"comment='off'"で表示状態をHPで切り替えられます。
"comment='任意の文字列'"をHPに応じて表示できます。

改行( {nl} )、色付け( {#FF0000} )なども対応できます。

## v1.0.2

### 一時的なON/OFF機能の追加

チャットで"/hpm on"または"/hpm off"で、通知のON/OFFができます。
マップ切り替えなどが発生すると、初期状態(ON)に戻ります。

## v1.0.1

### テストプレイ結果反映

## v1.0.0

### テストプレイ版作成

### 何をするもの？

ボスのHPを監視して、指定パーセント付近で音とチャットを流します。
特殊行動の対処等に使う想定です。

それとは別に、常時モンスターのHPバーにパーセンテージ表示を追加します。

### どうすれば？

ipfファイルをインストールします。

addons/hpmonitor/settings.txtを用意します。

#### 初期設定

下記テンプレートをコピペします。
```
local s = {}
---
s['boss_AmissDog'] = {
  [1] = { limit = 70, msg = '/p 70%です' },
  [2] = { limit = 50, msg = '/p 50%です' },
}
s['ID_boss_Rambandgad_red'] = {
  [1] = { limit = 80, msg = '/p 89', sound = 'button_click_stats_up', comment='on' },
  [2] = { limit = 79, msg = '/p 87%です' },
  [3] = { limit = 78, msg = '/p 86%です', comment='test{nl}test2{#FF0000}color?' },
  [4] = { limit = 77, msg = '/p 85%です', comment='off' },
}
---
return s
```

#### 設定方法

"--"で囲まれた部分が変更可能な範囲です。

##### 設定内容の説明

s['boss_AmissDog'] = ...

監視対象のClassNameを設定します。
ClassNameはtosjbase等で調べてください。

[1] = { limit = 80, msg = '/p 89', sound = 'button_click_stats_up' },

- limit

アドオンが動作するHPのパーセンテージです。80なら81%～80%の範囲内で動作します。

- msg

アドオン動作時にチャットで発言する内容です。/p 始まりだとPTチャットとなります。

- sound

アドオン動作時に鳴らす効果音です。

### いつ動くの？

- ターゲットのHPが変化した場合

### 注意事項

なし