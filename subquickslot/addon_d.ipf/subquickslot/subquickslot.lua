-- 領域定義
local author = 'weizlogy'
local addonName = 'subquickslot'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- 個別フレームのコンストラクター
function g.new(self)
  local members = {};

  -- === 公開定数 === --
  members.GLOBALVALUE_LIFTICON_CATEGORY = 'category-lifticon'
  members.GLOBALVALUE_LIFTICON_TYPE = 'type-lifticon'
  members.GLOBALVALUE_LIFTICON_FROMINDEX = 'fromindex-lifticon'

  -- === 定数 === --
  local __ADDON_DIR = '../addons/'..addonName
  local __OPTION_FRAME_NAME = addonName..'_option'

  local __USERVALUE_FRAME_INDEX = 'frameindex'
  local __USERVALUE_SLOT_CATEGORY = 'category'
  local __USERVALUE_SLOT_TYPE = 'type'
  local __USERVALUE_FRAME_IS_COMMON = 'iscommon'

  local __CONFIG_FRAME_INDEXIES = 'frameindexies'
  local __CONFIG_SLOT_CATEGORY = 'category'
  local __CONFIG_SLOT_TYPE = 'type'
  local __CONFIG_SLOT_IESID = 'iesid'
  local __CONFIG_SLOTSET_SIZE = 'size'
  local __CONFIG_SLOTSET_ALPHA = 'alpha'
  local __CONFIG_SLOTSET_ALPHASLOT = 'alphaslot'
  local __CONFIG_SLOTSET_LOCK = 'lock'
  local __CONFIG_SLOTSET_POS = 'pos'
  local __CONFIG_SLOTSET_MAGNI = 'magnification'
  local __CONFIG_SLOTSET_NOTIFY_CLASSID = 'nofifyclassid'
  local __CONFIG_SLOTSET_DIRECT_WARP = 'directwarp'
  local __CONFIG_SLOTSET_SHOW = 'show'

  local __CONFIG_COMMON_FRAME_FILENAME = 'commonslot'

  -- === 内部データ === --
  local __cid = ''
  local __config = {}
  local __commmon = {}

  -- === 内部関数 === --
  local GetConfigByFrameKey = function(index)
    return 'frame'..index
  end
  local GetFrameKeyByFrameName = function(frameName)
    return string.match(frameName, '^.-%-(%d+)$')
  end
  local GetDataFromFrame = function(frame)
    if (frame:GetUserValue(__USERVALUE_FRAME_IS_COMMON) == '1') then
      return __commmon
    end
    return __config
  end
  local CreateNotInInventoryItemImage = function(icon, category, type, iesid)
    icon:Set(GET_ITEM_ICON_IMAGE(GetClassByType('Item', type)), category, type, 0, iesid)
    icon:SetTooltipType('wholeitem')
    icon:SetTooltipNumArg(type)
    icon:SetTooltipIESID(iesid)
    icon:SetColorTone('FFFF0000')
  end
  local CreateLabeledEditCtrl = function(frame, key, labelText, x, y, tooltip)
    local label = frame:CreateOrGetControl('richtext', key..'label', x, y, 0, 0)
    label:SetFontName('white_16_ol')
    label:SetText(labelText)
    label:SetTextTooltip(tooltip)
    local input = frame:CreateOrGetControl(
      'edit', key..'input', label:GetWidth() + 10, label:GetY() - 4, 50, 25)
    tolua.cast(input, 'ui::CEditControl')
		input:SetFontName('white_16_ol')
    input:SetSkinName('test_weight_skin')
    input:SetTextAlign('center', 'center')
    return input
  end
  local MyMoveIntoClientRegion = function(frame, x, y)
    local clientInitWidth = ui.GetClientInitialWidth()  -- 1920
    local clientInitHeight = ui.GetClientInitialHeight()  -- 1080
    local sceneWidth = ui.GetSceneWidth()  -- 実画面サイズ
    local sceneHeight = ui.GetSceneHeight()  -- 実画面サイズ
    -- 最大値計算
    local maxWidth = math.max(clientInitWidth, math.max(sceneWidth, sceneWidth * clientInitHeight / sceneHeight))
    local maxHeight = math.max(clientInitHeight, sceneHeight)
    -- オーバーラップ抑止
    local movex = x
    local movey = y
    if (x + frame:GetWidth() > maxWidth) then
      movex = maxWidth - frame:GetWidth()
    end
    if (y + frame:GetHeight() > maxHeight) then
      movey = maxHeight - frame:GetHeight()
    end
    -- CHAT_SYSTEM(x..' / '..y..' | '..maxWidth..' / '..maxHeight..' => '..movex..' / '..movey)
    -- 移動
    frame:SetOffset(movex, movey)
  end
  local GetCategoryFromLiftIconInfo = function(info)
    local category = info.GetCategory and info:GetCategory()
    if (category == 'None' or not category) then
      category = info.category
    end
    return category
  end

  -- === 公開関数 === --
  -- 全フレームを読み込む
  members.CreateFrames = function(self)
    self:Dbg('CreateFrames called.')

    -- CID紐づけ分
    __cid = info.GetCID(session.GetMyHandle())
    __config = self:Deserialize(__cid) or {}

    for index in string.gmatch(__config[__CONFIG_FRAME_INDEXIES] or '1', "%S+") do
      self:CreateFrame(index)
    end

    -- 共通分
    __commmon = self:Deserialize(__CONFIG_COMMON_FRAME_FILENAME) or {}

    for index in string.gmatch(__commmon[__CONFIG_FRAME_INDEXIES] or '1', "%S+") do
      self:CreateFrame(index, true)
    end
  end

  -- 全フレームのアイテム数を更新
  members.RedrawFrames = function(self, isCommon)
    self:Dbg('RedrawFrames called.')

    local target = __config
    if (isCommon) then
      target = __commmon
    end

    for frameIndex in string.gmatch(target[__CONFIG_FRAME_INDEXIES] or '1', "%S+") do
      local frame = ui.GetFrame(addonName..'-'..frameIndex)
      self:Dbg('Redrawing... target='..frame:GetName())
      local slotset = GET_CHILD(frame, 'slotset', 'ui::CSlotSet')

      for k, v in pairs(target[GetConfigByFrameKey(frameIndex)]) do
        local index = string.match(k, 'slot(%d+)')
        local category = v[__CONFIG_SLOT_CATEGORY]
        local type = v[__CONFIG_SLOT_TYPE]
        local iesid = v[__CONFIG_SLOT_IESID]
        if (index and category == 'Item') then
          local slot = slotset:GetSlotByIndex(index)
          local invItem = session.GetInvItemByGuid(iesid) or session.GetInvItemByType(type)
          if (not invItem) then
            self:Dbg('change count to '..0)
            CreateNotInInventoryItemImage(CreateIcon(slot), category, type, iesid)
            SET_SLOT_COUNT_TEXT(slot, 0)
          else
            self:Dbg('change count => '..invItem.count)
            SET_SLOT_ITEM_IMAGE(slot, invItem)
            SET_SLOT_ITEM_TEXT(slot, invItem, GetClassByType('Item', type))
            CreateIcon(slot):SetColorTone('FFFFFFFF')
          end
        end
      end
      self:Dbg('Finish redraw... target='..frame:GetName())
    end
  end

  -- 全フレームのスキル特性のON/OFFを更新
  members.RedrawSkillAbilityFrames = function(self, className, isCommon)
    self:Dbg('RedrawSkillAbilityFrames called.')

    local target = __config
    if (isCommon) then
      target = __commmon
    end

    for frameIndex in string.gmatch(target[__CONFIG_FRAME_INDEXIES] or '1', "%S+") do
      local frame = ui.GetFrame(addonName..'-'..frameIndex)
      self:Dbg('Redrawing... target='..frame:GetName()..' ability='..className)
      local slotset = GET_CHILD(frame, 'slotset', 'ui::CSlotSet')

      for k, v in pairs(target[GetConfigByFrameKey(frameIndex)]) do
        local index = string.match(k, 'slot(%d+)')
        local category = v[__CONFIG_SLOT_CATEGORY]
        local type = v[__CONFIG_SLOT_TYPE]
        if (index and category == 'Ability') then
          -- 特性の状態が変化したものだけを対象にする
          local abilClass = GetClassByType("Ability", type)
          if (abilClass.ClassName == className) then
            local slot = slotset:GetSlotByIndex(index)
            SET_ABILITY_TOGGLE_COLOR(CreateIcon(slot), type)
          end
        end
      end
      self:Dbg('Finish redraw... target='..frame:GetName())
    end
  end

  -- シリアライズ
  members.Serialize = function(self, fileName, dataObj)
    self:Dbg('Serialize called. '..fileName)

    local filePath = string.format('%s/%s', __ADDON_DIR, fileName)
    local f, e = io.open(filePath, 'w')
    if (e) then
      self:Err('Failed to save option to file.'..fileName)
      self:Err(tostring(e))
      return
    end

    -- localを再帰で使うための
    local recursive; recursive = function(key, value, depth)
      local indent = string.rep(' ', depth)
      if (type(value) == 'table') then
        f:write(string.format('%s[\'%s\'] = %s\n', indent, key, '{'))
        for k, v in pairs(value) do
          recursive(k, v, depth + 2)
        end
        f:write(indent..'},\n')
      elseif (value ~= nil) then
        f:write(string.format('%s[\'%s\'] = \'%s\',\n', indent, key, value))
      end
    end

    f:write('local s = {\n')
    for k, v in pairs(dataObj) do
      recursive(k, v, 2)
    end
    f:write('}\n')
    f:write('return s')
    f:flush()
    f:close()
    self:Dbg('Save option to file.'..fileName)
  end

  -- デシリアライズ
  members.Deserialize = function(self, fileName)
    self:Dbg('Deserialize called. '..fileName)

    local filePath = string.format('%s/%s', __ADDON_DIR, fileName)
    local f, e = io.open(filePath, 'r')
    if (e) then
      self:Dbg('Nothing to load option from file.')
      return nil
    end
    f:close()
    local s, e = pcall(dofile, filePath)
    if (not s) then
      self:Err(e)
    end
    return e
  end

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

  -- フレーム作成
  members.CreateFrame = function(self, frameIndex, isCommon)
    self:Dbg('CreateFrame called. '..frameIndex)

    local config = __config
    if (isCommon) then
      config = __commmon
    end

    local configKey = GetConfigByFrameKey(frameIndex)
    config[configKey] = config[configKey]
    -- 設定がない場合は index == 1 のスロットから設定をいくつか継承する
    if (not config[configKey]) then
      config[configKey] = {}
      local baseConfig = __config[GetConfigByFrameKey(1)]
      if (baseConfig) then
        -- 継承するのは、倍率/透過度2種
        config[configKey][__CONFIG_SLOTSET_MAGNI] = baseConfig[__CONFIG_SLOTSET_MAGNI]
        config[configKey][__CONFIG_SLOTSET_ALPHA] = baseConfig[__CONFIG_SLOTSET_ALPHA]
        config[configKey][__CONFIG_SLOTSET_ALPHASLOT] = baseConfig[__CONFIG_SLOTSET_ALPHASLOT]
      end
    end

    -- スロットサイズ解析
    local slotw, sloth = string.match(config[configKey][__CONFIG_SLOTSET_SIZE] or '1x1', '(%d+)x(%d+)')
    self:Dbg('creating slot => '..slotw..' x '..sloth)
    local slotsize = 48 * (tonumber(config[configKey][__CONFIG_SLOTSET_MAGNI] or '100') / 100)
    -- ロック状態取得
    local lockstate = tonumber(config[configKey][__CONFIG_SLOTSET_LOCK] or '0')
    self:Dbg('lockstate => '..lockstate)

    local frame = ui.CreateNewFrame(addonName, addonName..'-'..frameIndex)
    frame:SetUserValue(__USERVALUE_FRAME_INDEX, frameIndex)
    frame:SetSkinName('downbox')
    frame:SetEventScript(ui.RBUTTONUP, 'SUBQUICKSLOT_ON_SHOWMENU')
    frame:SetEventScript(ui.LBUTTONUP, 'SUBQUICKSLOT_ON_ENDMOVE')
    frame:SetAlpha(string.match(config[configKey][__CONFIG_SLOTSET_ALPHA] or '100', '^(%d+)$'))
    local frameX, frameY = string.match(config[configKey][__CONFIG_SLOTSET_POS] or '200x200', '(%d+)x(%d+)')
    frame:Resize(slotw * slotsize + 20, sloth * slotsize + 20)
    frame:SetOffset(frameX, frameY)
    frame:EnableMove(math.abs(lockstate - 1))
    -- スロット作成
    DESTROY_CHILD_BYNAME(frame, 'slotset')
    local slotset = frame:CreateOrGetControl('slotset', 'slotset', 10, 10, 0, 0)
    tolua.cast(slotset, 'ui::CSlotSet')
    slotset:SetSlotSize(slotsize, slotsize)  -- スロットの大きさ
    slotset:EnablePop(math.abs(lockstate - 1))
    slotset:EnableDrag(math.abs(lockstate - 1))
    slotset:EnableDrop(math.abs(lockstate - 1))
  	slotset:SetColRow(slotw, sloth)  -- スロットの配置と個数
  	slotset:SetSpc(0, 0)
  	slotset:SetSkinName('slot')
    slotset:SetEventScript(ui.DROP, 'SUBQUICKSLOT_ON_DROPSLOT')
    slotset:SetEventScript(ui.POP, 'SUBQUICKSLOT_ON_POPSLOT')
  	slotset:EnableSelection(0)
  	slotset:CreateSlots()

    if (isCommon) then
      -- 共通って分かるようにフラグたて
      frame:SetUserValue(__USERVALUE_FRAME_IS_COMMON, '1')
      -- 共通って分かるような見た目
      local titlelabel = frame:CreateOrGetControl('richtext', 'titlelabel', 0, 0, 0, 0)
      titlelabel:SetFontName('white_16_ol')
      titlelabel:SetTextAlign('center', 'center')
      titlelabel:SetGravity(ui.CENTER_HORZ, ui.TOP)
      titlelabel:SetText('★')
    end

    self:Dbg('createed slot.')
    for i = 0, slotw * sloth - 1 do
      local slot = slotset:GetSlotByIndex(i)
      slot:SetAlpha(string.match(config[configKey][__CONFIG_SLOTSET_ALPHASLOT] or '100', '^(%d+)$'))
    end
    -- スロット復元
    for k, v in pairs(config[configKey]) do
      local index = string.match(k, 'slot(%d+)')
      if (index) then
        local dummyLiftIconInfo = {}
        dummyLiftIconInfo.category = v[__CONFIG_SLOT_CATEGORY]
        dummyLiftIconInfo.type = v[__CONFIG_SLOT_TYPE]
        dummyLiftIconInfo.GetIESID = function(self)
          return v[__CONFIG_SLOT_IESID]
        end
        -- 設定がバグっても大丈夫なように回避を入れる
        local slot = slotset:GetSlotByIndex(index)
        if (not slot) then
          config[configKey][k] = nil
        else
          self:SetSubSlot(slot, dummyLiftIconInfo)
        end
      end
    end
    self:Dbg('recovered slot.')
    -- タイマー作成
    -- OH用
    local timer = frame:CreateOrGetControl('timer', 'addontimer', 0, 0, 0, 0)
    tolua.cast(timer, 'ui::CAddOnTimer')
  	timer:SetUpdateScript('SUBQUICKSLOT_ON_UPDATE_OVERHEAT')
  	timer:Start(0.3)
    -- ディスペラー系スクロールエフェクト用
    frame:CreateOrGetControl('timer', 'jungtantimer', 0, 0, 0, 0)
    frame:CreateOrGetControl('timer', 'jungtandeftimer', 0, 0, 0, 0)
    frame:CreateOrGetControl('timer', 'dispeldebufftimer', 0, 0, 0, 0)
    self:Dbg('created timers.')

    frame:ShowWindow(tonumber(config[configKey][__CONFIG_SLOTSET_SHOW] or '1'))
  end

  -- フレーム削除
  members.DeleteFrame = function(self, frameIndex, isCommon)
    self:Dbg('DeleteFrame called.')

    ui.DestroyFrame(addonName..'-'..frameIndex)

    if (isCommon) then
      __commmon[GetConfigByFrameKey(frameIndex)] = nil
    else
      __config[GetConfigByFrameKey(frameIndex)] = nil
    end
  end

  -- フレーム非表示
  members.HideFrame = function(self, frameIndex, isCommon)
    self:Dbg('HideFrame called. frameIndex='..frameIndex)

    local frame = ui.GetFrame(addonName..'-'..frameIndex)
    frame:ShowWindow(0)

    local target = __config
    if (isCommon) then
      target = __commmon
    end
    target[GetConfigByFrameKey(frameIndex)][__CONFIG_SLOTSET_SHOW] = '0'

    if (isCommon) then
      self:Serialize(__CONFIG_COMMON_FRAME_FILENAME, __commmon)
    else
      self:Serialize(__cid, __config)
    end
  end
  
  -- オプションフレーム作成
  members.CreateOptionFrame = function(self, frameIndex, x, y, isCommon)
    self:Dbg('CreateOptionFrame called. index='..frameIndex)

    local target = __config
    if (isCommon) then
      target = __commmon
    end

    local frame = ui.CreateNewFrame(addonName, __OPTION_FRAME_NAME)
    frame:SetUserValue(__USERVALUE_FRAME_INDEX, frameIndex)
    if (isCommon) then
      frame:SetUserValue(__USERVALUE_FRAME_IS_COMMON, '1')
    end
    frame:SetEventScript(ui.LOST_FOCUS, "SUBQUICKSLOT_ON_LOSTFOCUSOPTION")
    frame:SetLayerLevel(999)
    frame:SetSkinName('test_frame_low')
    frame:Resize(250, 250)
    MyMoveIntoClientRegion(frame, x, y)
    -- タイトル
    local titlelabel = frame:CreateOrGetControl('richtext', 'titlelabel', 0, 14, 0, 0)
    titlelabel:SetFontName('white_16_ol')
    titlelabel:SetTextAlign('center', 'center')
    titlelabel:SetGravity(ui.CENTER_HORZ, ui.TOP)
    titlelabel:SetText(string.format('SubQuickSlot-%s Options', frameIndex))
    CreateLabeledEditCtrl(
      frame, 'size', 'VxH  ', 10, 45, 'Input slot size, what you want. Fromat: <vertial>x<horizon>. Ex: 2x4.'):SetText(target[GetConfigByFrameKey(frameIndex)][__CONFIG_SLOTSET_SIZE] or '1x1')
    -- 不透明度
    local alphalabel = frame:CreateOrGetControl('richtext', 'alphalabel', 10, 75, 0, 0)
    alphalabel:SetFontName('white_16_ol')
    alphalabel:SetText('Alpha')
    alphalabel:SetTextTooltip('Input alpha channel which ranged between 10 and 100. Left is background and the other is slot. Fromat: number. Ex: 50.')
    local alphainput = frame:CreateOrGetControl('edit', 'alphainput', 55, alphalabel:GetY() - 4, 50, 25)
    tolua.cast(alphainput, 'ui::CEditControl')
		alphainput:SetFontName('white_16_ol')
    alphainput:SetSkinName('test_weight_skin')
    alphainput:SetTextAlign('center', 'center')
    alphainput:SetText(target[GetConfigByFrameKey(frameIndex)][__CONFIG_SLOTSET_ALPHA] or '100')
    local alphaslotinput =
      frame:CreateOrGetControl('edit', 'alphaslotinput', alphainput:GetX() + alphainput:GetWidth() + 5, alphainput:GetY(), alphainput:GetWidth(), 25)
    tolua.cast(alphaslotinput, 'ui::CEditControl')
		alphaslotinput:SetFontName('white_16_ol')
    alphaslotinput:SetSkinName('test_weight_skin')
    alphaslotinput:SetTextAlign('center', 'center')
    alphaslotinput:SetText(target[GetConfigByFrameKey(frameIndex)][__CONFIG_SLOTSET_ALPHASLOT] or '100')
    -- 倍率
    CreateLabeledEditCtrl(
      frame, 'magni', 'Magni', 10, 105, 'Input slot magnification which ranged between 50 and 100.')
        :SetText(target[GetConfigByFrameKey(frameIndex)][__CONFIG_SLOTSET_MAGNI] or '100')
    -- ロック状態
    local lockcheck = frame:CreateOrGetControl('checkbox', 'lockcheck', 10, 135, 0, 0)
    tolua.cast(lockcheck, 'ui::CCheckBox')
    lockcheck:SetFontName('white_16_ol')
    lockcheck:SetText('Lock')
    lockcheck:SetTextTooltip('If you check, the slot is lock.')
    lockcheck:SetCheck(tonumber(target[GetConfigByFrameKey(frameIndex)][__CONFIG_SLOTSET_LOCK] or '0'))
    -- ID通知
    local notifyidcheck = frame:CreateOrGetControl('checkbox', 'notifyidcheck', 10, 165, 0, 0)
    tolua.cast(notifyidcheck, 'ui::CCheckBox')
    notifyidcheck:SetFontName('white_16_ol')
    notifyidcheck:SetText('Notify ClassID')
    notifyidcheck:SetTextTooltip('If you check, notify ClassID with SystemChat when set on slot.')
    notifyidcheck:SetCheck(tonumber(target[GetConfigByFrameKey(frameIndex)][__CONFIG_SLOTSET_NOTIFY_CLASSID] or '0'))
    -- ワープ確認ダイアログON/OFF
    local directwarpcheck = frame:CreateOrGetControl('checkbox', 'directwarpcheck', 10, 195, 0, 0)
    tolua.cast(directwarpcheck, 'ui::CCheckBox')
    directwarpcheck:SetFontName('white_16_ol')
    directwarpcheck:SetText('DirectWaap')
    directwarpcheck:SetTextTooltip('If you check, you can warp immediately.')
    directwarpcheck:SetCheck(tonumber(target[GetConfigByFrameKey(frameIndex)][__CONFIG_SLOTSET_DIRECT_WARP] or '1'))

    frame:ShowWindow(1)
  end

  -- 設定保存＋フレーム非表示
  members.CloseOptionFrame = function(self)
    self:Dbg('CloseOptionFrame called.')

    local frame = ui.GetFrame(__OPTION_FRAME_NAME)
    local frameIndex = frame:GetUserValue(__USERVALUE_FRAME_INDEX)
    local isCommon = frame:GetUserValue(__USERVALUE_FRAME_IS_COMMON)

    local target = __config
    if (isCommon) then
      target = __commmon
    end

    -- 設定取得
    local size = GET_CHILD(frame, 'sizeinput', 'ui::CEditControl'):GetText()
    local alpha = GET_CHILD(frame, 'alphainput', 'ui::CEditControl'):GetText()
    alpha = math.min(tonumber(alpha) or 100, 100)
    alpha = math.max(tonumber(alpha) or 10, 10)
    local alphaslot = GET_CHILD(frame, 'alphaslotinput', 'ui::CEditControl'):GetText()
    alphaslot = math.min(tonumber(alphaslot) or 100, 100)
    alphaslot = math.max(tonumber(alphaslot) or 10, 10)
    local magni = GET_CHILD(frame, 'magniinput', 'ui::CEditControl'):GetText()
    magni = math.min(tonumber(magni) or 100, 100)
    magni = math.max(tonumber(magni) or 50, 50)
    local lock = GET_CHILD(frame, 'lockcheck', 'ui::CCheckBox'):IsChecked()
    local notifyid = GET_CHILD(frame, 'notifyidcheck', 'ui::CCheckBox'):IsChecked()
    local directwarp = GET_CHILD(frame, 'directwarpcheck', 'ui::CCheckBox'):IsChecked()
    -- 再描画判定
    local configKey = GetConfigByFrameKey(frameIndex)
    local redraw =
      target[configKey][__CONFIG_SLOTSET_SIZE] ~= size
      or target[configKey][__CONFIG_SLOTSET_ALPHA] ~= alpha
      or target[configKey][__CONFIG_SLOTSET_ALPHASLOT] ~= alphaslotinput
      or target[configKey][__CONFIG_SLOTSET_MAGNI] ~= magni
      or target[configKey][__CONFIG_SLOTSET_LOCK] ~= lock
      or target[configKey][__CONFIG_SLOTSET_NOTIFY_CLASSID] ~= notifyid
      or target[configKey][__CONFIG_SLOTSET_DIRECT_WARP] ~= directwarp
      -- 設定保存
      target[configKey][__CONFIG_SLOTSET_SIZE] = size
    self:Dbg('size='..size)
    target[configKey][__CONFIG_SLOTSET_ALPHA] = alpha
    self:Dbg('alpha='..alpha)
    target[configKey][__CONFIG_SLOTSET_ALPHASLOT] = alphaslot
    self:Dbg('alpha='..alpha)
    target[configKey][__CONFIG_SLOTSET_MAGNI] = magni
    self:Dbg('magni='..magni)
    target[configKey][__CONFIG_SLOTSET_LOCK] = lock
    self:Dbg('lock='..lock)
    target[configKey][__CONFIG_SLOTSET_NOTIFY_CLASSID] = notifyid
    self:Dbg('notifyid='..notifyid)
    target[configKey][__CONFIG_SLOTSET_DIRECT_WARP] = directwarp
    self:Dbg('directwarp='..directwarp)
    -- 永続化
    if (isCommon) then
      self:Serialize(__CONFIG_COMMON_FRAME_FILENAME, __commmon)
    else
      self:Serialize(__cid, __config)
    end
    -- フレーム非表示
    frame:ShowWindow(0)
    return redraw
  end

  -- 右クリックメニュー作成
  members.CreateOptionMenu = function(self, frame)
    self:Dbg('CreateOptionMenu called. index='..frame:GetName())

    local frameIndex = frame:GetUserValue(__USERVALUE_FRAME_INDEX)
    local isCommon = tostring(frame:GetUserValue(__USERVALUE_FRAME_IS_COMMON))

    local menuTitle = 'SubQuickSlot-'..frameIndex
    local context = ui.CreateContextMenu(
      'CONTEXT_SUBQUICKSLOT_OPTION', menuTitle, 0, 0, string.len(menuTitle) * 12, 100)
    -- 画面表示
    ui.AddContextMenuItem(context, 'Option', string.format('SUBQUICKSLOT_ON_MENU_SHOWOPTION(%s, %d, %d, %s)', frameIndex, frame:GetX(), frame:GetY(), isCommon))
    ui.AddContextMenuItem(context, 'Redraw', 'SUBQUICKSLOT_ON_MENU_REDRAW')
    -- 
    if (frameIndex == '1') then
      ui.AddContextMenuItem(context, 'CreateNew', string.format('SUBQUICKSLOT_ON_MENU_CREATENEW(%s)', frameIndex))
      ui.AddContextMenuItem(context, 'ShowAll', 'SUBQUICKSLOT_ON_MENU_SHOWALL')
    else
      ui.AddContextMenuItem(context, 'Delete',
        string.format('SUBQUICKSLOT_ON_MENU_DELETE(%s, %s)', frameIndex, isCommon))
      ui.AddContextMenuItem(context, 'Hide',
        string.format('SUBQUICKSLOT_ON_MENU_HIDE(%s, %s)', frameIndex, isCommon))
      ui.AddContextMenuItem(context, 'CommonConfig', string.format('SUBQUICKSLOT_ON_MENU_COMMONCONFIG(%s, %s)', frameIndex, isCommon))
    end

    ui.AddContextMenuItem(context, 'EmoticonList',
      string.format('SUBQUICKSLOT_ON_MENU_ADDEMOTICON(%s, %d, %d)', frameIndex, frame:GetX(), frame:GetY()))

    ui.AddContextMenuItem(context, 'Cancel', 'None')
    ui.OpenContextMenu(context)
  end

  -- 共通設定メニュー作成
  members.CreateCommonConfigMenu = function(self, index, isCommon)
    self:Dbg('CreateCommonConfigMenu called.')

    local menuTitle = 'SubQuickSlot Common Config (' .. index
    local context = ui.CreateContextMenu(
      'CONTEXT_SUBQUICKSLOT_COMMON_CONFIG', menuTitle, 0, 0, string.len(menuTitle) * 12, 100)

    SUBQUICKSLOT_ON_MENU_COMMONCONFIG_MARK = function()
      g.instance:MarkedCommon(index)
    end
    SUBQUICKSLOT_ON_MENU_COMMONCONFIG_UNMARK = function()
      g.instance:DeletedCommon(index)
    end

    SUBQUICKSLOT_ON_MENU_MARK_AS_A_COMMON_PRECHECK = function()
      ui.MsgBox('It will be MARKED as a common slot.', 'SUBQUICKSLOT_ON_MENU_COMMONCONFIG_MARK', 'None')
    end
    SUBQUICKSLOT_ON_MENU_UNMARK_FROM_COMMON_PRECHECK = function()
      ui.MsgBox('It will be UNMARKED from common slot.', 'SUBQUICKSLOT_ON_MENU_COMMONCONFIG_UNMARK', 'None')
    end

    -- 画面表示
    if (isCommon) then
      ui.AddContextMenuItem(context, 'Unmark from Common', 'SUBQUICKSLOT_ON_MENU_UNMARK_FROM_COMMON_PRECHECK')
    else
      ui.AddContextMenuItem(context, 'Mark as a Common', 'SUBQUICKSLOT_ON_MENU_MARK_AS_A_COMMON_PRECHECK')
    end
    ui.AddContextMenuItem(context, 'Cancel', 'None')
    ui.OpenContextMenu(context)
  end

  -- 共通スロット化
  -- cidに紐づいたものを別ファイルに保存し、紐づけを解除する
  members.MarkedCommon = function(self, index)
    self:Dbg('MarkedCommon called.')

    local config = __config[GetConfigByFrameKey(index)]
    if (not config) then
      self:Log('Do not exist frame. index='..index)
      return
    end

    -- 共通ファイル保存
    __commmon[GetConfigByFrameKey(index)] = config
    self:SaveFrameIndex(index, false, true)

    -- cidの呪縛から解放
    self:DeleteFrame(index)
    self:SaveFrameIndex(index, true)

    self:Log('Please redraw manually with "Menu > Redraw".')
  end

  -- 共通スロットをCIDスロットに戻す
  members.DeletedCommon = function(self, index)
    self:Dbg('DeletedCommon called.')

    local config = __commmon[GetConfigByFrameKey(index)]
    if (not config) then
      self:Log('Do not exist frame. index='..index)
      return
    end

    -- 共通ファイルから解放
    self:DeleteFrame(index, true)
    self:SaveFrameIndex(index, true, true)

    -- cidの呪縛をかける
    __config[GetConfigByFrameKey(index)] = config
    self:SaveFrameIndex(index)

    self:Log('Please redraw manually with "Menu > Redraw".')
  end

  -- サブスロットにアイコンをセット
  members.SetSubSlot = function(self, slot, liftIconInfo)
    self:Dbg('SetSubSlot called.')

    -- ドロップ情報を取得
    local category = GetCategoryFromLiftIconInfo(liftIconInfo)
    local mytype = liftIconInfo.type
    local iesid = liftIconInfo.GetIESID and liftIconInfo:GetIESID() or 0
    self:Dbg(string.format('%s - %s - %s', category, mytype, iesid))

    tolua.cast(slot, "ui::CSlot")
    slot:SetEventScript(ui.RBUTTONUP, 'SUBQUICKSLOT_ON_SLOTRUP')
    slot:SetEventScriptArgNumber(ui.RBUTTONUP, mytype)
    slot:SetUserValue(__USERVALUE_SLOT_CATEGORY, category)
    slot:SetUserValue(__USERVALUE_SLOT_TYPE, mytype)
    -- OH用のゲージ作成するものの一旦消しておく
    QUICKSLOT_MAKE_GAUGE(slot)
    QUICKSLOT_SET_GAUGE_VISIBLE(slot, 0)

    if (category == 'Item') then
      local invItem = session.GetInvItemByGuid(iesid) or session.GetInvItemByType(mytype)
      if (not invItem) then
        self:Dbg('not in inventory.')
        CreateNotInInventoryItemImage(CreateIcon(slot), category, mytype, iesid)
        SET_SLOT_COUNT_TEXT(slot, 0)
        return
      end
      -- スロット格納してイベント定義
      SET_SLOT_ITEM_IMAGE(slot, invItem)
      SET_SLOT_ITEM_TEXT(slot, invItem, GetClassByType('Item', mytype))
      CreateIcon(slot):SetColorTone('FFFFFFFF')
      -- クールダウンの設定
      ICON_SET_ITEM_COOLDOWN_OBJ(slot:GetIcon(), GetIES(invItem:GetObject()))

    elseif (category == 'Skill') then
      local skill = session.GetSkill(mytype)
      local icon = CreateIcon(slot)
      icon:SetOnCoolTimeUpdateScp('ICON_UPDATE_SKILL_COOLDOWN')
      icon:SetEnableUpdateScp('ICON_UPDATE_SKILL_ENABLE')
      icon:SetColorTone('FFFFFFFF')
      icon:SetTooltipType('skill')
      icon:Set('icon_' .. GetClassString('Skill', mytype, 'Icon'), category, mytype, 0, iesid)
			icon:SetTooltipNumArg(mytype)
			icon:SetTooltipIESID(iesid)
      slot:ClearText()
      SET_QUICKSLOT_OVERHEAT(slot)

    elseif (category == 'Pose') then
      local icon = CreateIcon(slot)
      local pose = GetClassByType('Pose', mytype)
      icon:Set(pose.Icon, category, mytype, 0, iesid)
      icon:SetColorTone('FFFFFFFF')
      icon:SetTextTooltip(pose.Name)
      slot:ClearText()

    elseif (category == 'Motion') then
      local image, _ = string.match(mytype, '^(.-)%s(.-)$')
      local icon = CreateIcon(slot)
      icon:SetImage(image)
      icon:SetColorTone('FFFFFFFF')
      icon:SetTextTooltip(mytype)
      slot:ClearText()

    elseif (category == 'Ability') then
      local abilClass = GetClassByType("Ability", mytype)
      local icon = CreateIcon(slot)
      icon:SetTooltipType("ability")
			icon:SetTooltipNumArg(mytype)
      icon:SetColorTone('FFFFFFFF')
      icon:Set(abilClass.Icon, category, mytype, 0, iesid)
      slot:ClearText()
      SET_ABILITY_TOGGLE_COLOR(icon, mytype)

    elseif (category == 'WarpAction') then
      local questIES = GetClassByType('QuestProgressCheck', mytype)
      local zoneName =
        GetClassString(
          'Map',
          questIES[CONVERT_STATE(SCR_QUEST_CHECK_Q(SCR_QUESTINFO_GET_PC(), questIES.ClassName)) .. 'Map'],
          'Name')
      local tooltiptext = zoneName..' - '..questIES.Name
      local icon = CreateIcon(slot)
      icon:Set('questinfo_return', 'WarpAction', mytype, 0, 0)
      icon:SetTextTooltip(tooltiptext)

      slot:SetEventScriptArgString(ui.RBUTTONUP, tooltiptext)
      SET_SLOT_COUNT_TEXT(slot, zoneName, '{s10}{ol}{b}', ui.LEFT, ui.BOTTOM, 0, 0)
    end
  end

  -- スロットクリックアクション
  members.SlotClickAction = function(self, parent, slot, str, num)
    local category = self:GetCategoryFromSlot(slot)
    local mytype = self:GetTypeFromSlot(slot)

    if (category == 'Item') then
      SLOT_ITEMUSE_BY_TYPE(parent, slot, str, num)

    elseif (category == 'Skill') then
      local icon = slot:GetIcon()
      if (not icon) then
        return
      end
      ICON_USE(icon)

    elseif (category == 'Pose') then
      control.Pose(GetClassByType('Pose', num).ClassName)

    elseif (category == 'Motion') then
      -- モーション判定してグループを強制する
      local image, icongroup = string.match(mytype, '^(.-)%s(.-)$')
      if (icongroup == 'Motion') then
        ui.GetFrame('chat_emoticon'):SetUserValue("EMOTICON_GROUP", 'Motion');
      else
        ui.GetFrame('chat_emoticon'):SetUserValue("EMOTICON_GROUP", '');
      end
      CHAT_EMOTICON_SELECT(parent, slot)
    
    elseif (category == 'Ability') then
      local icon = slot:GetIcon()
      if (not icon) then
        return
      end
      ICON_USE(icon)

    elseif (category == 'WarpAction') then
      local questID = num
      local wheretogo = str
      -- LALTで共有
      if (keyboard.IsKeyPressed('LALT') == 1) then
        party.ReqChangeMemberProperty(PARTY_NORMAL, "Shared_Quest", questID)
        REQUEST_QUEST_SHARE_PARTY_PROGRESS(questID)
        QUEST_UPDATE_ALL(ui.GetFrame("quest"))
        self:Log('Successfully shared : '..wheretogo)
        return
      end

      -- それ以外はワープ
      -- 直接ワープがOFFならダイアログ生成
      SUBQUICKSLOT_ON_EXECUTE_WARP = function()
        QUESTION_QUEST_WARP(parent, slot, str, num)
      end

      local frame = parent:GetTopParentFrame()

      local target = __config
      if (frame:GetUserValue(__USERVALUE_FRAME_IS_COMMON) == '1') then
        target = __commmon
      end

      local configKey = GetFrameKeyByFrameName(frame:GetName())
      local directwarp =
        tonumber(target[GetConfigByFrameKey(configKey)][__CONFIG_SLOTSET_DIRECT_WARP] or '1')
      if (directwarp == 1) then
        SUBQUICKSLOT_ON_EXECUTE_WARP(parent, slot, str, num)
        return
      end

      ui.MsgBox(string.format('Execute warp to [%s]. Are you alrigh?', wheretogo), 'SUBQUICKSLOT_ON_EXECUTE_WARP', 'None')
    end
  end

  -- ディスペラー系スクロールのエフェクトONOFF制御
  members.UpdateJungtan = function(self, spellName, onoff, itemType, isCommon)
    self:Dbg('UpdateJungtan called.')
    self:Dbg(spellName..' - '..onoff)

    local target = __config
    if (isCommon) then
      target = __commmon
    end

    for frameIndex in string.gmatch(target[__CONFIG_FRAME_INDEXIES] or '1', "%S+") do
      local frame = ui.GetFrame(addonName..'-'..frameIndex)
      self:Dbg('UpdateJungtan... target='..frame:GetName())

      frame:SetUserValue(string.format('%s_%s', spellName, 'EFFECT'), onoff == 'ON' and itemType or 0)
      local timer = GET_CHILD(frame, spellName:lower()..'timer', 'ui::CAddOnTimer')
      if (onoff == 'OFF') then
        timer:Stop()
      elseif (onoff == 'ON') then
        timer:SetUpdateScript('SUBQUICKSLOT_UPDATE_'..spellName)
        timer:Start(1)
      end
    end
  end

  -- ディスペラー系スクロールのエフェクト処理
  -- スロットの上にエフェクトを乗せるので、エフェクト中に移動させるとエフェクトが遅れてついてくる
  -- どうにかならないかな（どうにもならない
  members.UpdateJungtanEffect = function(self, frame, timerName, isCommon)
    local itemType = frame:GetUserValue(string.format('%s_%s', string.gsub(timerName:upper(), 'TIMER', ''), 'EFFECT'))

    local target = __config
    if (isCommon) then
      target = __commmon
    end

    local slotset = GET_CHILD(frame, 'slotset', 'ui::CSlotSet')

    for k, v in pairs(target[GetConfigByFrameKey(GetFrameKeyByFrameName(frame:GetName()))]) do
      local index = string.match(k, 'slot(%d+)')
      if (index and v[__CONFIG_SLOT_CATEGORY] == 'Item' and v[__CONFIG_SLOT_TYPE] == itemType) then
        local x, y = GET_SCREEN_XY(slotset:GetSlotByIndex(index))
        movie.PlayUIEffect('I_sys_item_slot', x, y, 0.8)
      end
    end
  end

  -- OH変更監視
  members.UpdateSkillOverHeat = function(self, frame)
    local slotset = GET_CHILD(frame, 'slotset', 'ui::CSlotSet')

    local target = __config
    if (frame:GetUserValue(__USERVALUE_FRAME_IS_COMMON) == '1') then
      target = __commmon
    end

    for k, v in pairs(target[GetConfigByFrameKey(GetFrameKeyByFrameName(frame:GetName()))]) do
      local index = string.match(k, 'slot(%d+)')
      if (index and v[__CONFIG_SLOT_CATEGORY] == 'Skill') then
        UPDATE_SLOT_OVERHEAT(slotset:GetSlotByIndex(index))
      end
    end
  end

  -- ポーズD&D事前加工
  members.ModifyForPose = function(self, info, poseid)
    self:Dbg('ModifyForPose called. poseid='..poseid)

    if (poseid == 'None') then
      return info
    end
    info.category = 'Pose'
    info.type = poseid
    info.iesid = 0
    return info
  end

  -- サブスロットからアイコンを削除
  members.RemoveFromSubSlot = function(self, slot)
    self:Dbg('RemoveFromSubSlot called.')
    slot:ClearIcon()
    slot:ClearText()
    QUICKSLOT_SET_GAUGE_VISIBLE(slot, 0)
  end

  -- スロットからカテゴリー情報を復元
  members.GetCategoryFromSlot = function(self, slot)
    local category = slot:GetUserValue(__USERVALUE_SLOT_CATEGORY)
    self:Dbg('GetCategoryFromSlot called. category='..category)
    return category
  end
  -- スロットからTYPE情報を復元
  members.GetTypeFromSlot = function(self, slot)
    local mytype = slot:GetUserValue(__USERVALUE_SLOT_TYPE)
    self:Dbg('GetTypeFromSlot called. mytype='..mytype)
    return mytype
  end

  -- スロット情報を保存
  members.SaveSlot = function(self, frame, slotIndex, liftIconInfo, removeSlotIndex)
    self:Dbg('SaveSlot called. index='..frame:GetName())

    local configKey = GetConfigByFrameKey(frame:GetUserValue(__USERVALUE_FRAME_INDEX))

    local target = __config
    local isCommon = frame:GetUserValue(__USERVALUE_FRAME_IS_COMMON) == '1'
    if (isCommon) then
      target = __commmon
    end

    -- 削除
    if (removeSlotIndex) then
      target[configKey]['slot'..removeSlotIndex] = nil
    end

    -- 追加
    if (slotIndex) then
      local key = 'slot'..slotIndex
      target[configKey][key] = target[configKey][key] or {}
      target[configKey][key][__CONFIG_SLOT_CATEGORY] = GetCategoryFromLiftIconInfo(liftIconInfo)
      target[configKey][key][__CONFIG_SLOT_TYPE] = liftIconInfo.type
      target[configKey][key][__CONFIG_SLOT_IESID] =
        liftIconInfo.GetIESID and liftIconInfo:GetIESID() or 0
    end

    if (isCommon) then
      __commmon = target
      self:Serialize(__CONFIG_COMMON_FRAME_FILENAME, __commmon)
    else
      __config = target
      self:Serialize(__cid, __config)
    end
  end

  -- 位置情報を保存
  members.SavePos = function(self, frame)
    self:Dbg('SavePos called. index='..frame:GetName())

    local isCommon = tostring(frame:GetUserValue(__USERVALUE_FRAME_IS_COMMON)) == '1'

    local target = __config
    if (isCommon) then
      target = __commmon
    end

    local frameIndex = frame:GetUserValue(__USERVALUE_FRAME_INDEX)
    target[GetConfigByFrameKey(frameIndex)][__CONFIG_SLOTSET_POS] =
      string.format('%dx%d', frame:GetX(), frame:GetY())

    if (isCommon) then
      self:Serialize(__CONFIG_COMMON_FRAME_FILENAME, __commmon)
    else
      self:Serialize(__cid, __config)
    end
  end

  -- フレームインデックスを保存または削除
  members.SaveFrameIndex = function(self, frameIndex, delete, isCommon)
    self:Dbg('SaveFrameIndex called. index='..frameIndex)

    local buffer = __config
    if (isCommon) then
      buffer = __commmon
    end

    local config = buffer[__CONFIG_FRAME_INDEXIES] or '1'
    if (delete) then
      config = string.gsub(config, '%s'..frameIndex, '', 1)
    else
      config = config..' '..frameIndex
    end
    buffer[__CONFIG_FRAME_INDEXIES] = config

    if (isCommon) then
      __commmon = buffer
      self:Serialize(__CONFIG_COMMON_FRAME_FILENAME, __commmon)
    else
      __config = buffer
      self:Serialize(__cid, __config)
    end
  end

  -- クラスID通知
  members.NofityClassIDInChat = function(self, frame, liftIconInfo)
    self:Dbg('NofityClassIDInChat called.')

    local target = __config
    local isCommon = frame:GetUserValue(__USERVALUE_FRAME_IS_COMMON) == '1'
    if (isCommon) then
      target = __commmon
    end

    local configKey = GetConfigByFrameKey(frame:GetUserValue(__USERVALUE_FRAME_INDEX))
    if (tonumber(target[configKey][__CONFIG_SLOTSET_NOTIFY_CLASSID]) ~= 1 or not liftIconInfo) then
      return
    end
    local targetClass =
      GetClassByType(GetCategoryFromLiftIconInfo(liftIconInfo), liftIconInfo.type)
    if (not targetClass) then
      return
    end
    self:Log(string.format('%s -> %s', targetClass.Name, targetClass.ClassID))
  end

  members.ShowAll = function(self)
    -- キャラクターに紐づくスロット用
    for index in string.gmatch(__config[__CONFIG_FRAME_INDEXIES] or '1', "%S+") do
      local configKey = GetConfigByFrameKey(index)
      if (tonumber(__config[configKey][__CONFIG_SLOTSET_SHOW] or '1') == 0) then
        __config[configKey][__CONFIG_SLOTSET_SHOW] = '1'
        self:CreateFrame(index)
      end
    end
    self:Serialize(__cid, __config)
    -- 共通スロット用
    for index in string.gmatch(__commmon[__CONFIG_FRAME_INDEXIES] or '1', "%S+") do
      local configKey = GetConfigByFrameKey(index)
      if (tonumber(__commmon[configKey][__CONFIG_SLOTSET_SHOW] or '1') == 0) then
        __commmon[configKey][__CONFIG_SLOTSET_SHOW] = '1'
        self:CreateFrame(index, true)
      end
    end
    self:Serialize(__CONFIG_COMMON_FRAME_FILENAME, __commmon)
  end

  -- デストラクター
  members.Destroy = function(self)
  end
  -- おまじない
  return setmetatable(members, {__index = self});
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new})

