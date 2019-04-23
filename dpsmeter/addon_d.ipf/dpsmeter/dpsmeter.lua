-- 領域定義
local author = 'weizlogy'
local addonName = 'dpsmeter'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  -- initialize members.
  local members = {};

  local __ADDON_DIR = '../addons/'..addonName
	local __CONFIG_FILENAME = 'settings.txt'

  -- 0: not counted
  -- 1: counting
  local __isCounting = 0
  -- 0: all
  -- 1: skillby
  -- 2: skill-targetby
  local __mode = 0
  -- 0: disable
  -- 1: enable
  local __minimize = 0

  local __UpdateToggleButtonText = function(ctrl)
    ctrl:SetText('Count'..((__isCounting == 0) and 'Start' or 'End'))
  end

  members.CreateUI = function(self)
    local frame = ui.GetFrame('dpsmeter')
    frame:SetLayerLevel(1)
    frame:SetSkinName('downbox')
    frame:Resize(500, __minimize == 0 and 300 or 60)
    frame:SetAlpha(80)
    frame:SetOffset(__config['pos']['x'], __config['pos']['y'])
    frame:EnableMove(1)
    frame:ShowWindow(1)
    frame:SetEventScript(ui.LBUTTONUP, 'DPSMETER_ON_ENDMOVE')

    local bg = frame:CreateOrGetControl('groupbox', 'bg', 0, 0, 0, 0)
    tolua.cast(bg, 'ui::CGroupBox')
    bg:SetSkinName('None')
    bg:Resize(frame:GetWidth() - 10, 300 - 60)
    bg:SetOffset(0, 40)
    bg:EnableScrollBar(1)
    bg:EnableHittestGroupBox(false)

    DPSMETER_ON_TOGGLE_LCLICK = function(frame, ctrl, str, num)
      if (__isCounting == 0) then
        session.dps.SendStartDpsMsg()
        __isCounting = 1
        frame:RunUpdateScript('DPSMETER_UPDATE', 0, 0, 0, 1)
      else
        session.dps.SendStopDpsMsg()
        __isCounting = 0
      end
      __UpdateToggleButtonText(ctrl)
    end

    local dpstoggle = frame:CreateOrGetControl(
      'button', 'dpstoggle', 10, 10, 100, 25)
    dpstoggle:SetFontName('white_14_ol')
    __UpdateToggleButtonText(dpstoggle)
    dpstoggle:SetEventScript(ui.LBUTTONUP, 'DPSMETER_ON_TOGGLE_LCLICK')

    DPSMETER_ON_CLEAR_LCLICK = function(frame, ctrl, str, num)
      session.dps.Clear_allDpsInfo()
      tolua.cast(frame:GetChild('bg'), 'ui::CGroupBox'):DeleteAllControl()
    end

    local dpsclear = frame:CreateOrGetControl(
      'button', 'dpsclear', 110, 10, 100, 25)
    dpsclear:SetFontName('white_14_ol')
    dpsclear:SetText('Clear')
    dpsclear:SetEventScript(ui.LBUTTONUP, 'DPSMETER_ON_CLEAR_LCLICK')

    DPSMETER_SELECT_ON_TOGGLE_MODE = function()
      if (__mode == 0) then
        __mode = 1
      elseif (__mode == 1) then
        __mode = 2
      else
        __mode = 0
      end
      tolua.cast(frame:GetChild('bg'), 'ui::CGroupBox'):DeleteAllControl()
      self:Serialize()
    end
    DPSMETER_SELECT_ON_TOGGLE_FRAMESIZE = function()
      __minimize = __minimize == 0 and 1 or 0
      if (__minimize == 1) then
        frame:Resize(frame:GetWidth(), 60)
      else
        frame:Resize(frame:GetWidth(), 300)
      end
      self:Serialize()
    end

    DPSMETER_ON_MODESELECT_LCLICK = function(frame, ctrl, str, num)
      local menuTitle = 'DPSMeter'
      local context = ui.CreateContextMenu(
        'CONTEXT_DPSMETER_ON_MENU_SELECT', menuTitle, 0, 0, string.len(menuTitle) * 12, 100)
      -- 表示切り替え
      local nextModeText = 'ToAllMode'
      if (__mode == 0) then
        nextModeText = 'ToSkillByMode'
      elseif (__mode == 1) then
        nextModeText = 'ToSkillAndTargetByMode'
      end
      ui.AddContextMenuItem(
        context, nextModeText, 'DPSMETER_SELECT_ON_TOGGLE_MODE')
      ui.AddContextMenuItem(
        context, __minimize == 0 and 'Minimize' or 'Maximize',
          'DPSMETER_SELECT_ON_TOGGLE_FRAMESIZE')

      ui.AddContextMenuItem(context, 'Cancel', 'None')
      ui.OpenContextMenu(context)
    end

    local modeselect = frame:CreateOrGetControl(
      'button', 'modeselect', frame:GetWidth() - 30, 10, 25, 25)
    modeselect:SetFontName('white_14_ol')
    modeselect:SetText('≡')
    modeselect:SetEventScript(ui.LBUTTONUP, 'DPSMETER_ON_MODESELECT_LCLICK')
  end

  members.Update = function(self, frame)
    -- CHAT_SYSTEM('update'..__isCounting..' - '..session.dps.Get_allDpsInfoSize())
    if (__isCounting == 0) then
      return 0
    end

    local dataMerged = {}
    for i = 1, session.dps.Get_allDpsInfoSize() do
      local dpsInfo = session.dps.Get_alldpsInfoByIndex(i - 1)
      local unit = dpsInfo:GetName()
      if (__mode == 1) then
        unit = GetClassByType('Skill', dpsInfo:GetSkillID()).Name
      elseif (__mode == 2) then
        unit = dpsInfo:GetName()..'{nl}　<- '..GetClassByType('Skill', dpsInfo:GetSkillID()).Name
      end
      dataMerged[unit] = dataMerged[unit] or {}
      -- 総ダメージ
      dataMerged[unit]['total_damage'] =
        (dataMerged[unit]['total_damage'] or 0) + tonumber(dpsInfo:GetStrDamage())
      -- ヒット回数
      -- 時間をみてDPSになるようにヒット数を調整する
      local isAddedHitCount = 0
      local beforeTime = dataMerged[unit]['temp_time']
      local currentTime = dpsInfo:GetTime().wMilliseconds
      -- CHAT_SYSTEM(i..') '..unit..' - '..tostring(beforeTime)..' <= '..tostring(currentTime))
      if (beforeTime == nil) then
        isAddedHitCount = 1
        dataMerged[unit]['temp_time'] = currentTime
      else
        if (beforeTime <= currentTime) then
          isAddedHitCount = 1
          dataMerged[unit]['temp_time'] = currentTime
        end
      end
      if (isAddedHitCount == 1) then
        dataMerged[unit]['damage_count'] = (dataMerged[unit]['damage_count'] or 0) + 1
      end
    end

    tolua.cast(frame:GetChild('bg'), 'ui::CGroupBox'):DeleteAllControl()

    local bg = tolua.cast(frame:GetChild('bg'), 'ui::CGroupBox')
    local titleName = bg:CreateOrGetControl('richtext', 'title_name', 10, 0, 100, 25)
    titleName:SetFontName('white_14_ol')
    titleName:SetText('Name')
    local titleTotal = bg:CreateOrGetControl('richtext', 'title_total', 300, 0, 100, 25)
    titleTotal:SetFontName('white_14_ol')
    titleTotal:SetText('TOTAL')
    local titleDPS = bg:CreateOrGetControl('richtext', 'title_dps', 400, 0, 100, 25)
    titleDPS:SetFontName('white_14_ol')
    titleDPS:SetText('DPS')

    local line = 0
    for k, v in orderedPairs(dataMerged) do
      local height = (20 + ((__mode == 0 or __mode == 1) and 0 or 15)) * line + 20
      local name = bg:CreateOrGetControl(
        'richtext', k, 10, height, 100, 25)
      name:SetFontName('white_14_ol')
      name:SetText(k)

      local damage = bg:CreateOrGetControl(
        'richtext', 'damage_'..k, 0, height, 100, 25)
      damage:SetFontName('white_14_ol')
      damage:SetText(GET_COMMAED_STRING(v['total_damage']))
      damage:SetGravity(ui.RIGHT, ui.TOP)
      damage:SetOffset(150, height)

      local dps = bg:CreateOrGetControl(
        'richtext', 'dps_'..k, 0, height, 100, 25)
      dps:SetFontName('white_14_ol')
      dps:SetText(GET_COMMAED_STRING(string.format('%d', v['total_damage'] / v['damage_count'])))
      dps:SetGravity(ui.RIGHT, ui.TOP)
      dps:SetOffset(50, height)

      line = line + 1
    end

    return 1
  end

	members.Serialize = function(self)
	  local f, e = io.open(string.format(
			'%s/%s', __ADDON_DIR, __CONFIG_FILENAME), 'w')
    if (e) then
      self:Err(tostring(e))
      return
    end

    local frame = ui.GetFrame('dpsmeter')
    __config = {
      ['pos'] = { x = frame:GetX(), y = frame:GetY() },
      ['state'] = { mode = __mode, minimize = __minimize },
    }

    f:write('local s = {}\n')
    for key, values in pairs(__config) do
      f:write(string.format('s[\'%s\'] = {', key))
      for vk, vv in pairs(values) do
    		f:write(string.format(' %s = %s, ', vk, vv))
      end
      f:write('}\n')
    end
    f:write('return s')
    f:flush()
    f:close()
	end

	members.Deserialize = function(self)
    __config = {
      ['pos'] = { x = 100, y = 100 },
      ['state'] = { mode = 0, minimize = 0 },
    }
    local filePath = string.format(
			'%s/%s', __ADDON_DIR, __CONFIG_FILENAME)
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
    __config = e

    __mode = __config['state']['mode']
    __minimize = __config['state']['minimize']
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

-- frame initialize.
function DPSMETER_ON_INIT(addon, frame)
  g.instance:Deserialize()
  g.instance:CreateUI()
end

function DPSMETER_UPDATE(frame, ctrl, str, num)
  return g.instance:Update(frame)
end

function DPSMETER_ON_ENDMOVE(frame, str, num)
  g.instance:Serialize()
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy();
end
g.instance = g();
