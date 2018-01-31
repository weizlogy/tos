-- 領域定義
local author = 'weizlogy'
local addonName = 'showhiddenmap'
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
function SHOWHIDDENMAP_ON_INIT(addon, frame)
  -- 関数退避
  if (g.instance.DontUseMinimap == nil) then
    g.instance.DontUseMinimap = session.DontUseMinimap
  end
  -- ミニマップ不使用チェックのサニタイジング
  session.DontUseMinimap = function()
    return false
  end
  -- 旧関数でミニマップ不使用だったマップに居るときはイベントハンドラーを設置する
  if (g.instance.DontUseMinimap() == true) then
    ui.GetFrame('minimap'):RunUpdateScript("SHOWHIDDENMAP_UPDATE_MINIMAP", 0.2)
    ui.GetFrame('map'):RunUpdateScript("SHOWHIDDENMAP_UPDATE_MAP", 0.2)
  end
end

-- ミニマップ更新イベントハンドラー
function SHOWHIDDENMAP_UPDATE_MINIMAP(frame)
  MINIMAP_CHAR_UDT(frame, '', '', session.GetMyHandle())
  return 1
end

-- マップ更新イベントハンドラー
function SHOWHIDDENMAP_UPDATE_MAP(frame)
  MAP_CHAR_UPDATE(frame, '', '', session.GetMyHandle())
  return 1
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy()
end
g.instance = g()