-- 自フレーム初期化処理
function SUBQUICKSLOT_ON_INIT(addon, frame)
  -- インベントリ操作が発生したら再描画が必要
  addon:RegisterMsg('INV_ITEM_ADD', 'SUBQUICKSLOT_ON_REDRAW_COUNT')
  addon:RegisterMsg('INV_ITEM_POST_REMOVE', 'SUBQUICKSLOT_ON_REDRAW_COUNT')
  addon:RegisterMsg('INV_ITEM_CHANGE_COUNT', 'SUBQUICKSLOT_ON_REDRAW_COUNT')
  addon:RegisterMsg('JUNGTAN_SLOT_UPDATE', 'SUBQUICKSLOT_ON_JUNGTAN_SLOT_UPDATE')
  -- 特性ONOFFが発生したら再描画が必要
  addon:RegisterMsg('RESET_ABILITY_ACTIVE', 'SUBQUICKSLOT_ON_RESET_ABILITY_ACTIVE')
  -- 遅延呼び出し的な
  -- これをしないとSCR_QUEST_CHECK_Q() の戻り値がNoneになって正しく動かない
  addon:RegisterMsg('GAME_START', 'SUBQUICKSLOT_ON_MENU_REDRAW')
end

-- === イベントハンドラー === --
function SUBQUICKSLOT_ON_SHOWMENU(frame, index, num)
  g.instance:CreateOptionMenu(frame)
