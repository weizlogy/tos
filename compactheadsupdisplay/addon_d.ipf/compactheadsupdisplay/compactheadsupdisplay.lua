-- 領域定義
local author = 'weizlogy'
local addonName = 'compactheadsupdisplay'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  -- initialize members.
  local members = {};

  members.HideGauge = function(self, frame)
    local stamina = GET_CHILD_RECURSIVELY(frame, 'sta1', 'ui::CGauge')
    stamina:Resize(0, 0)
    local hp = GET_CHILD_RECURSIVELY(frame, 'hp', 'ui::CGauge')
    hp:Resize(0, 0)
    local sp = GET_CHILD_RECURSIVELY(frame, 'sp', 'ui::CGauge')
    sp:Resize(0, 0)
    local myhpspleft = GET_CHILD_RECURSIVELY(frame, 'myhpspleft', 'ui::CGauge')
    myhpspleft:SetAlpha(0)
    local myhpspright = GET_CHILD_RECURSIVELY(frame, 'myhpspright', 'ui::CGauge')
    myhpspright:SetAlpha(0)
    local gaugelight1 = GET_CHILD_RECURSIVELY(frame, 'gaugelight1', 'ui::CGauge')
    gaugelight1:SetAlpha(0)
    local gaugelight2 = GET_CHILD_RECURSIVELY(frame, 'gaugelight2', 'ui::CGauge')
    gaugelight2:SetAlpha(0)
    frame:Resize(100, frame:GetHeight())
  end

  -- ログ出力
  members.Dbg = function(self, msg)
    CHAT_SYSTEM(string.format('{#666666}[%s] <Dbg> %s', addonName, msg))
  end
  members.Log = function(self, msg)
    CHAT_SYSTEM(string.format('[%s] <Log> %s', addonName, msg))
  end
  members.Err = function(self, msg)
    CHAT_SYSTEM(string.format('[%s] <Err> %s', addonName, msg))
  end

  -- destroy.
  members.Destroy = function(self)
    HEADSUPDISPLAY_ON_MSG = g.instance.HEADSUPDISPLAY_ON_MSG;
    g.instance.HEADSUPDISPLAY_ON_MSG = nil;
  end
  -- おまじない
  return setmetatable(members, {__index = self});
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new});

-- frame initialize.
function COMPACTHEADSUPDISPLAY_ON_INIT(addon, frame)
  if (g.instance.HEADSUPDISPLAY_ON_MSG == nil) then
    g.instance.HEADSUPDISPLAY_ON_MSG = HEADSUPDISPLAY_ON_MSG;
  end
  HEADSUPDISPLAY_ON_MSG = function(frame, msg, argStr, argNum)
    g.instance.HEADSUPDISPLAY_ON_MSG(frame, msg, argStr, argNum);
    g.instance:HideGauge(frame);
  end
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy();
end
g.instance = g();
