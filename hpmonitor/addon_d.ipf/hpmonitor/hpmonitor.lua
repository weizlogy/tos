-- 領域定義
local author = 'weizlogy'
local addonName = 'hpmonitor'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  local members = {}

  local __ADDON_DIR = '../addons/'..addonName
  local __CONFIG_FILENAME = 'settings.txt'
  
  local __config = {}
  local __monitorByHandle = {}
  local __monitorMode = 1

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

	members.Deserialize = function(self)
    local filePath = string.format('%s/%s', __ADDON_DIR, __CONFIG_FILENAME)
    local f, e = io.open(filePath, 'r')
    if (e) then
      self:Dbg(tostring(e))
      self:Dbg(e)
      return
    end
    f:close()
    local s, e = pcall(dofile, filePath)
    if (not s) then
      self:Err(e)
    end
    -- ローカル変数初期化
    __config = e
    __monitorByHandle = {}
  end

  members.GetPerHP = function(self, handle)
    local stat = info.GetTargetInfo(handle).stat
    return (stat.HP / stat.maxHP) * 100
  end

  members.GetInfo = function(self, handle)
    if (__monitorMode == 0) then
      return nil
    end

    if (__monitorByHandle[handle] == nil) then
      local monster = GetClass("Monster", info.GetMonsterClassName(handle))
      __monitorByHandle[handle] = __config[monster.ClassName]
    end
    return __monitorByHandle[handle]
  end

  members.Check = function(self, handle, monitor)
    local stat = info.GetTargetInfo(handle).stat
    local perHP = (stat.HP / stat.maxHP) * 100
    -- self:Dbg(perHP)

    local sound = ""
    local sendmsg = ""
    local matchedIndex = -1
    for i, _ in ipairs(monitor) do
      local m = monitor[i]
      self:Dbg(m.limit..' -> '..m.msg)
      -- limit <= perHP <= limit
      if (perHP <= m.limit + 1 and perHP >= m.limit) then
        sound = m.sound or ""
        sendmsg = m.msg or ""
        m.limit = -100 -- 一度ヒットしたものはヒットさせないようにする
      end
    end
    return { msg = sendmsg, sound = sound }
  end

  members.Play = function(self, playdata)
    local sound = playdata.sound
    local msg = playdata.msg
    if (sound ~= nil) then
      imcSound.PlaySoundEvent(sound)
    end
    UI_CHAT(msg)
  end

  members.ChangeMode = function(self, mode)
    if (mode == 'on') then
      __monitorMode = 1
      self:Log('hpmonitor is on.')
    elseif (mode == 'off') then
      __monitorMode = 0
      self:Log('hpmonitor is off.')
    end
  end

  -- デストラクター
  members.Destroy = function(self)
    if (g.instance.TARGETINFO_TRANS_HP_VALUE ~= nil) then
      TARGETINFO_TRANS_HP_VALUE = g.instance.TARGETINFO_TRANS_HP_VALUE
      g.instance.TARGETINFO_TRANS_HP_VALUE = nil
    end
    if (g.instance.TARGETINFOTOBOSS_TARGET_SET ~= nil) then
      TARGETINFOTOBOSS_TARGET_SET = g.instance.TARGETINFOTOBOSS_TARGET_SET
      g.instance.TARGETINFOTOBOSS_TARGET_SET = nil
    end
    if (g.instance.UI_CHAT ~= nil) then
      UI_CHAT = g.instance.UI_CHAT
      g.instance.UI_CHAT = nil
    end
  end
  -- おまじない
  return setmetatable(members, {__index = self})
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new})

-- 自フレーム初期化処理
function HPMONITOR_ON_INIT(addon, frame)
  g.instance:Dbg('HPMONITOR_ON_INIT called.')

  if (g.instance.TARGETINFO_TRANS_HP_VALUE == nil) then
    g.instance.TARGETINFO_TRANS_HP_VALUE = TARGETINFO_TRANS_HP_VALUE
  end
  TARGETINFO_TRANS_HP_VALUE = function(handle, hp, fontStyle)
    local perHP = g.instance:GetPerHP(handle)
    return g.instance.TARGETINFO_TRANS_HP_VALUE(handle, hp, fontStyle)
      ..string.format('(%.2f%%)', perHP)
  end

  if (g.instance.TARGETINFOTOBOSS_TARGET_SET == nil) then
    g.instance.TARGETINFOTOBOSS_TARGET_SET = TARGETINFOTOBOSS_TARGET_SET
  end
  TARGETINFOTOBOSS_TARGET_SET = function(frame, msg, argStr, argNum)
    g.instance.TARGETINFOTOBOSS_TARGET_SET(frame, msg, argStr, argNum)
    local handle = argNum
    local monitor = g.instance:GetInfo(handle)
    if (monitor == nil) then
      return
    end
    local playdata = g.instance:Check(handle, monitor)
    g.instance:Play(playdata)
  end

  if (g.instance.UI_CHAT == nil) then
    g.instance.UI_CHAT = UI_CHAT
  end
  UI_CHAT = function(msg)
    local temp = msg
    temp = string.gsub(temp, '/g ', '')
    temp = string.gsub(temp, '/p ', '')
    temp = string.gsub(temp, '/y ', '')
    if (string.find(temp, "/hpm", 1, true) == 1) then
      local mode = string.match(temp, "^/hpm (.+)$")
      g.instance:ChangeMode(mode)
    end
    g.instance.UI_CHAT(msg)
  end

  g.instance:Deserialize()
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy()
end
g.instance = g()