end
function SUBQUICKSLOT_ON_MENU_SHOWOPTION(index, x, y, isCommon)
  g.instance:CreateOptionFrame(index, x, y, tostring(isCommon) == '1')
end
function SUBQUICKSLOT_ON_MENU_REDRAW()
  g.instance:CreateFrames()
end
function SUBQUICKSLOT_ON_MENU_CREATENEW(index)
  local newIndex = IMCRandom(2,999)
  g.instance:CreateFrame(newIndex)
  g.instance:SaveFrameIndex(newIndex)
end
function SUBQUICKSLOT_ON_MENU_COMMONCONFIG(index, isCommon)
  g.instance:CreateCommonConfigMenu(index, isCommon)
end
function SUBQUICKSLOT_ON_MENU_SHOWALL()
  g.instance:ShowAll()
end
function SUBQUICKSLOT_ON_MENU_DELETE(index, isCommon)
  g.instance:DeleteFrame(index, tostring(isCommon) == '1')
  g.instance:SaveFrameIndex(index, true, tostring(isCommon) == '1')
end
function SUBQUICKSLOT_ON_MENU_HIDE(index, isCommon)
  g.instance:HideFrame(index, tostring(isCommon) == '1')
end

function SUBQUICKSLOT_ON_LOSTFOCUSOPTION()
  local redraw = g.instance:CloseOptionFrame()
  if (redraw) then
    g.instance:CreateFrames()
  end
