-- 領域定義
local author = 'weizlogy'
local addonName = 'partyinfoex'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  local members = {}
  
  members.nameY = 0
  members.lvboxY = 0

  -- SPゲージを見える化
  -- 4/17VUで必要なくなったけど...
  -- members.AddSpGauge = function(self, partyInfoCtrlSet)
  --   local spGauge = GET_CHILD(partyInfoCtrlSet, "sp", "ui::CGauge");
  --   spGauge:SetMargin(79,47,0,0)
  --   spGauge:SetSkinName('pcinfo_gauge_sp')
  -- end

  -- 所在地を見える化
  members.AddLocation = function(self, partyInfoCtrlSet, partyMemberInfo)
    local mapCls = GetClassByType("Map", partyMemberInfo:GetMapID())
    if mapCls == nil then
      return
    end
    local location = partyInfoCtrlSet:CreateOrGetControl('richtext', "partyinfoex_location", 0, 0, 0, 0)
    location:SetText(string.format("{s12}{ol}[%s-%d]", mapCls.Name, partyMemberInfo:GetChannel() + 1))
    location:Resize(100, 20)
    location:SetOffset(10, 0)
    location:ShowWindow(1)

    -- レベルと名前をちょっと下げないと被ってしまう
    local nameObj = partyInfoCtrlSet:GetChild('name_text')
    if (self.nameY == 0) then
      self.nameY = nameObj:GetY()
    end
    nameObj:SetOffset(nameObj:GetX(), self.nameY + 2)

    local lvbox = partyInfoCtrlSet:GetChild('lvbox')
    if (self.lvboxY == 0) then
      self.lvboxY = lvbox:GetY()
    end
    lvbox:SetOffset(lvbox:GetX(), self.lvboxY + 2)
  end

  -- デストラクター
  members.Destroy = function(self)
    if (g.instance.UPDATE_PARTYINFO_HP ~= nil) then
      UPDATE_PARTYINFO_HP = g.instance.UPDATE_PARTYINFO_HP
    end
  end
  -- おまじない
  return setmetatable(members, {__index = self})
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new});

-- 自フレーム初期化処理
function PARTYINFOEX_ON_INIT(addon, frame)
  -- 関数退避
  if (g.instance.UPDATE_PARTYINFO_HP == nil) then
    g.instance.UPDATE_PARTYINFO_HP = UPDATE_PARTYINFO_HP
  end
  -- PT情報更新関数をフックして...
  UPDATE_PARTYINFO_HP = function(partyInfoCtrlSet, partyMemberInfo)
    g.instance.UPDATE_PARTYINFO_HP(partyInfoCtrlSet, partyMemberInfo)
    -- g.instance:AddSpGauge(partyInfoCtrlSet)
    if partyMemberInfo:GetMapID() > 0 then
      g.instance:AddLocation(partyInfoCtrlSet, partyMemberInfo)
    end
  end
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy()
end
g.instance = g()
