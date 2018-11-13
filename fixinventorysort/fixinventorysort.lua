-- 領域定義
local author = 'weizlogy'
local addonName = 'fixinventorysort'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  local members = {};

  -- ソート種別
  --  デフォルト
  --   0 = LEVEL,
  --   1 = WEIGHT,
  --   2 = NAME,
  local __sortType = -1
  -- 拡張ソート設定
  local __config = {}
  -- デフォルトのソート種別と重複しないように拡張ソート種別の開始位置を決める
  local __extendSortStartIndex = 10

  -- ソート条件を保存
  members.SetSortType = function(self, sortType)
    __sortType = sortType
  end

  -- ソート処理
  members.Sort = function(self, baseList, useAffect)
    -- INV_ITEM_SORTED_LIST型を再現（いらないんじゃないか疑惑はある
    local sortWorker = {
      at = function(self, index)
        return self[index + 1]
      end,  -- <- カンマないと死ぬ気をつけて
      size = function(self)
        return #self
      end
    }
    -- ソート対象外保管領域
    local ignoreSortWorker = {}

    -- データを作業ワークへコピー
    -- 対象外のアイテムは専用ワーク行き
    for i = 0 , baseList:size() - 1 do
      local invItem = baseList:at(i)
      if (invItem ~= nil) then
        if (not useAffect) then
          table.insert(sortWorker, invItem)
        else
          local baseidcls = GET_BASEID_CLS_BY_INVINDEX(invItem.invIndex)
          -- CHAT_SYSTEM(GetIES(invItem:GetObject()).GroupName..' / '..baseidcls.TreeGroupCaption..' / '..baseidcls.TreeSSetTitle)
          local affect = __config['affect']
          local target = baseidcls.TreeSSetTitle
          if (affect and affect[dictionary.ReplaceDicIDInCompStr(target)]) then
            -- 対象グループ名ごとにまとめる
            -- ここも再帰的呼び出しのためINV_ITEM_SORTED_LIST型を再現
            ignoreSortWorker[target] = ignoreSortWorker[target] or {
              at = function(self, index)
                return self[index + 1]
              end,  -- <- カンマないと死ぬ気をつけて
              size = function(self)
                return #self
              end
            }
            table.insert(ignoreSortWorker[target], invItem)
          else
            table.insert(sortWorker, invItem)
          end
        end
      end
    end

    local sortFunc = self:ToSortFunc(__sortType)
    if (sortFunc == nil) then
      return baseList
    end
    -- ソート実行
    table.sort(sortWorker, sortFunc)

    -- for i = 0, 20 do
    --   CHAT_SYSTEM('['..dictionary.ReplaceDicIDInCompStr(GetIES(sortWorker:at(i):GetObject()).Name)..']')
    -- end

    local chooseSortType = __sortType
    for k, v in pairs(ignoreSortWorker) do
      __sortType = self:ToSortType(__config['affect'][dictionary.ReplaceDicIDInCompStr(k)])
      local sortedList = self:Sort(v)
      -- CHAT_SYSTEM(k..' - '..__sortType..' - '..#sortedList)
      for _, v in ipairs(sortedList) do
        table.insert(sortWorker, 1, v)
      end
    end
    __sortType = chooseSortType

    return sortWorker
  end

  -- ソート種別からソートロジックに変換
  members.ToSortFunc = function(self, type)
    local sortFunc = nil
    if (__sortType == 1) then
      sortFunc = function(s1, s2)
        local o1 = GetIES(s1:GetObject())
        local o2 = GetIES(s2:GetObject())
        local r = o1.Weight < o2.Weight
        if o1.Weight ~= o2.Weight then
          return r
        end
        r = dictionary.ReplaceDicIDInCompStr(o1.Name) < dictionary.ReplaceDicIDInCompStr(o2.Name)
        if o1.Name ~= o2.Name then
          return r
        end
        r = s1.count > s2.count
        if s1.count ~= s2.count then
          return r
        end
        return s1:GetIESID() < s2:GetIESID()
      end
    elseif (__sortType == 2) then
      sortFunc = function(s1, s2)
        local o1 = GetIES(s1:GetObject())
        local o2 = GetIES(s2:GetObject())
        local r = dictionary.ReplaceDicIDInCompStr(o1.Name) < dictionary.ReplaceDicIDInCompStr(o2.Name)
        if o1.Name ~= o2.Name then
          return r
        end
        return s1:GetIESID() < s2:GetIESID()
      end
    -- 拡張ソートロジック
    elseif (__sortType >= __extendSortStartIndex) then
      -- 設定復元
      local config = __config[__sortType - __extendSortStartIndex]
      if (not config) then
        return baseList
      end
      -- ソートロジック作成
      local sortFuncTemplate =
        " return function(s1, s2) \
            local o1 = GetIES(s1:GetObject()); \
            local o2 = GetIES(s2:GetObject()); \
            local r = 0; \
            %s \
            return s1:GetIESID() < s2:GetIESID(); \
          end; "
      local sortFuncDynamicaly = ''
      local sortKeys = config.Sort
      for i = 0, #sortKeys do
        local key = sortKeys[i]
        local logic = string.format(
          " r = dictionary.ReplaceDicIDInCompStr(o1['%s']) < dictionary.ReplaceDicIDInCompStr(o2['%s']);  \
            if (o1['%s'] ~= o2['%s']) then  \
              return r  \
            end; ", key, key, key, key)
        sortFuncDynamicaly = sortFuncDynamicaly..logic
      end
      sortFunc = assert(loadstring(string.format(sortFuncTemplate, sortFuncDynamicaly)))()
    end
    return sortFunc
  end

  members.CreateSortMenu = function(self)
    local configName = '../addons/fixinventorysort/settings.txt'
    -- 設定ファイルが不正ならオリジナル
    -- 設定ファイルがあればそこからメニュー構築
    local customContextConfig, e = loadfile(configName)
    if (e) then
      self:Err(e)
      self.SORT_ITEM_INVENTORY()
      return
    end
    __config = customContextConfig()
    local context = ui.CreateContextMenu('FIXINVENTORYSORT_CONTEXT_SORT', addonName, 0, 0, 170, 100)

    for i = 0, #__config do
      local scpScp = ''
      local config = __config[i]
      -- 文字列だけ == 既存ロジック
      -- 文字列以外 == 拡張ロジック
      if (type(config) == 'string') then
        scpScp = string.format("REQ_INV_SORT(%d, %d)",IT_INVENTORY, self:ToSortType(config))
        ui.AddContextMenuItem(context, loadstring(string.format('return ScpArgMsg("SortBy%s")', config:gsub('^%l', string.upper)))(), scpScp)
      else
        config.Id = self:ToSortType(i)
        self:Dbg(config.Id..' - '..config.Desc)
        scpScp = string.format("REQ_INV_SORT(%d, %d)",IT_INVENTORY, config.Id)
        ui.AddContextMenuItem(context, config.Desc, scpScp)
      end
    end

  	ui.OpenContextMenu(context)
  end

  members.ToSortType = function(self, value)
    if (type(value) == 'string') then
      return loadstring('return BY_'..value:upper())()
    end
    return value + __extendSortStartIndex  -- Index値から勝手にIDを捏造
  end

  -- ログ出力
  members.Dbg = function(self, msg)
    -- CHAT_SYSTEM(string.format('[%s] <Dbg> %s', addonName, msg))
  end
  members.Log = function(self, msg)
    CHAT_SYSTEM(string.format('[%s] <Log> %s', addonName, msg))
  end
  members.Err = function(self, msg)
    CHAT_SYSTEM(string.format('[%s] <Err> %s', addonName, msg))
  end

  -- デストラクター
  members.Destroy = function(self)
    if (self.sessionGetInvItemSortedList ~= nil) then
      session.GetInvItemSortedList = self.sessionGetInvItemSortedList
      self.sessionGetInvItemSortedList = nil
    end
    if (self.REQ_INV_SORT ~= nil) then
      REQ_INV_SORT = self.REQ_INV_SORT
      self.REQ_INV_SORT = nil
    end
    if (self.SORT_ITEM_INVENTORY ~= nil) then
      SORT_ITEM_INVENTORY = self.SORT_ITEM_INVENTORY
      self.SORT_ITEM_INVENTORY = nil
    end
  end
  -- おまじない
  return setmetatable(members, {__index = self});
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new});

-- 自フレーム初期化処理
function FIXINVENTORYSORT_ON_INIT(addon, frame)
  -- インベントリソート呼び出し処理をフックしてソート種別を取得する
  if (g.instance.REQ_INV_SORT == nil) then
    g.instance.REQ_INV_SORT = REQ_INV_SORT
  end
  REQ_INV_SORT = function(invType, sortType)
    g.instance.REQ_INV_SORT(invType, sortType)
    g.instance:SetSortType(sortType)
  end
  -- インベントリアイテムの一覧取得処理をフックして正しく並び替えた一覧を返す
  if (g.instance.sessionGetInvItemSortedList == nil) then
    g.instance.sessionGetInvItemSortedList = session.GetInvItemSortedList
  end
  session.GetInvItemSortedList = function()
    return g.instance:Sort(g.instance.sessionGetInvItemSortedList(), true)
  end
  -- インベントリソートメニュー生成処理をフックしてカスタムソートを追加する
  if (g.instance.SORT_ITEM_INVENTORY == nil) then
    g.instance.SORT_ITEM_INVENTORY = SORT_ITEM_INVENTORY
  end
  SORT_ITEM_INVENTORY = function()
    g.instance:CreateSortMenu()
  end
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy();
end
g.instance = g();