end
function SUBQUICKSLOT_ON_ENDMOVE(frame, str, num)
  g.instance:SavePos(frame)
end
function SUBQUICKSLOT_ON_DROPSLOT(parent, slot, str, num)
  local liftIcon = ui.GetLiftIcon()
  local info = liftIcon:GetInfo()
  -- POP時の情報を復元する
  info.category = g.instance[g.instance.GLOBALVALUE_LIFTICON_CATEGORY] or info.category
  info.fromIndex = g.instance[g.instance.GLOBALVALUE_LIFTICON_FROMINDEX]
  -- 本来lifticon.typeは数値のみなので、Motion特別仕様に変更する
  if (info.category == 'Motion') then
    local dummy = {}
    dummy.category = info.category
    dummy.fromIndex = info.fromIndex
    dummy.type = g.instance[g.instance.GLOBALVALUE_LIFTICON_TYPE]
    info = dummy
  end
  -- グローバルに保存した情報は使ったら破棄しましょうね
  g.instance[g.instance.GLOBALVALUE_LIFTICON_CATEGORY] = nil
  g.instance[g.instance.GLOBALVALUE_LIFTICON_FROMINDEX] = nil
  g.instance[g.instance.GLOBALVALUE_LIFTICON_TYPE] = nil
  -- ポーズはオリジナルにはないので特殊処理で復元
  info = g.instance:ModifyForPose(info, liftIcon:GetUserValue('POSEID'))
  -- スロットに入れる
  g.instance:SetSubSlot(slot, info)
  -- ドラッグ開始とドラッグ終了が同じ場所の場合は消したらいけない
  -- ドラッグ開始とドラッグ終了のフレームが違う場合は消したらいけない
  if (liftIcon:GetTopParentFrame():GetName() ~= parent:GetTopParentFrame():GetName()) then
    -- fromIndexを消すことで削除処理と削除データ保存処理を回避する
    info.fromIndex = nil
  end
  if (info.fromIndex and info.fromIndex ~= slot:GetSlotIndex()) then
    g.instance:RemoveFromSubSlot(parent:GetSlotByIndex(info.fromIndex))
  end
  g.instance:SaveSlot(parent:GetTopParentFrame(), slot:GetSlotIndex(), info, info.fromIndex)
  -- クラスID通知
  g.instance:NofityClassIDInChat(parent:GetTopParentFrame(), info)
