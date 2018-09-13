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

  members.SetSortType = function(self, sortType)
    __sortType = sortType
  end

  members.Sort = function(self, baseList)
    -- INV_ITEM_SORTED_LIST型を再現（いらないんじゃないか疑惑はある
    local sortWorker = {
      at = function(self, index)
        return self[index + 1]
      end,  -- <- カンマないと死ぬ気をつけて
      size = function(self)
        return #self
      end
    }

    -- データを作業ワークへコピー
    for i = 0 , baseList:size() - 1 do
      local invItem = baseList:at(i)
      if (invItem ~= nil) then
        table.insert(sortWorker, invItem)
      end
    end

    local sortType = __sortType
    local sortFunc = nil
    if (__sortType == 1) then
      sortFunc = function(s1, s2)
        local o1 = GetIES(s1:GetObject())
        local o2 = GetIES(s2:GetObject())
        local r = o1.Weight < o2.Weight
        if (o1.Weight == o2.Weight) then
          r = dictionary.ReplaceDicIDInCompStr(o1.Name) < dictionary.ReplaceDicIDInCompStr(o2.Name)
        end
        return r
      end
    elseif (__sortType == 2) then
      sortFunc = function(s1, s2)
        local o1 = GetIES(s1:GetObject())
        local o2 = GetIES(s2:GetObject())
        return dictionary.ReplaceDicIDInCompStr(o1.Name) < dictionary.ReplaceDicIDInCompStr(o2.Name)
      end
    else
      -- ソート未指定なら何もしない
      return baseList
    end
    -- ソート実行
    table.sort(sortWorker, sortFunc)

    -- for i = 0, 20 do
    --   CHAT_SYSTEM('['..dictionary.ReplaceDicIDInCompStr(GetIES(sortWorker:at(i):GetObject()).Name)..']')
    -- end

    return sortWorker
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
    return g.instance:Sort(g.instance.sessionGetInvItemSortedList())
  end
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy();
end
g.instance = g();
