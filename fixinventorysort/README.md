# Release Note.

## v1.2.0

### サブグループ指定ソート機能追加

アイテムのサブグループを指定して全体のソートとは別のソート順を指定できます。

#### 設定方法

機能を有効にするには以下の記述が設定ファイルに必要です。
（つまり、該当機能を使用しないのであれば書かないほうがソート処理速度に有利です。
```
s['affect'] = {}
```

##### 設定内容の説明

フォーマットは以下の通りで、カンマ区切りにより複数個指定可能です。
```
['サブグループ名'] = ソート順 , ...
```

サブグループ名は、インベントリの中項目の分類です。
例えば、ジェム（大項目：アイテム > 中項目：ジェム

ソート順は、そのサブグループ名に該当するアイテムのソート順を指定します。（そのままやん...
既存ソートを指定する場合は、'weight'など文字列で記載できます。
拡張ソートを指定する場合は、定義部分（s[]）に記載した数字を記載します。（s[2]なら、2

具体例を一つ。
材料は重さ順、消費は名前順、ジェムはアイコン順にする場合は
以下のようにします。
```
local s = {}
--
s[0] = 'weight'
s[1] = 'name'
s[2] = {
  Desc = 'アイコン順',
  Sort = {
    [0] = 'Icon',
    [1] = 'Name'
  }
}
s['affect'] = {
  ['材料'] = 'weight',
  ['消費'] = 'name',
  ['ジェム'] = 2,
}
--
return s
```

## v1.1.0

### 重さ順の処理修正

- 重さ順
重さ（昇順） > 個数（降順） > 名前（昇順）

### 拡張メニュー対応

設定ファイルで自分の好きなソートを定義できます。

#### 用意するもの

addons/fixinventorysort/settings.txt

#### 初期設定

下記テンプレートをコピペします。
```
local s = {}
--
s[0] = 'weight'
s[1] = 'name'
s[2] = {
  Desc = 'アイコン順',
  Sort = {
    [0] = 'Icon',
    [1] = 'Name'
  }
}
--
return s
```

#### 設定方法

"--"で囲まれた部分が変更可能な範囲です。

##### 設定内容の説明

これは既存のソート順である「重さ順」を使えるようにします。
この書き方で、'name'（名前順）, 'level'（等級順）の定義ができます。
```
s[0] = 'weight'
```

これは独自に拡張したソート順の定義で、ソートメニュー上では「アイコン順」と表示されます。
並び方は、アイコン（昇順） > 名前（昇順）の順序です。
```
s[2] = {
  Desc = 'アイコン順',
  Sort = {
    [0] = 'Icon',
    [1] = 'Name'
  }
}
```

sの後に続く数字はソートメニュー上の表示順序です。
テンプレートでは、「重さ順」「名前順」「アイコン順」と表示されます。
**数字が重複しないように気をつけてください。**
```
s[0]...
s[1]...
s[2]...
```

##### 拡張ソート順で使える項目

item.ies（とマージしているies）に定義された以下の項目が使えます。
どんな値が入っているかは書くと大変なので名称で察してください。

とまあ作ってみたものの実際そんな使えそうなものがないという...

```
ClassID,Weight,ItemStar,UseLv,MaterialPrice,Price,PriceRatio,SellPrice,RepairPriceRatio,MaxStack,Scale,DropSoundTime,DeadBreakRatio,NumberArg1,NumberArg2,ItemCoolDown,BelongingCount,LifeTime,ItemLifeTimeOver,ReopenDiscountRatio,CardLevel,PackageTradeCount,ItemExp,SkillType,SkillLevel,ClassName,Name,ItemType,Journal,GroupName,EquipXpGroup,MergeTable1,MergeClass1,MergeTable2,MergeClass2,MergeTable3,MergeClass3,ToolTipScp,ItemGrade,TooltipImage,Icon,ReqToolTip,TooltipValue,Desc,DropSound,EquipSound,InOutScp,Script,Destroyable,TeamTrade,ShopTrade,MarketTrade,UserTrade,RefreshScp,DropStyle,StringArg,Usable,PreCheckScp,Consumable,UseAnim,ClientScp,ParticleName,UseTx,CoolDown,CoolDownGroup,AllowDuplicate,NotExist,LogoutSave,PVPMap,ItemLifeTime,SpineTooltipImage,AllowReopen,Reinforce_Type,CubeDuplicate,MarketCategory,Desc_Sub,CardGroupName,FileName,CustomToolTip,ClassType2,LifeTime_Limitcheck,PVP,PackageTradeAble,Package,ClassType
```

## v1.0.0

### 何をするもの？

ロケーションに応じた名前でのソートが上手く動かない問題を修正します。
また、以下の通り、既存ソートを変更します。

- 等級順
既存踏襲

- 重さ順
重さ（昇順） > 名前（昇順）

- 等級順
名前（昇順）

### どうすれば？

ipfファイルをインストールするだけです。

### いつ動くの？

- ソートを実行したとき。

### 注意事項

ないよ！
