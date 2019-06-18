-- 領域定義
local author = 'weizlogy'
local addonName = 'repeaterypuzzlecraft'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- 個別フレームのコンストラクター
function g.new(self)
  local members = {};

  -- === 公開定数 === --

  -- === 定数 === --
  local __ADDON_DIR = '../addons/'..addonName

  -- === 内部データ === --
  local __recipe = {}

  -- === 内部関数 === --

  -- === 公開データ === --
  members.RepeatCount = 0

  -- === 公開関数 === --
  members.SaveRecipe = function(self)
  end

  members.ShowRemainCount = function(self)
    self:Log('Remaining : '..self.RepeatCount)
  end

  members.ExecCombination = function()
    if false == geItemPuzzle.ExecCombination(true) then
      ui.SysMsg(ClMsg("NotEnoughRecipe"))
    end
  end

  -- ログ出力
  members.Dbg = function(self, msg)
    CHAT_SYSTEM(string.format('[%s] <Dbg> %s', addonName, msg))
  end
  members.Log = function(self, msg)
    CHAT_SYSTEM(string.format('[%s] <Log> %s', addonName, msg))
  end
  members.Err = function(self, msg)
    CHAT_SYSTEM(string.format('[%s] <Err> %s', addonName, msg))
  end

  -- デストラクター
  members.Destroy = function(self)
    if (g.i._PUZZLECRAFT_EXEC ~= nil) then
      _PUZZLECRAFT_EXEC = g.i._PUZZLECRAFT_EXEC
    end
    if (g.i.PUZZLE_COMPLETE ~= nil) then
      PUZZLE_COMPLETE = g.i.PUZZLE_COMPLETE
    end
  end
  -- おまじない
  return setmetatable(members, {__index = self});
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new})

-- 自フレーム初期化処理
function REPEATERYPUZZLECRAFT_ON_INIT(addon, frame)
  -- 調合前に回数指定
  -- 調合開始後に画面を閉じない
  if (g.i._PUZZLECRAFT_EXEC == nil) then
    g.i._PUZZLECRAFT_EXEC = _PUZZLECRAFT_EXEC
  end
  _PUZZLECRAFT_EXEC = function(frame)
    local default = 1
    local min = 1
    local max = 999
    INPUT_NUMBER_BOX(nil, ScpArgMsg('InputCount'), 'REPEATERYPUZZLECRAFT_EXEC_TRUELY', default, min, max, nil, 1)
  end

  -- 調合後に再実行
  -- 1調合後に状態をリセットしない
  if (g.i.PUZZLE_COMPLETE == nil) then
    g.i.PUZZLE_COMPLETE = PUZZLE_COMPLETE
  end
  PUZZLE_COMPLETE = function()
    g.i.RepeatCount = g.i.RepeatCount - 1
    if (g.i.RepeatCount <= 0) then
      g.i.PUZZLE_COMPLETE()
      return
    end
    g.i:ShowRemainCount()
    g.i:ExecCombination()
  end
end

-- === イベントハンドラー === --
function REPEATERYPUZZLECRAFT_EXEC_TRUELY(count, inputframe)
  g.i.RepeatCount = tonumber(count)
  g.i:ExecCombination()
end

-- インスタンス作成
if (g.i ~= nil) then
  g.i:Destroy();
end
g.i = g();
