-- 領域定義
local author = 'weizlogy'
local addonName = 'fixinventorysort'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  local members = {};

  -- === 定数 === --
  local __ADDON_DIR = '../addons/'..addonName

  -- ソート種別
  --  デフォルト
  --   0 = LEVEL,
  --   1 = WEIGHT,
  --   2 = NAME,
  local __sortType = -1
  -- 拡張ソート設定
  local __config = {}
  -- デフォルトのソート種別と重複しないように拡張ソート種別の開始位置を決める
  local __extendSortStartIndex = 10

  -- ソート条件を保存
  members.SetSortType = function(self, sortType)
    self:Dbg('sortType = '..sortType)
    __sortType = sortType
  end

  -- ソート処理
  members.Sort = function(self, baseList, useAffect)
    -- INV_ITEM_SORTED_LIST型を再現（いらないんじゃないか疑惑はある
    local sortWorker = {
      at = function(self, index)
        return self[index + 1]
      end,  -- <- カンマないと死ぬ気をつけて
      size = function(self)
        return #self
      end
    }
    -- ソート対象外保管領域
    local ignoreSortWorker = {}

    -- データを作業ワークへコピー
    -- 対象外のアイテムは専用ワーク行き
    for i = 0 , baseList:size() - 1 do
      local invItem = baseList:at(i)
      if (invItem ~= nil) then
        if (not useAffect) then
          table.insert(sortWorker, invItem)
        else
          local baseidcls = GET_BASEID_CLS_BY_INVINDEX(invItem.invIndex)
          -- CHAT_SYSTEM(GetIES(invItem:GetObject()).GroupName..' / '..baseidcls.TreeGroupCaption..' / '..baseidcls.TreeSSetTitle)
          local affect = __config['affect']
          local target = baseidcls.TreeSSetTitle
          if (affect and affect[dictionary.ReplaceDicIDInCompStr(target)]) then
            -- 対象グループ名ごとにまとめる
            -- ここも再帰的呼び出しのためINV_ITEM_SORTED_LIST型を再現
            ignoreSortWorker[target] = ignoreSortWorker[target] or {
              at = function(self, index)
                return self[index + 1]
              end,  -- <- カンマないと死ぬ気をつけて
              size = function(self)
                return #self
              end
            }
            table.insert(ignoreSortWorker[target], invItem)
          else
            table.insert(sortWorker, invItem)
          end
        end
      end
    end

    local sortFunc = self:ToSortFunc()
    if (sortFunc == nil) then
      return baseList
    end
    -- ソート実行
    table.sort(sortWorker, sortFunc)
    local s, e = pcall(table.sort, sortWorker, sortFunc)
    if (not s) then
      self:Err(e)
    end

    -- for i = 0, 5 do
    --   local obj = GetIES(sortWorker:at(i):GetObject())
    --   self:Dbg('['..dictionary.ReplaceDicIDInCompStr(obj.Name)..']')
    -- end

    local chooseSortType = __sortType
    for k, v in pairs(ignoreSortWorker) do
      __sortType = self:ToSortType(__config['affect'][dictionary.ReplaceDicIDInCompStr(k)])
      local sortedList = self:Sort(v)
      -- CHAT_SYSTEM(k..' - '..__sortType..' - '..#sortedList)
      for _, v in ipairs(sortedList) do
        table.insert(sortWorker, 1, v)
      end
    end
    __sortType = chooseSortType

    return sortWorker
  end

  -- ソート種別からソートロジックに変換
  members.ToSortFunc = function(self)
    local sortFunc = nil
    if (__sortType == 1) then
      sortFunc = function(s1, s2)
        local o1 = GetIES(s1:GetObject())
        local o2 = GetIES(s2:GetObject())
        local r = o1.Weight < o2.Weight
        if o1.Weight ~= o2.Weight then
          return r
        end
        r = dictionary.ReplaceDicIDInCompStr(o1.Name) < dictionary.ReplaceDicIDInCompStr(o2.Name)
        if o1.Name ~= o2.Name then
          return r
        end
        r = s1.count > s2.count
        if s1.count ~= s2.count then
          return r
        end
        return s1:GetIESID() < s2:GetIESID()
      end
    elseif (__sortType == 2) then
      sortFunc = function(s1, s2)
        local o1 = GetIES(s1:GetObject())
        local o2 = GetIES(s2:GetObject())
        local r = dictionary.ReplaceDicIDInCompStr(o1.Name) < dictionary.ReplaceDicIDInCompStr(o2.Name)
        if o1.Name ~= o2.Name then
          return r
        end
        return s1:GetIESID() < s2:GetIESID()
      end
    -- 拡張ソートロジック
    elseif (__sortType >= __extendSortStartIndex) then
      -- 設定復元
      local config = __config[__sortType - __extendSortStartIndex]
      if (not config) then
        return baseList
      end
      -- ソートロジック作成
      local sortFuncTemplate =
        " return function(s1, s2) \
            local o1 = GetIES(s1:GetObject()); \
            local o2 = GetIES(s2:GetObject()); \
            local r = 0; \
            %s \
            return s1:GetIESID() < s2:GetIESID(); \
          end; "
      local sortFuncDynamicaly = ''
      local sortKeys = config.Sort
      for i = 0, #sortKeys do
        local key = sortKeys[i]
        local rmprelogic = ''
        if (__config['removeprefix'] and __config['removeprefix'][key]) then
          for k, v in pairs(__config['removeprefix'][key]) do
            if (type(v) == 'table') then
              self:Dbg(string.format('removeprefix %s -> %s, %s', key, v['Regex'], v['Capture']))
              rmprelogic = rmprelogic ..
                string.format("  t1 = string.gsub(t1, '%s', '%s'); t2 = string.gsub(t2, '%s', '%s');  ", v['Regex'], v['Capture'], v['Regex'], v['Capture'])
            else
              self:Dbg(string.format('removeprefix %s -> %s', key, v))
              rmprelogic = rmprelogic ..
                string.format("  t1 = string.gsub(t1, '%s', ''); t2 = string.gsub(t2, '%s', '');  ", v, v)
            end
          end
        end
        local logic = string.format(
          " \
           local t1 = string.lower(dictionary.ReplaceDicIDInCompStr(o1['%s'])) \
           local t2 = string.lower(dictionary.ReplaceDicIDInCompStr(o2['%s'])) \
           %s \
           r = t1 < t2; \
           if (o1['%s'] ~= o2['%s']) then  \
             return r  \
           end; ", key, key, rmprelogic, key, key)
        sortFuncDynamicaly = sortFuncDynamicaly..logic
      end
      sortFunc = assert(loadstring(string.format(sortFuncTemplate, sortFuncDynamicaly)))()
    end
    return sortFunc
  end

  members.CreateSortMenu = function(self)
    local configName = '../addons/fixinventorysort/settings.txt'
    -- 設定ファイルが不正ならオリジナル
    -- 設定ファイルがあればそこからメニュー構築
    local customContextConfig, e = loadfile(configName)
    if (e) then
      self:Err(e)
      self.SORT_ITEM_INVENTORY()
      return
    end
    __config = customContextConfig()
    -- removeprefixを生成
    __config['removeprefix'] = {
      Icon = {
        [0] = '^%d+_',
        [1] = 'icon_',
        [2] = 'item_'
      },
      ItemLifeTime = {
        [0] = {
          Regex = '^(%d%d%d%d%d%d)%d',
          Capture = '%1x'
        }
      }
    }
    local context = ui.CreateContextMenu('FIXINVENTORYSORT_CONTEXT_SORT', addonName, 0, 0, 170, 100)

    for i = 0, #__config do
      local scpScp = ''
      local config = __config[i]
      -- 文字列だけ == 既存ロジック
      -- 文字列以外 == 拡張ロジック
      if (type(config) == 'string') then
        local sortType = self:ToSortType(config)
        local msgPrefix = 'SortBy'
        scpScp = string.format("REQ_INV_SORT(%d, %d)",IT_INVENTORY, sortType)
        if (sortType == -1) then
          msgPrefix = ''
        end
        ui.AddContextMenuItem(context, loadstring(string.format('return ScpArgMsg("%s%s")', msgPrefix, config:gsub('^%l', string.upper)))(), scpScp)
      else
        config.Id = self:ToSortType(i)
        self:Dbg(config.Id..' - '..config.Desc)
        scpScp = string.format("REQ_INV_SORT(%d, %d)",IT_INVENTORY, config.Id)
        ui.AddContextMenuItem(context, config.Desc, scpScp)
      end
    end

    FIXINVENTORYSORT_ON_MENU_CONFIG = function()
      self:OpenConfig()
    end

    ui.AddContextMenuItem(context, '[config]', 'FIXINVENTORYSORT_ON_MENU_CONFIG')
  	ui.OpenContextMenu(context)
  end

  members.ToSortType = function(self, value)
    if (type(value) == 'string') then
      local s, e = pcall(loadstring('return BY_'..value:upper()))
      if (not s or e == nil) then
        self:Dbg(tostring(e))
        return -1
      end
      return e
      -- return loadstring('return BY_'..value:upper())()
    end
    return value + __extendSortStartIndex  -- Index値から勝手にIDを捏造
  end

  members.OpenConfig = function(self)
    self:Dbg('Loading config...')

    local offsetToInventory = function(frame)
      local inv = ui.GetFrame('inventory')
      frame:SetOffset(inv:GetX(), inv:GetY())
    end

    local autocompleteEditor = function()
    end

    local removeLineButton = function(target, name, x, y, key, index, key2, index2)
      local f = tolua.cast(target:CreateOrGetControl('button', name, x, y, 25, 25), 'ui::CButton')
      f:SetFontName('white_16_ol')
      f:SetTextAlign('center', 'center')
      f:EnableHitTest(1)
      f:SetText('-')
      f:SetEventScript(ui.LBUTTONUP, 'FIXINVENTORYSORT_ON_CONFIG_MINUS_LBUTTONUP')
      f:SetEventScriptArgString(ui.LBUTTONUP, key)
      f:SetEventScriptArgNumber(ui.LBUTTONUP, index)
      f:SetUserValue('FIXINVENTORYSORT_ON_CONFIG_MINUS_KEY2', key2)
      f:SetUserValue('FIXINVENTORYSORT_ON_CONFIG_PLUS_INDEX2', index2)

      FIXINVENTORYSORT_ON_CONFIG_MINUS_LBUTTONUP = function(frame, ctrl, str, num)
        local key2 = ctrl:GetUserValue('FIXINVENTORYSORT_ON_CONFIG_MINUS_KEY2')
        FIXINVENTORYSORT_ON_CONFIG_MINUS_LBUTTONUP_OK = function()
          if (str == '') then
            table.remove(__config, num)
          elseif (key2 ~= 'None') then
            __config[str][key2] = nil
          else
            local index2 = ctrl:GetUserIValue('FIXINVENTORYSORT_ON_CONFIG_PLUS_INDEX2')
            table.remove(__config[index2][str], num)
          end
          FIXINVENTORYSORT_ON_REDRAW_CONFIG()
        end
        ui.MsgBox(string.format(
          'It will be erased the [%s] of %s. Are you alrigh?',
            (key2 == 'None' and tostring(num) or key2), (str == '' and 'main' or str)),
          'FIXINVENTORYSORT_ON_CONFIG_MINUS_LBUTTONUP_OK', 'None')
      end
    end

    local appendLineButton = function(target, name, x, y, key, index, key2)
      local f = tolua.cast(target:CreateOrGetControl('button', name, x, y, 25, 25), 'ui::CButton')
      f:SetFontName('white_16_ol')
      f:SetTextAlign('center', 'center')
      f:EnableHitTest(1)
      f:SetText('+')
      f:SetEventScript(ui.LBUTTONUP, 'FIXINVENTORYSORT_ON_CONFIG_PLUS_LBUTTONUP')
      f:SetEventScriptArgString(ui.LBUTTONUP, key)
      f:SetEventScriptArgNumber(ui.LBUTTONUP, index)
      f:SetUserValue('FIXINVENTORYSORT_ON_CONFIG_PLUS_KEY2', key2)

      FIXINVENTORYSORT_ON_CONFIG_PLUS_LBUTTONUP = function(frame, ctrl, str, num)
        local key2 = ctrl:GetUserValue('FIXINVENTORYSORT_ON_CONFIG_PLUS_KEY2')
        if (str == '') then
          table.insert(__config, '')
        elseif (key2 ~= 'None') then
          if (not __config[str]) then
            __config[str] = {}
          end
          __config[str][key2] = ''
        else
          table.insert(__config[num][str], '')
        end
        FIXINVENTORYSORT_ON_REDRAW_CONFIG()
      end
    end

    local frame = ui.GetFrame(addonName)
    frame:SetLayerLevel(999)
    frame:SetSkinName('test_frame_low')
    frame:Resize(510, 510)
    frame:EnableHitTest(1)
    offsetToInventory(frame)

    -- タイトル
    local title = tolua.cast(frame:CreateOrGetControl('richtext', '_title', 10, 10, 0, 0), 'ui::CRichText')
    title:SetText('FixInventorySort Config')
    title:SetFontName('white_16_ol')
    -- CLOSE
    local close = tolua.cast(frame:CreateOrGetControl('button', '_close', 10, 10, 60, 25), 'ui::CButton')
    close:SetFontName('white_16_ol')
    close:SetTextAlign('center', 'center')
    close:SetText('CLOSE')
    close:SetOffset(frame:GetWidth() - close:GetWidth() - close:GetX(), close:GetY())
    -- イベントハンドラー：CLOSEボタン 左クリック
    FIXINVENTORYSORT_ON_CONFIG_CLOSE_LBUTTONUP = function(frame, ctrl, str, num)
      self:Dbg('FIXINVENTORYSORT_ON_CONFIG_CLOSE_LBUTTONUP start.')
      frame:ShowWindow(0)
      self:Dbg('FIXINVENTORYSORT_ON_CONFIG_CLOSE_LBUTTONUP end.')
    end
    close:SetEventScript(ui.LBUTTONUP, 'FIXINVENTORYSORT_ON_CONFIG_CLOSE_LBUTTONUP')
    -- SAVE
    local save = tolua.cast(frame:CreateOrGetControl('button', '_save', 10, 10, 60, 25), 'ui::CButton')
    save:SetFontName('white_16_ol')
    save:SetTextAlign('center', 'center')
    save:SetText('SAVE')
    save:SetOffset(frame:GetWidth() - save:GetWidth() - save:GetX(), frame:GetHeight() - save:GetHeight() - save:GetY())
    -- イベントハンドラー：SAVEボタン 左クリック
    FIXINVENTORYSORT_ON_CONFIG_SAVE_LBUTTONUP = function(frame, ctrl, str, num)
      self:Dbg('FIXINVENTORYSORT_ON_CONFIG_SAVE_LBUTTONUP start.')

      local filePath = string.format('%s/%s', __ADDON_DIR, 'settings.txt')
      local f, e = io.open(filePath, 'w')
      if (e) then
        self:Err('Failed to save option to file.'..fileName)
        self:Err(tostring(e))
        return
      end

      f:write('local s = {}\n---\n')
      for i = 0, #__config do
        if (type(__config[i]) == 'string') then
          f:write(string.format('s[%d] = "%s"\n', i, __config[i]))
        else
          f:write(string.format('s[%d] = {\n', i))
          f:write(string.format('  Desc = "%s",\n', __config[i]['Desc']))
          f:write('  Sort = {\n')
          for j = 0, #__config[i]['Sort'] do
            f:write(string.format('    [%d] = "%s",\n', j, __config[i]['Sort'][j]))
          end
          f:write('  }\n')
          f:write('}\n')
        end
      end
      if (__config['affect']) then
        f:write('s["affect"] = {\n')
        for k, v in pairs(__config['affect']) do
          f:write(string.format('  ["%s"] = "%s",\n', k, v))
        end
        f:write('}\n')
      end
      f:write('---\n')
      f:write('return s')
      f:flush()
      f:close()
      self:Log('Successfully saved.')
      self:Dbg('FIXINVENTORYSORT_ON_CONFIG_SAVE_LBUTTONUP end.')
    end
    save:SetEventScript(ui.LBUTTONUP, 'FIXINVENTORYSORT_ON_CONFIG_SAVE_LBUTTONUP')

    DESTROY_CHILD_BYNAME(frame, '_settingsgb')

    local settingsgb = tolua.cast(frame:CreateOrGetControl('groupbox', '_settingsgb', 10, 60, 0, 0), 'ui::CGroupBox')
    settingsgb:SetSkinName('None')
    settingsgb:Resize(frame:GetWidth() - settingsgb:GetX() - 20, frame:GetHeight() - settingsgb:GetY() - 40)
    settingsgb:EnableHitTest(1)
    settingsgb:EnableScrollBar(1)
    local sortTitle = tolua.cast(frame:CreateOrGetControl('richtext', '_sorttitle', 10, 40, 0, 0), 'ui::CRichText')
    sortTitle:SetText('Main')
    sortTitle:SetFontName('white_16_ol')

    local createSortLineEditor = function(target, config, index)
      local label = tolua.cast(target:CreateOrGetControl('richtext', '_label'..index, 10, 10, 0, 0), 'ui::CRichText')
      label:SetText(string.format('[%d]', index))
      label:SetFontName('white_16_ol')
      local input = tolua.cast(target:CreateOrGetControl('edit', '_input'..index, label:GetWidth() + 10, 10, 120, 25), 'ui::CEditControl')
      input:SetFontName('white_16_ol')
      input:SetSkinName('test_weight_skin')
      input:SetTextAlign('center', 'center')
      input:SetText(type(config) == 'string' and config or config['Desc'])
      input:SetOffset(input:GetX(), index * input:GetHeight() + index * 5)
      label:SetOffset(label:GetX(), index * input:GetHeight() + index * 5 + 4)
      input:SetTypingScp('FIXINVENTORYSORT_ON_INPUT_TYPING')

      FIXINVENTORYSORT_ON_INPUT_TYPING = function(parent, ctrl)
        local text = ctrl:GetText()
        if (type(__config[index]) == 'string') then
          __config[index] = text
          return
        end
        __config[index]['Desc'] = text
      end

      removeLineButton(target, '_func'..index,
        input:GetX() + input:GetWidth() + 10, input:GetY(), '', index)

      local func2 = tolua.cast(target:CreateOrGetControl('button', '_func2'..index, input:GetX() + input:GetWidth() + 40, input:GetY(), 25, 25), 'ui::CButton')
      func2:SetFontName('white_16_ol')
      func2:SetTextAlign('center', 'center')
      func2:EnableHitTest(1)
      func2:SetText('⇔')
      func2:SetEventScript(ui.LBUTTONUP, 'FIXINVENTORYSORT_ON_CONFIG_FUNC2_LBUTTONUP')
      func2:SetEventScriptArgNumber(ui.LBUTTONUP, index)

      FIXINVENTORYSORT_ON_CONFIG_FUNC2_LBUTTONUP = function(frame, ctrl, str, num)
        local originalSort = type(config) == 'string'

        FIXINVENTORYSORT_ON_CONFIG_FUNC2_OK = function()
          local config = __config[num]
          if (originalSort) then
            __config[num] = {
              Desc = '',
              Sort = {
                [0] = ''
              }
            }
          else
            __config[num] = ''
          end
          FIXINVENTORYSORT_ON_REDRAW_CONFIG()
        end

        ui.MsgBox(string.format(
          'It will be changed to %s sort and current config will be erased. Are you alrigh?',
            originalSort and 'CUSTOM' or 'ORIGINAL'),
          'FIXINVENTORYSORT_ON_CONFIG_FUNC2_OK', 'None')
      end

      if (type(config) == 'string') then
        return
      end

      local func3 = tolua.cast(target:CreateOrGetControl('button', '_func3'..index, input:GetX() + input:GetWidth() + 70, input:GetY(), 25, 25), 'ui::CButton')
      func3:SetFontName('white_16_ol')
      func3:SetTextAlign('center', 'center')
      func3:EnableHitTest(1)
      func3:SetText('>')
      func3:SetEventScript(ui.LBUTTONUP, 'FIXINVENTORYSORT_ON_CONFIG_FUNC3_LBUTTONUP')
      func3:SetEventScriptArgNumber(ui.LBUTTONUP, index)

      FIXINVENTORYSORT_ON_CONFIG_FUNC3_LBUTTONUP = function(frame, ctrl, str, num)
        local config = __config[num]
        if (type(config) ~= 'table') then
          return
        end
        local bgName = '_custombg'..num
        local showCustomSort = frame:GetChild(bgName) == nil

        DESTROY_CHILD_BYNAME(frame, '_custombg'..num)
        if (not showCustomSort) then
          return
        end

        local custombg = tolua.cast(frame:CreateOrGetControl('groupbox', '_custombg'..num, ctrl:GetX() + ctrl:GetWidth() + 10, ctrl:GetY(), 0, 0), 'ui::CGroupBox')
        custombg:SetSkinName('None')
        custombg:EnableHitTest(1)

        local createCustomSortLineEditor = function(target, config, index)
          local label = tolua.cast(target:CreateOrGetControl('richtext', '_label'..index, 30, 10, 0, 0), 'ui::CRichText')
          label:SetText(string.format('[%d]', index))
          label:SetFontName('white_16_ol')
          local input = tolua.cast(target:CreateOrGetControl('edit', '_input'..index, label:GetWidth() + label:GetX(), 10, 120, 25), 'ui::CEditControl')
          input:SetFontName('white_16_ol')
          input:SetSkinName('test_weight_skin')
          input:SetTextAlign('center', 'center')
          input:SetOffset(input:GetX(), index * input:GetHeight() + index * 5)
          input:SetText(config)
          label:SetOffset(label:GetX(), index * input:GetHeight() + index * 5 + 4)

          input:SetTypingScp('FIXINVENTORYSORT_ON_INPUT_CUSTOM_TYPING')

          FIXINVENTORYSORT_ON_INPUT_CUSTOM_TYPING = function(parent, ctrl)
            __config[num]['Sort'][index] = ctrl:GetText()
          end

          removeLineButton(target, '_funccustom'..index,
            input:GetX() + input:GetWidth() + 10, input:GetY(), 'Sort', index, nil, num)
        end

        local configSorts = config['Sort']
        local customIndex = #configSorts
        for i = 0, customIndex do
          local sort = configSorts[i]
          self:Dbg(string.format('Create %d of %d config -> Sort.', i, customIndex))
          createCustomSortLineEditor(custombg, sort, i)
        end
        appendLineButton(custombg, '_appendcustom', 30, (customIndex + 1) * 25 + (customIndex + 1) * 5, 'Sort', index)

        custombg:AutoSize(1)
        frame:Invalidate()
      end
    end

    local index = #__config

    for i = 0, index do
      local config = __config[i]
      if (config) then
        self:Dbg(string.format('Create %d of %d config.', i, #__config))
        createSortLineEditor(settingsgb, config, i)
      end
    end
    appendLineButton(settingsgb, '_appendMain', 11, (index + 1) * 25 + (index + 1) * 5, '', index)

-- キーの変更がアレなので一旦忘れよう
    -- local affectTitle = tolua.cast(settingsgb:CreateOrGetControl('richtext', '_affecttitle', 0, (index + 2) * 25 + (index + 2) * 5 + 10, 0, 0), 'ui::CRichText')
    -- affectTitle:SetText('Affect')
    -- affectTitle:SetFontName('white_16_ol')
    --
    -- local createAffectLineEditor = function(target, key, value, index)
    --   local inputkey = tolua.cast(target:CreateOrGetControl('edit', '_affectinputkey'..index, 10, 10, 120, 25), 'ui::CEditControl')
    --   inputkey:SetFontName('white_16_ol')
    --   inputkey:SetSkinName('test_weight_skin')
    --   inputkey:SetTextAlign('center', 'center')
    --   inputkey:SetText(key)
    --   local inputvalue = tolua.cast(target:CreateOrGetControl('edit', '_affectinputvalue'..index, inputkey:GetWidth() + 10, 10, 120, 25), 'ui::CEditControl')
    --   inputvalue:SetFontName('white_16_ol')
    --   inputvalue:SetSkinName('test_weight_skin')
    --   inputvalue:SetTextAlign('center', 'center')
    --   inputvalue:SetText(value)
    --   inputvalue:SetOffset(inputvalue:GetX(), 60 + index * inputvalue:GetHeight() + index * 5)
    --   inputkey:SetOffset(inputkey:GetX(), inputvalue:GetY())
    --
    --   inputkey:SetTypingScp('FIXINVENTORYSORT_ON_INPUT_AFFECT_KEY_TYPING')
    --   inputvalue:SetTypingScp('FIXINVENTORYSORT_ON_INPUT_AFFECT_VALUE_TYPING')
    --
    --   FIXINVENTORYSORT_ON_INPUT_AFFECT_KEY_TYPING = function(parent, ctrl)
    --     local text = ctrl:GetText()
    --     __config['affect'][key] = nil
    --     __config['affect'][text] = ''
    --   end
    --   FIXINVENTORYSORT_ON_INPUT_AFFECT_VALUE_TYPING = function(parent, ctrl)
    --     __config['affect'][key] = ctrl:GetText()
    --   end
    --
    --   removeLineButton(target, '_funcaffect'..index,
    --     inputvalue:GetX() + inputvalue:GetWidth() + 10, inputvalue:GetY(), 'affect', index, key)
    -- end
    --
    -- local affectIndex = 1
    -- if (__config['affect']) then
    --   for k, v in pairs(__config['affect']) do
    --     self:Dbg(string.format('Create %s of %s config -> affect.', k, v))
    --     createAffectLineEditor(settingsgb, k, __config['affect'][k], affectIndex + index)
    --     affectIndex = affectIndex + 1
    --   end
    -- end
    -- index = index + affectIndex
    -- appendLineButton(settingsgb, '_appendAffect', 11, (index + 1) * 25 + (index + 1) * 5 + 30, 'affect', index, affectIndex)

    frame:Invalidate()
    frame:ShowWindow(1)
    self:Dbg('Loading config end.')
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
    if (self.sessionGetInvItemSortedList ~= nil) then
      session.GetInvItemSortedList = self.sessionGetInvItemSortedList
      self.sessionGetInvItemSortedList = nil
    end
    if (self.REQ_INV_SORT ~= nil) then
      REQ_INV_SORT = self.REQ_INV_SORT
      self.REQ_INV_SORT = nil
    end
    if (self.SORT_ITEM_INVENTORY ~= nil) then
      SORT_ITEM_INVENTORY = self.SORT_ITEM_INVENTORY
      self.SORT_ITEM_INVENTORY = nil
    end
  end
  -- おまじない
  return setmetatable(members, {__index = self});
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new});

-- 自フレーム初期化処理
function FIXINVENTORYSORT_ON_INIT(addon, frame)
  -- インベントリソート呼び出し処理をフックしてソート種別を取得する
  if (g.instance.REQ_INV_SORT == nil) then
    g.instance.REQ_INV_SORT = REQ_INV_SORT
  end
  REQ_INV_SORT = function(invType, sortType)
    g.instance.REQ_INV_SORT(invType, sortType)
    g.instance:SetSortType(sortType)
  end
  -- インベントリアイテムの一覧取得処理をフックして正しく並び替えた一覧を返す
  if (g.instance.sessionGetInvItemSortedList == nil) then
    g.instance.sessionGetInvItemSortedList = session.GetInvItemSortedList
  end
  session.GetInvItemSortedList = function()
    local sorted = g.instance:Sort(g.instance.sessionGetInvItemSortedList(), true)
    for i = 0 , sorted:size() - 1 do
      local invItem = sorted:at(i)
      invItem.index = i
    end
    return sorted
  end
  -- インベントリソートメニュー生成処理をフックしてカスタムソートを追加する
  if (g.instance.SORT_ITEM_INVENTORY == nil) then
    g.instance.SORT_ITEM_INVENTORY = SORT_ITEM_INVENTORY
  end
  SORT_ITEM_INVENTORY = function()
    g.instance:CreateSortMenu()
  end
  -- 邪魔な既存ソート処理をどうにかする
  INVENTORY_SORT_BY_GRADE = function(a, b)
    return a.index < b.index
  end
  INVENTORY_SORT_BY_WEIGHT = INVENTORY_SORT_BY_GRADE
  INVENTORY_SORT_BY_NAME = INVENTORY_SORT_BY_GRADE
  INVENTORY_SORT_BY_COUNT = INVENTORY_SORT_BY_GRADE
end

function FIXINVENTORYSORT_ON_REDRAW_CONFIG()
  g.instance:OpenConfig()
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy();
end
g.instance = g();
