-- 領域定義
local author = 'weizlogy'
local addonName = 'kaywadequeer'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  local members = {};

  members.CreateUI = function(self)
    local frame = ui.GetFrame(addonName)
    frame:ShowWindow(0)
    local base = ui.GetFrame('headsupdisplay')
    local exec = base:CreateOrGetControl('button', 'exec', 0, 0, 25, 25)
    exec:SetText('DE')
    exec:SetOffset(5, base:GetHeight() - 23)

    KAYWADEQUEER_ON_EXEC_LBU = function(parent, ctrl, str, num)
      debug.ReloadAddOnScp()
      debug.ReloadUIEvent()
    end
    exec:SetEventScript(ui.LBUTTONUP, 'KAYWADEQUEER_ON_EXEC_LBU')
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
  end
  -- おまじない
  return setmetatable(members, {__index = self});
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new});

-- 自フレーム初期化処理
function KAYWADEQUEER_ON_INIT(addon, frame)
  g.instance:CreateUI()
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy();
end
g.instance = g();