end
function SUBQUICKSLOT_ON_POPSLOT(parent, slot, str, num)
  local liftIcon = ui.GetLiftIcon()
  local info = liftIcon:GetInfo()
  -- 画面外にドロップしてもイベント発生しないのでLALTで消すようにする
  if (keyboard.IsKeyPressed('LALT') == 1) then
    g.instance:RemoveFromSubSlot(slot)
    g.instance:SaveSlot(parent:GetTopParentFrame(), nil, info, slot:GetSlotIndex())
    return
  end
  -- Re:BuildでLiftIconに情報を保持できなくなったのでグローバルでなんとかする
  -- 同時ドラッグ数は1だから大丈夫だと思う...
  -- スロットからドラッグ開始するとcategoryが抜けるので予め保持したものを持ってくる
  local category = g.instance:GetCategoryFromSlot(slot)
  g.instance[g.instance.GLOBALVALUE_LIFTICON_CATEGORY] = category
  -- ドロップ時に消せるようにliftIconInfoにIndexをもたせる
  g.instance[g.instance.GLOBALVALUE_LIFTICON_FROMINDEX] = slot:GetSlotIndex()

  if (category == 'Motion') then
    -- D&D対応してない絵文字用特殊処理
    g.instance[g.instance.GLOBALVALUE_LIFTICON_TYPE] = g.instance:GetTypeFromSlot(slot)
  end
