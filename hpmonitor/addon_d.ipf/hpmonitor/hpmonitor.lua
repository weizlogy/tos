--* 領域定義
local author = 'weizlogy'
local addonName = 'hpmonitor'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

--* 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

--* コンストラクター
function g.new(self)
  local members = {}

  local __ADDON_DIR = '../addons/'..addonName
  local __CONFIG_FILENAME = 'settings.txt'
  local __LOCATION_FILENAME = 'location.txt'
  local __TRANSPARENCY_FILENAME = 'transparency.txt'
  
  local __config = {}
  local __location = { x = 100, y = 100, w = 300, h = 200}
  local __transparency = 50
  local __monitorByHandle = {}
  local __monitorMode = 1
  local __commentMode = 0

  local __currentComment = ''

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

  --* デシリアライズ
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

  --* HPのパーセンテージ取得
  members.GetPerHP = function(self, handle)
    local stat = info.GetTargetInfo(handle).stat
    return (stat.HP / stat.maxHP) * 100
  end

  --* 対象の情報を取得
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

  --* 
  members.Check = function(self, handle, monitor)
    local stat = info.GetTargetInfo(handle).stat
    local perHP = (stat.HP / stat.maxHP) * 100

    self:Dbg(perHP)

    local sound = ""
    local sendmsg = ""
    local comment = ""
    local matchedIndex = -1

    for i, _ in ipairs(monitor) do
      local m = monitor[i]
      -- limit <= perHP <= limit
      if (perHP <= m.limit + 1 and perHP >= m.limit) then
        self:Dbg(m.limit..' -> '..m.msg)
        -- 複数ヒットした場合は先に音を鳴らす
        if (sound ~= "") then
          imcSound.PlaySoundEvent(sound)
        end
        sound = m.sound or ""
        -- 複数ヒットした場合はメッセージを連結する
        if (sendmsg ~= "") then
          sendmsg = sendmsg .. " / " .. (m.msg or "")
        else
          sendmsg = m.msg or ""
        end
        -- 複数ヒットした場合はCommentModeのチェックだけ先にやらせる
        if (comment ~= "") then
          self:ChangeCommentMode(m.comment)
          comment = m.comment or ""
        else
          comment = comment .. "{nl}" .. (m.comment or "")
        end
        m.limit = -100 -- 一度ヒットしたものはヒットさせないようにする
      end
    end

    return { msg = sendmsg, sound = sound, comment = comment }
  end

  --* 
  members.Play = function(self, playdata)
    local sound = playdata.sound
    local msg = playdata.msg
    local comment = playdata.comment

    self:Dbg(string.format('playdata = [%s] [%s] [%s]', sound, msg, comment))

    if (sound ~= "") then
      self:Dbg('play sound.')
      imcSound.PlaySoundEvent(sound)
    end
    UI_CHAT(msg)

    if (comment ~= "") then
      self:ChangeCommentMode(comment)  -- on, offの指定があれば行う
      __currentComment = comment
    end
  end

  --* 
  members.ChangeMode = function(self, mode)
    if (mode == 'on') then
      __monitorMode = 1
      self:Log('hpmonitor is on.')
    elseif (mode == 'off') then
      __monitorMode = 0
      self:Log('hpmonitor is off.')
    end
  end
  --* 
  members.ChangeCommentMode = function(self, mode)
    self:Dbg('ChangeCommentMode ' .. mode)

    if (mode == 'on') then
      __commentMode = 1
      self:Log('comment function is on.')
    elseif (mode == 'off') then
      __commentMode = 0
      self:Log('comment function is off.')
    elseif (mode == 'clear') then
      __currentComment = ''
      self:Log('comment clear.')
    end
    ui.GetFrame(addonName):ShowWindow(__commentMode)
  end

  --*
  members.InitCommentFrame = function(self)
    self:Dbg('InitCommentFrame start.')

    self:LoadLocation()

    local frame = ui.GetFrame(addonName)

    _HPMONITOR_RESIZE = function()
      frame:CancelReserveScript("HPMONITOR_END_RESIZE")
      frame:ReserveScript("HPMONITOR_END_RESIZE", 0.3, 0, '')
    end

    frame:SetSkinName("downbox")
    frame:SetEventScript(ui.LBUTTONUP, "HPMONITOR_END_DRAG")
    frame:SetEventScript(ui.RBUTTONUP, "HPMONITOR_OPEN_MENU")
    frame:SetEventScript(ui.MOUSEWHEEL, "HPMONITOR_END_WHEEL")
    frame:SetAlpha(__transparency)
    frame:EnableMove(1)
    frame:SetOffset(__location.x, __location.y)
    frame:Resize(__location.w, __location.h)
    frame:ShowWindow(__commentMode)

    local margin = 10
    local textCtrl = frame:CreateOrGetControl(
      "richtext", "text", margin, margin, __location.w - margin, __location.h - margin)
    textCtrl:SetFontName('white_16_ol')

    HPMONITOR_COMMENT_WATCHER = function()
      textCtrl:SetText(__currentComment)
      return 1
    end
    frame:RunUpdateScript('HPMONITOR_COMMENT_WATCHER', 0, 0, 0, 0.9)

    self:Dbg('InitCommentFrame end.')
  end

  --*
  members.SaveLocation = function(self)
    local frame = ui.GetFrame(addonName)
    __location.x = frame:GetX()
    __location.y = frame:GetY()
    __location.w = frame:GetWidth()
    __location.h = frame:GetHeight()

    local filePath = string.format('%s/%s', __ADDON_DIR, __LOCATION_FILENAME)
    local f, e = io.open(filePath, "w")
    if (f == nil) then
      self:Err(e)
      return
    end
    f:write(string.format('return { x = %d, y = %d, w = %d, h = %d }',
     __location.x, __location.y, __location.w, __location.h))
    f:flush()
    f:close()
  end
  --*
  members.LoadLocation = function(self)
    local filePath = string.format('%s/%s', __ADDON_DIR, __LOCATION_FILENAME)
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
    __location = e
  end

  --*
  members.ChangeTransparency = function(self, frame, delta)
    if (__transparency < 20 or __transparency > 100) then
      return
    end
    if (delta > 0) then
      __transparency = __transparency + 1
    elseif (delta < 0) then
      __transparency = __transparency - 1
    else
      self:Log('delta is 0.')
    end
    frame:SetAlpha(__transparency)
  end
  --*
  members.SaveTransparency = function(self)
    self:Log(string.format('Transparency -> %d', __transparency))
    local filePath = string.format('%s/%s', __ADDON_DIR, __TRANSPARENCY_FILENAME)
    local f, e = io.open(filePath, "w")
    if (f == nil) then
      self:Err(e)
      return
    end
    f:write(string.format('return %d', __transparency))
    f:flush()
    f:close()
  end
  --*
  members.LoadTransparency = function(self)
    local filePath = string.format('%s/%s', __ADDON_DIR, __TRANSPARENCY_FILENAME)
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
    __transparency = e
  end

  --* 
  members.TestMode = function(self, mode)
    if (mode == 'temp') then
      __currentComment = '{#FF0000}{s20}{ol}bbb{/}{/}{/}ccc'
    end
  end

  --* デストラクター
  members.Destroy = function(self)
    if (g.instance.TARGETINFO_TRANS_HP_VALUE ~= nil) then
      TARGETINFO_TRANS_HP_VALUE = g.instance.TARGETINFO_TRANS_HP_VALUE
      g.instance.TARGETINFO_TRANS_HP_VALUE = nil
    end
    -- if (g.instance.TARGETINFOTOBOSS_TARGET_SET ~= nil) then
    --   TARGETINFOTOBOSS_TARGET_SET = g.instance.TARGETINFOTOBOSS_TARGET_SET
    --   g.instance.TARGETINFOTOBOSS_TARGET_SET = nil
    -- end
    -- if (g.instance.TGTINFO_TARGET_SET ~= nil) then
    --   TGTINFO_TARGET_SET = g.instance.TGTINFO_TARGET_SET
    --   g.instance.TGTINFO_TARGET_SET = nil
    -- end
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

