# Release Note.

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
