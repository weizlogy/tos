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

  -- デストラクター
  members.Destroy = function(self)
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
  -- PT情報更新関数をフックしてSPゲージを見える化
  UPDATE_PARTYINFO_HP = function(partyInfoCtrlSet, partyMemberInfo)
    g.instance.UPDATE_PARTYINFO_HP(partyInfoCtrlSet, partyMemberInfo)

    local spGauge = GET_CHILD(partyInfoCtrlSet, "sp", "ui::CGauge");
    spGauge:SetMargin(225,35,0,0)
    spGauge:SetSkinName('pcinfo_gauge_sp')
  end
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy()
end
g.instance = g()
