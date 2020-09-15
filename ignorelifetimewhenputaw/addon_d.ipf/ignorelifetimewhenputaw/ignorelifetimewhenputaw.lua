-- 領域定義
local author = 'weizlogy'
local addonName = 'ignorelifetimewhenputaw'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- 個別フレームのコンストラクター
function g.new(self)
  local members = {};

  -- === 関数 === --

  -- ************************************************************** --
  -- ************************************************************** --
  -- ************************************************************** --

  --* ログ出力
  members.Dbg = function(self, msg)
    -- CHAT_SYSTEM(string.format('{#666666}[%s] <Dbg> %s', addonName, msg))
  end
  members.Log = function(self, msg)
    CHAT_SYSTEM(string.format('[%s] <Log> %s', addonName, msg))
  end
  members.Err = function(self, msg)
    CHAT_SYSTEM(string.format('{#FF0000}[%s] <Err> %s', addonName, msg))
  end

  --* 既存関数オーバーライド汎用
  local __override = {};
  members.Override = function(self, name, func)
    if (func == nil) then
      self:Dbg('FUNCTION CALL -> '..name)
      return __override[name]
    end
    if (__override[name]) == nil then
      __override[name] = _G[name]
    end
    _G[name] = func
    self:Dbg('FUNCTION OVERRIDE -> '..name)
  end

  --* デストラクター
  members.Destroy = function(self)
    for name, func in pairs(__override) do
      if (name) ~= nil then
        _G[name] = func
        __override[name] = nil
        self:Dbg('FUNCTION UN-OVERRIDE -> '..name)
      end
    end
  end
  -- おまじない
  return setmetatable(members, {__index = self});
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new})

--* 自フレーム初期化処理
function IGNORELIFETIMEWHENPUTAW_ON_INIT(addon, frame)
  g.i:Override('PUT_ACCOUNT_ITEM_TO_WAREHOUSE_BY_INVITEM',
    function(_frame, _invItem, _slot, _fromFrame)
      _invItem.hasLifeTime = false
      g.i:Override('PUT_ACCOUNT_ITEM_TO_WAREHOUSE_BY_INVITEM')(_frame, _invItem, _slot, _fromFrame)
  end)
end

--* インスタンス作成
if (g.i ~= nil) then
  g.i:Destroy();
end
g.i = g();