end
function SUBQUICKSLOT_ON_SLOTRUP(parent, slot, str, num)
  g.instance:SlotClickAction(parent, slot, str, num)
end
function SUBQUICKSLOT_ON_REDRAW_COUNT()
  g.instance:RedrawFrames()
  g.instance:RedrawFrames(true)
end
function SUBQUICKSLOT_ON_JUNGTAN_SLOT_UPDATE(frame, msg, str, itemType)
  local spellName, onoff = string.match(str, '^(.-)%_(.-)$')
  g.instance:UpdateJungtan(spellName, onoff, itemType)
  g.instance:UpdateJungtan(spellName, onoff, itemType, true)
end
function SUBQUICKSLOT_UPDATE_JUNGTAN(frame, ctrl, num, str, time)
  if (frame:IsVisible() == 0) then
    return
  end
  g.instance:UpdateJungtanEffect(frame, ctrl:GetName())
  g.instance:UpdateJungtanEffect(frame, ctrl:GetName(), true)
end
function SUBQUICKSLOT_UPDATE_JUNGTANDEF(frame, ctrl, num, str, time)
  if (frame:IsVisible() == 0) then
    return
  end
  g.instance:UpdateJungtanEffect(frame, ctrl:GetName())
  g.instance:UpdateJungtanEffect(frame, ctrl:GetName(), true)