--* 自フレーム初期化処理
function HPMONITOR_ON_INIT(addon, frame)
  g.instance:Dbg('HPMONITOR_ON_INIT called.')

  if (g.instance.TARGETINFO_TRANS_HP_VALUE == nil) then
    g.instance.TARGETINFO_TRANS_HP_VALUE = TARGETINFO_TRANS_HP_VALUE
  end
  TARGETINFO_TRANS_HP_VALUE = function(handle, hp, fontStyle)
    -- 
    local monitor = g.instance:GetInfo(handle)
    if (monitor ~= nil) then
      local playdata = g.instance:Check(handle, monitor)
      g.instance:Play(playdata)
    end
    -- HP監視本体
    local perHP = g.instance:GetPerHP(handle)
    return g.instance.TARGETINFO_TRANS_HP_VALUE(handle, hp, fontStyle)
      ..string.format('(%.2f%%)', perHP)
  end

  -- if (g.instance.TARGETINFOTOBOSS_TARGET_SET == nil) then
  --   g.instance.TARGETINFOTOBOSS_TARGET_SET = TARGETINFOTOBOSS_TARGET_SET
  -- end
  -- TARGETINFOTOBOSS_TARGET_SET = function(frame, msg, argStr, argNum)
  --   g.instance.TARGETINFOTOBOSS_TARGET_SET(frame, msg, argStr, argNum)
  --   local handle = session.GetTargetHandle()
  --   local monitor = g.instance:GetInfo(handle)
  --   if (monitor == nil) then
  --     return
  --   end
  --   local playdata = g.instance:Check(handle, monitor)
  --   g.instance:Play(playdata)
  -- end

  -- -- テスト用にボスじゃなくても動くように
  -- if (g.instance.TGTINFO_TARGET_SET == nil) then
  --   g.instance.TGTINFO_TARGET_SET = TGTINFO_TARGET_SET
  -- end
  -- TGTINFO_TARGET_SET = function(frame, msg, argStr, argNum)
  --   g.instance.TGTINFO_TARGET_SET(frame, msg, argStr, argNum)
  --   local handle = session.GetTargetHandle()
  --   local monitor = g.instance:GetInfo(handle)
  --   if (monitor == nil) then
  --     return
  --   end
  --   local playdata = g.instance:Check(handle, monitor)
  --   g.instance:Play(playdata)
  -- end

  if (g.instance.UI_CHAT == nil) then
    g.instance.UI_CHAT = UI_CHAT
  end
  UI_CHAT = function(msg)
    local temp = msg
    temp = string.gsub(temp, '/g ', '')
    temp = string.gsub(temp, '/p ', '')
    temp = string.gsub(temp, '/y ', '')
 
    if (string.find(temp, "/hpm comment", 1, true) == 1) then
      local mode = string.match(temp, "^/hpm comment (.+)$")
      g.instance:ChangeCommentMode(mode)
    elseif (string.find(temp, "/hpm test", 1, true) == 1) then
      local mode = string.match(temp, "^/hpm test (.+)$")
      g.instance:TestMode(mode)
    elseif (string.find(temp, "/hpm", 1, true) == 1) then
      local mode = string.match(temp, "^/hpm (.+)$")
      g.instance:ChangeMode(mode)
    end
    g.instance.UI_CHAT(msg)
  end

  g.instance:Deserialize()

  g.instance:InitCommentFrame()
