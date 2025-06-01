see [https://blog.weizlogy.com/pages/tos-addon/#repairendur](https://blog.weizlogy.com/pages/tos-addon/#repairendur)

## settings.

Nexon\TreeofSaviorJP\addons\repairendur\settings.txt を作成します。

以下の初期設定を[settings.txt](https://github.com/weizlogy/tos/blob/master/repairendur/settings.txt)コピペします。

```lua
reen.Weapon = {
  Lp = 30,
  Mp = 5,
  Hp = 1
};
reen.Armor = {
  Lp = 35,
  Mp = 10,
  Hp = 5
};
reen.SubWeapon = reen.Weapon; -- added v1.1.0
reen.EndurColor = {
  Lc = "FFFF00",
  Mc = "FF0000",
  Hc = "000000"
};
```

### explanation.

この設定は装備の耐久度と割合に応じた文字色の設定です。

[Weapon]、[Armor]は装備の耐久度の色分け用閾値で、Low, Middle, Highの3段階を、武器用と防具用で用意しています。

[EndurColor]は装備の耐久度閾値に対応する色をRGBで指定します。

### explanation of initial parameters.

武器

- 耐久度[30]%以下で[黄]色
- 耐久度[5]%以下で[赤]色
- 耐久度[1]%以下で[黒]色

防具

- 耐久度[35]%以下で[黄]色
- 耐久度[10]%以下で[赤]色
- 耐久度[5]%以下で[黒]色

サブウェポン

- 武器と同様

## descriptions.

### v1.1.0

サブウェポン用の設定を追加しました。

[issue #2](https://github.com/weizlogy/tos/issues/2)

初期値は武器の設定値を見るようにしています。

### v1.0.1

修理後に以前の耐久度表示が残る問題を修正しました。

### v1.0.0

新規作成。

アドオンがロードされると、NPC修理、露天修理の装備アイコンに耐久度を設定の閾値に応じた文字色で表示します。