end
function SUBQUICKSLOT_UPDATE_DISPELDEBUFF(frame, ctrl, num, str, time)
  if (frame:IsVisible() == 0) then
    return
  end
  g.instance:UpdateJungtanEffect(frame, ctrl:GetName())
  g.instance:UpdateJungtanEffect(frame, ctrl:GetName(), true)
end
function SUBQUICKSLOT_ON_UPDATE_OVERHEAT(frame, ctrl, num, str, time)
  g.instance:UpdateSkillOverHeat(frame)
end
function SUBQUICKSLOT_ON_RESET_ABILITY_ACTIVE(frame, msg, argStr, argNum)
  g.instance:RedrawSkillAbilityFrames(argStr)
  g.instance:RedrawSkillAbilityFrames(argStr, true)
end
function SUBQUICKSLOT_ON_MENU_ADDEMOTICON(frameIndex, x, y)
  local GetEmoticonImageName = function(className)
    local namelist = StringSplit(className, "motion_");
    local imageName = namelist[1];
    if 1 < #namelist then
      imageName = namelist[2];
    end
    return imageName
  end

  -- 画面表示
  local list, listCnt = GetClassList("chat_emoticons")
  local slotw = 6
  local sloth = listCnt / slotw + 1
  local slotsize = 48

  local frame = ui.CreateNewFrame(addonName, addonName..'-Emoticon')
  frame:SetSkinName('downbox')
  frame:Resize(310, 350)
  frame:SetOffset(x + 10, y + 10)
  frame:SetLayerLevel(999)
  frame:EnableMove(1)
  -- 閉じるボタン
  local close = frame:CreateOrGetControl('button', 'close', frame:GetWidth() - 20, 0, 20, 20)
  close:SetText('ｘ')
  close:SetFontName('white_14_ol')
  SUBQUICKSLOT_CLOSE_ADDEMOTICON = function(f, c, s, n)
    f:ShowWindow(0)
  end
  close:SetEventScript(ui.LBUTTONUP, 'SUBQUICKSLOT_CLOSE_ADDEMOTICON')
  -- スクロール用のGBOX
  local bg = frame:CreateOrGetControl('groupbox', 'bg', 0, 0, 0, 0)
  tolua.cast(bg, 'ui::CGroupBox')
  bg:SetSkinName('None')
  bg:Resize(frame:GetWidth() - 0, frame:GetHeight() - 20)
  bg:SetOffset(0, 20)
  bg:EnableScrollBar(1)
  bg:EnableHittestGroupBox(false)
  -- スロット作成
  DESTROY_CHILD_BYNAME(bg, 'slotset')
  local slotset = bg:CreateOrGetControl('slotset', 'slotset', 0, 0, 0, 0)
  tolua.cast(slotset, 'ui::CSlotSet')
  slotset:SetSlotSize(slotsize, slotsize)  -- スロットの大きさ
  slotset:EnablePop(1)
  slotset:EnableDrag(1)
  slotset:EnableDrop(0)
  slotset:SetColRow(slotw, sloth)  -- スロットの配置と個数
  slotset:SetSpc(0, 0)
  slotset:SetSkinName('invenslot')
  slotset:SetEventScript(ui.POP, 'SUBQUICKSLOT_ON_EMOTICON_POPSLOT')
  slotset:EnableSelection(0)
  slotset:CreateSlots()

  for i = 0 , listCnt - 1 do
    local cls = GetClassByIndexFromList(list, i)
    -- 絵文字チーム共通化で保持状態確認先が変わるんだよ
    local etc = GetMyAccountObj();
    if TryGetProp(cls, 'HaveUnit', 'None') == 'PC' then
      etc = GetMyEtcObject()
    end
    local haveEmoticon = 1
    if cls.CheckServer == 'YES' then
      haveEmoticon = TryGetProp(etc, 'HaveEmoticon_' .. cls.ClassID)
    end
    local slot = slotset:GetSlotByIndex(i)
    local icon = CreateIcon(slot)
    icon:SetImage(GetEmoticonImageName(cls.ClassName))
    local tooltipText = string.format( "%s%s(%s)" , "/" ,cls.IconTokken, icon:GetInfo():GetImageName())
    icon:SetTextTooltip(tooltipText)
    if (haveEmoticon <= 0) then
      -- slot:SetAlpha(25)
      icon:SetColorTone('11FFFFFF')
    end
    local icongroup = 'Normal'
    local tempTokken = dictionary.ReplaceDicIDInCompStr(cls.IconTokken)
    if (string.match(tempTokken, 'モーション') or string.match(tempTokken, 'motion')) then
      icongroup = 'Motion';
    end
    slot:SetUserValue('icongroup', icongroup)
    slot:ShowWindow(1)
  end
end
function SUBQUICKSLOT_ON_EMOTICON_POPSLOT(parent, slot, str, num)
  g.instance[g.instance.GLOBALVALUE_LIFTICON_CATEGORY] = 'Motion'
  g.instance[g.instance.GLOBALVALUE_LIFTICON_TYPE] = slot:GetIcon():GetInfo():GetImageName() .. ' ' .. slot:GetUserValue('icongroup')
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy();
end
g.instance = g();
