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
  -- 0: disable
  -- 1: enable
  local __lock = 0
  -- 0: disable
  -- 1: enable
  local __option = 0
  -- 10 - 100
  local __alpha = 80
  -- def: 300
  local __listheight = 300

  -- データ継続保持関連
  local __preserve = 0
  local __preserveCount = 0
  local __preservingData = {}

  local __UpdateToggleButtonText = function(ctrl)
    ctrl:SetText('Count'..((__isCounting == 0) and 'Start' or 'End'))
  end

  local __OptionHeight = function()
    return __listheight + 150
  end

  members.ClearCountingState = function(self)
    __isCounting = 0
  end

  members.CreateUI = function(self)
    local frame = ui.GetFrame('dpsmeter')
    frame:SetLayerLevel(1)
    frame:SetSkinName('downbox')
    frame:Resize(500, __option == 1 and __OptionHeight() or (__minimize == 0 and __listheight or 60))
    frame:SetAlpha(__alpha)
    frame:SetOffset(__config['pos']['x'], __config['pos']['y'])
    frame:EnableMove(math.abs(__lock - 1))
    frame:ShowWindow(1)
    frame:SetLayerLevel(1)
    frame:SetEventScript(ui.LBUTTONUP, 'DPSMETER_ON_ENDMOVE')

    local bg = frame:CreateOrGetControl('groupbox', 'bg', 0, 0, 0, 0)
    tolua.cast(bg, 'ui::CGroupBox')
    bg:SetSkinName('None')
    bg:Resize(frame:GetWidth() - 10, __listheight - 60)
    bg:SetOffset(0, 40)
    bg:EnableScrollBar(1)
    bg:EnableHittestGroupBox(false)

    DPSMETER_ON_TOGGLE_LCLICK = function(frame, ctrl, str, num)
      if (__isCounting == 0) then
        __isCounting = 1
        session.dps.ReqStartDpsPacket()
        frame:RunUpdateScript('DPSMETER_UPDATE', 0, 0, 0, 1)
      else
        session.dps.ReqStopDps()
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
      for k in next, __preservingData do rawset(__preservingData, k, nil) end
    end

    local dpsclear = frame:CreateOrGetControl(
      'button', 'dpsclear', 110, 10, 100, 25)
    dpsclear:SetFontName('white_14_ol')
    dpsclear:SetText('Clear')
    dpsclear:SetEventScript(ui.LBUTTONUP, 'DPSMETER_ON_CLEAR_LCLICK')

    DPSMETER_SELECT_ON_TOGGLE_MODE = function()
      if (__preserve == 1) then
        self:Log('Cant change mode with Preserving.' )
        return
      end
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
        frame:Resize(frame:GetWidth(), __option == 1 and __OptionHeight() or __listheight)
      end
      self:Serialize()
    end
    DPSMETER_SELECT_ON_TOGGLE_OPTIONVIEW = function()
      __option = __option == 0 and 1 or 0
      if (__option == 1) then
        __minimize = 0  -- 最小化状態は強制解除
        frame:Resize(frame:GetWidth(), __OptionHeight())
      else
        frame:Resize(frame:GetWidth(), __listheight)
      end
    end
    DPSMETER_SELECT_ON_TOGGLE_LOCK = function()
      __lock = __lock == 0 and 1 or 0
      frame:EnableMove(math.abs(__lock - 1))
      self:Serialize()
    end
    DPSMETER_SELECT_ON_TOGGLE_PRESERVE = function()
      __preserve = __preserve == 0 and 1 or 0
      for k in next, __preservingData do rawset(__preservingData, k, nil) end
      __preserveCount = 0
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
      if (__preserve == 1) then
        nextModeText = string.gsub(nextModeText, 'To', '*')
      end
      ui.AddContextMenuItem(
        context, nextModeText, 'DPSMETER_SELECT_ON_TOGGLE_MODE')
      -- 描画領域
      ui.AddContextMenuItem(
        context, __minimize == 0 and 'Minimize' or 'Maximize',
          'DPSMETER_SELECT_ON_TOGGLE_FRAMESIZE')
      ui.AddContextMenuItem(
        context, __option == 0 and 'ShowOption' or 'HideOption',
          'DPSMETER_SELECT_ON_TOGGLE_OPTIONVIEW')
      ui.AddContextMenuItem(
        context, __lock == 0 and 'Lock' or 'UnLock',
          'DPSMETER_SELECT_ON_TOGGLE_LOCK')
      -- データ保持
      ui.AddContextMenuItem(
        context, __preserve == 0 and 'Preserve' or 'Un-Preserve',
          'DPSMETER_SELECT_ON_TOGGLE_PRESERVE')

      ui.AddContextMenuItem(context, 'Cancel', 'None')
      ui.OpenContextMenu(context)
    end

    local modeselect = frame:CreateOrGetControl(
      'button', 'modeselect', frame:GetWidth() - 30, 10, 25, 25)
    modeselect:SetFontName('white_14_ol')
    modeselect:SetText('≡')
    modeselect:SetEventScript(ui.LBUTTONUP, 'DPSMETER_ON_MODESELECT_LCLICK')

    -- 隠されたオプション群
    local optiontitle = frame:CreateOrGetControl('richtext', 'optiontitle', 10, __listheight, 0, 0)
    optiontitle:SetFontName('white_14_ol')
    optiontitle:SetText('Options')

    -- 不透明度
    local alphalabel = frame:CreateOrGetControl('richtext', 'alphalabel', 10, __listheight + 30, 0, 0)
    alphalabel:SetFontName('white_14_ol')
    alphalabel:SetText('Alpha')
    alphalabel:SetTextTooltip('Input alpha channel which ranged between 10 and 100. Fromat: number. Ex: 50.')
    local alphainput = frame:CreateOrGetControl('edit', 'alphainput', 85, alphalabel:GetY() - 4, 50, 25)
    tolua.cast(alphainput, 'ui::CEditControl')
		alphainput:SetFontName('white_14_ol')
    alphainput:SetSkinName('test_weight_skin')
    alphainput:SetTextAlign('center', 'center')
    alphainput:SetText(__alpha)
    -- リスト高
    local listheightlabel = frame:CreateOrGetControl('richtext', 'listheightlabel', 10, __listheight + 50, 0, 0)
    listheightlabel:SetFontName('white_14_ol')
    listheightlabel:SetText('ListHeight')
    listheightlabel:SetTextTooltip('Input dps-list height which is required 100 or above. Fromat: number. Ex: 300.')
    local listheightinput =
      frame:CreateOrGetControl('edit', 'listheightinput', 85, listheightlabel:GetY() - 4, 50, 25)
    tolua.cast(listheightinput, 'ui::CEditControl')
		listheightinput:SetFontName('white_14_ol')
    listheightinput:SetSkinName('test_weight_skin')
    listheightinput:SetTextAlign('center', 'center')
    listheightinput:SetText(__listheight)

    DPSMETER_ON_SAVEOPTION_LCLICK = function(frame, ctrl, str, num)
      local alpha = alphainput:GetText()
      alpha = math.min(tonumber(alpha) or 100, 100)
      alpha = math.max(tonumber(alpha) or 10, 10)
      __alpha = alpha

      local listheight = listheightinput:GetText()
      listheight = math.max(tonumber(listheight) or 100, 100)
      __listheight = listheight

      self:Serialize()
      self:CreateUI()
    end
    local saveoption = frame:CreateOrGetControl(
      'button', 'saveoption', 10, __listheight + 100, 100, 25)
    saveoption:SetFontName('white_14_ol')
    saveoption:SetText('Save')
    saveoption:SetEventScript(ui.LBUTTONUP, 'DPSMETER_ON_SAVEOPTION_LCLICK')
  end

  members.Update = function(self, frame)
    -- CHAT_SYSTEM('update'..__isCounting..' - '..session.dps.Get_allDpsInfoSize())
    if (__isCounting == 0) then
      return 0
    end

    local cid = info.GetCID(session.GetMyHandle())

    local dpsInfoSize = session.dps.Get_allDpsInfoSize()

    local dataMerged = __preserve == 1 and __preservingData or {}
    dataMerged[cid] = dataMerged[cid] or {}

    for i = (__preserve == 1 and __preserveCount or 0), dpsInfoSize - 1 do
      local dpsInfo = session.dps.Get_alldpsInfoByIndex(i)
      local unit = dpsInfo:GetName()
      if (__mode == 1) then
        unit = GetClassByType('Skill', dpsInfo:GetSkillID()).Name
      elseif (__mode == 2) then
        unit = dpsInfo:GetName()..'{nl}　<- '..GetClassByType('Skill', dpsInfo:GetSkillID()).Name
      end
      dataMerged[cid][unit] = dataMerged[cid][unit] or {}
      -- 総ダメージ
      dataMerged[cid][unit]['total_damage'] =
        (dataMerged[cid][unit]['total_damage'] or 0) + tonumber(dpsInfo:GetStrDamage())
      -- 総ヒット数
      dataMerged[cid][unit]['total_hit_count'] =
        (dataMerged[cid][unit]['total_hit_count'] or 0) + 1
      -- ヒット回数
      -- 時間をみてDPSになるようにヒット数を調整する
      local isAddedHitCount = 0
      local beforeTime = dataMerged[cid][unit]['temp_time']
      local currentTime = dpsInfo:GetTime().wMilliseconds
      -- CHAT_SYSTEM(i..') '..unit..' - '..tostring(beforeTime)..' <= '..tostring(currentTime))
      if (beforeTime == nil) then
        isAddedHitCount = 1
        dataMerged[cid][unit]['temp_time'] = currentTime
      else
        if (beforeTime <= currentTime) then
          isAddedHitCount = 1
          dataMerged[cid][unit]['temp_time'] = currentTime
        end
      end
      if (isAddedHitCount == 1) then
        dataMerged[cid][unit]['damage_count'] = (dataMerged[cid][unit]['damage_count'] or 0) + 1
      end
    end

    __preserveCount = dpsInfoSize

    tolua.cast(frame:GetChild('bg'), 'ui::CGroupBox'):DeleteAllControl()

    local bg = tolua.cast(frame:GetChild('bg'), 'ui::CGroupBox')
    local titleName = bg:CreateOrGetControl('richtext', 'title_name', 10, 0, 100, 25)
    titleName:SetFontName('white_14_ol')
    titleName:SetText('Name')
    local titleTotal = bg:CreateOrGetControl('richtext', 'title_total', 270, 0, 100, 25)
    titleTotal:SetFontName('white_14_ol')
    titleTotal:SetText('TOTAL')
    local titleDPS = bg:CreateOrGetControl('richtext', 'title_dps', 370, 0, 100, 25)
    titleDPS:SetFontName('white_14_ol')
    titleDPS:SetText('DPS')
    local titleHPS = bg:CreateOrGetControl('richtext', 'title_hps', 440, 0, 100, 25)
    titleHPS:SetFontName('white_14_ol')
    titleHPS:SetText('HPS')

    local line = 0
    for k, v in orderedPairs(dataMerged[cid]) do
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
      damage:SetOffset(180, height)

      local dps = bg:CreateOrGetControl(
        'richtext', 'dps_'..k, 0, height, 100, 25)
      dps:SetFontName('white_14_ol')
      dps:SetText(GET_COMMAED_STRING(string.format('%d', v['total_damage'] / v['damage_count'])))
      dps:SetGravity(ui.RIGHT, ui.TOP)
      dps:SetOffset(90, height)

      local hps = bg:CreateOrGetControl(
        'richtext', 'hps_'..k, 0, height, 100, 25)
      hps:SetFontName('white_14_ol')
      hps:SetText(GET_COMMAED_STRING(string.format('%d', v['total_hit_count'] / v['damage_count'])))
      hps:SetGravity(ui.RIGHT, ui.TOP)
      hps:SetOffset(30, height)

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
      ['state'] = { mode = __mode, minimize = __minimize, preserve = __preserve, lock = __lock },
      ['option'] = { alpha = __alpha, listheight = __listheight },
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
      ['state'] = { mode = 0, minimize = 0, preserve = 0, lock = 0 },
      ['option'] = { alpha = 80, listheight = 300 },
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
    __config['pos'] = e['pos'] or __config['pos']
    __config['state'] = e['state'] or __config['state']
    -- v2.1.1-vu対応
    __config['option'] = e['option'] or __config['option']
    __config['state']['lock'] = __config['state']['lock'] or 0

    __mode = __config['state']['mode']
    __minimize = __config['state']['minimize']
    __preserve = __config['state']['preserve']
    __lock = __config['state']['lock']
    __alpha = __config['option']['alpha']
    __listheight = __config['option']['listheight']
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
  g.instance:ClearCountingState()
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
