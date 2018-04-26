-- 領域定義
local author = 'weizlogy'
local addonName = 'removetipsfe'
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
    if (self.LEVEL_LINFORM_MESSAGE_CLIENT ~= nil) then
      LEVEL_LINFORM_MESSAGE_CLIENT = self.LEVEL_LINFORM_MESSAGE_CLIENT
    end
  end
  -- おまじない
  return setmetatable(members, {__index = self})
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new});

-- 自フレーム初期化処理
function REMOVETIPSFE_ON_INIT(addon, frame)
  -- 関数退避
  if (g.instance.LEVEL_LINFORM_MESSAGE_CLIENT == nil) then
    g.instance.LEVEL_LINFORM_MESSAGE_CLIENT = LEVEL_LINFORM_MESSAGE_CLIENT
  end
  -- フックして...
  LEVEL_LINFORM_MESSAGE_CLIENT = function(idList)
    -- pc_client.lua # LEVEL_LINFORM_MESSAGE_CLIENT からコピペ注意
    local idList = SCR_STRING_CUT(idList)
    local msg = '[TIPS] '
    for i = 1, #idList do
      local ies = GetClassByType('levelinformmessage', idList[i])
      msg = msg..'{nl} {nl}'..i..'. '..string.gsub(dictionary.ReplaceDicIDInCompStr(ies.Message), '%{.-%}', '')
    end
    CHAT_SYSTEM(msg)
  end
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy()
end
g.instance = g()
