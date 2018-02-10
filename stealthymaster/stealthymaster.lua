-- 領域定義
local author = 'weizlogy'
local addonName = 'stealthymaster'
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
    PROPERTY_COMPARE = g.instance.PROPERTY_COMPARE
  end
  -- おまじない
  return setmetatable(members, {__index = self})
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new})

-- 自フレーム初期化処理
function STEALTHYMASTER_ON_INIT(addon, frame)
  if (g.instance.PROPERTY_COMPARE == nil) then
    g.instance.PROPERTY_COMPARE = PROPERTY_COMPARE
  end
  PROPERTY_COMPARE = function(handle)
    -- ui.PropertyCompare(handle, 1)    -- キャラ情報表示＋いいね
    -- ui.PropertyCompare(handle, 1, 1) -- キャラ情報表示＋いいね
    -- ui.PropertyCompare(handle, 0, 1) -- いいね
    -- ui.PropertyCompare(handle, 1, 0) -- キャラ情報表示
    ui.PropertyCompare(handle, 1, 0)
  end
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy()
end
g.instance = g()