end

--*
function HPMONITOR_END_DRAG()
  g.instance:SaveLocation()
end
--*
function HPMONITOR_END_RESIZE()
  g.instance:SaveLocation()
end
--*
function HPMONITOR_END_WHEEL(frame, ctrl, delta, argNum)
  g.instance:ChangeTransparency(frame, delta)
  frame:CancelReserveScript("HPMONITOR_END_WHEEL_AFTER")
  frame:ReserveScript("HPMONITOR_END_WHEEL_AFTER", 0.3, 0, '')
end
--*
function HPMONITOR_END_WHEEL_AFTER()
  g.instance:SaveTransparency()
end
--*
function HPMONITOR_OPEN_MENU()
  local menuTitle = 'HPMONITOR comment'
  local context = ui.CreateContextMenu(
    'CONTEXT_HPMONITOR_COMMENT', menuTitle, 0, 0, string.len(menuTitle) * 12, 100)
  -- メニューイベントハンドラー
  HPMONITOR_MENU_COMMENT_CLEAR = function()
    g.instance:ChangeCommentMode('clear')
  end
  HPMONITOR_MENU_COMMENT_CLOSE = function()
    g.instance:ChangeCommentMode('off')
  end
  -- 画面表示
  ui.AddContextMenuItem(context, 'Clear', 'HPMONITOR_MENU_COMMENT_CLEAR')
  ui.AddContextMenuItem(context, 'Close', 'HPMONITOR_MENU_COMMENT_CLOSE')
  ui.AddContextMenuItem(context, 'Cancel', 'None')
  ui.OpenContextMenu(context)
end

--* インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy()
end
g.instance = g()
