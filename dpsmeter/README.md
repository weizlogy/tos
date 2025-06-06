see [https://blog.weizlogy.com/pages/tos-addon/#dpsmeter](https://blog.weizlogy.com/pages/tos-addon/#dpsmeter)

### v1.3.1

#### DPS計測ON/OFF追加

初期状態をOFFとしました。

チャットコマンドにてON/OFFを切り替えます。

```lua
/dpsm on  -- 計測開始
/dpsm off -- 計測停止
```

### v1.3.0

#### DPS平均値表示を追加

#### DPS平均値表示に伴い、フォーマットを変更

```
現在のDPS[{淡青}平均DPS][{淡赤}最大DPS] dps
```

#### モンスター死亡時のsystemメッセージによる通知をデフォルトOFFに変更

表示するには、DPSのUIを右クリック > [toggleChat]を選択します。

選択する度に通知のON/OFFを切り替えます。

#### DPS計測対象を調整

- ボコルのゾンビフィーで召喚するゾンビを除外

### v1.2.0

#### DPS計測方法を調整

ターゲットアイコン表示が可能な距離まで近づいて、初撃時（を含む。初撃はdamage/1sec換算）からDPS計測を開始します。

ターゲットが死ぬかフレームアウトするまで計測は止まりません。

#### DPS計測対象を調整

旧バージョンではfaction = "Monster"を計測対象としていましたが不十分でしたので、
計測対象を拡大し、ペット以外（faction ~= "Pet"）としました。

IWやルーツクリスタルも対象となってしまいますが、計測されないよりは良いかと。。。

### v1.1.0

#### UI表示を追加

現在のDPS、最大DPSをモンスターUI近辺に、以下のフォーマット表示します。

```
[現在のDPS]([最大DPS]) dps
```

#### モンスター死亡時のsystemメッセージによる通知を追加

モンスター死亡時、最大DPSをsystemメッセージで表示します。

ターゲットアイコン表示が可能な距離まで近づくとDPS計測を開始、離れると停止します。

### v1.0.0

#### 新規作成。

アドオンがロードされるとDPS計測が有効になり、計測結果はsystemメッセージで通知します。

現時点ではコンバットログが取れないので、正確な測定は実現できていません。

少しでも測定精度を上げたい場合は、以下の点に注意してください。

- ソロで戦う。（コンパニオンも出さない）
- 混戦しない。
- 回復持ちの敵は避ける。
