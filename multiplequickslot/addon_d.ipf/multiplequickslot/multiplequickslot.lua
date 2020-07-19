-- 領域定義
local author = 'weizlogy'
local addonName = 'multiplequickslot'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- 個別フレームのコンストラクター
function g.new(self)
  local members = {};

  -- === 公開定数 === --
  members.RETURN_NORMALY = 0
  members.NAME_ALREADY_USED = -1001
  members.NAME_IS_EMPTY = -1002
  members.NAME_NOT_FOUND = -1011

  -- === 定数 === --
  local __ADDON_DIR = '../addons/'..addonName
  local __FILE_SLOTSET_NAME_LIST = 'SlotsetNameList.txt'
  local __FILE_SLOTSET_LAST_SELECTED = 'LastSelected.txt'
  local __FILE_COMMON_CONFIG = 'Settings.txt'

  -- === 内部データ === --
  local __config = {};
  local __slotsetNames = {};
  local __lastSelected = -1

  -- === 関数 === --

  --* クイックスロット登録
  members.AddNewSlotset = function(self, newName)
    -- 名前チェック
    if (newName == nil or newName == '') then
      self:Err('At least one character is required.')
      return self.NAME_IS_EMPTY
    end
    local index = 0
    for k, v in pairs(__slotsetNames) do
      if (v == newName) then
        self:Err('The same name already exists.')
        return self.NAME_ALREADY_USED
      end
      index = math.max(index, math.tointeger(k))
    end

    __slotsetNames[tostring(index + 1)] = newName

    -- 最後に保存したものを選択状態に
    __lastSelected = tostring(index + 1)

    -- スロット情報取得
    local slotset = {}

    for i = 1, MAX_QUICKSLOT_CNT do
      local quickSlotInfo = quickslot.GetInfoByIndex(i - 1)
      slotset[i] = {
        ['category'] = quickSlotInfo.category,
        ['type'] = quickSlotInfo.type,
        ['iesid'] = quickSlotInfo:GetIESID(),
      }
    end

    -- 保存
    local cid = info.GetCID(session.GetMyHandle())
    g.i:Serialize(cid..'_'..__FILE_SLOTSET_NAME_LIST, __slotsetNames)
    g.i:Serialize(cid..'_'..Conv2CP932(newName)..'.txt', slotset)
    g.i:Serialize(cid..'_'..__FILE_SLOTSET_LAST_SELECTED, { [1] = __lastSelected })

    return self.RETURN_NORMALY
  end

  --* クイックスロット削除
  members.DeleteSlotset = function(self, name)
    -- 名前チェック
    local index = -1
    for k, v in pairs(__slotsetNames) do
      if (v == name) then
        index = k
      end
    end
    if (index == -1) then
      self:Log('The same name is not found.')
      return
    end

    -- 名前を消す
    __slotsetNames[index] = nil

    -- 最終選択だったら消す
    if (index == __lastSelected) then
      self:Dbg('Remove last selected state.')
      __lastSelected = -1
    end

    -- 保存
    local cid = info.GetCID(session.GetMyHandle())
    g.i:Serialize(cid..'_'..__FILE_SLOTSET_NAME_LIST, __slotsetNames)
    g.i:Serialize(cid..'_'..__FILE_SLOTSET_LAST_SELECTED, { [1] = __lastSelected })

    local res, code = os.remove(__ADDON_DIR..'/'..cid..'_'..Conv2CP932(name)..'.txt')
    if (res == nil) then
      self:Err(code)
    end

    return self.RETURN_NORMALY
  end

  --* 設定読み込み
  members.LoadConfig = function(self)
    local cid = info.GetCID(session.GetMyHandle())
    __slotsetNames = self:Deserialize(cid..'_'..__FILE_SLOTSET_NAME_LIST) or {}

    local tempLastSelected = self:Deserialize(cid..'_'..__FILE_SLOTSET_LAST_SELECTED)
    __lastSelected = tempLastSelected ~= nil and tempLastSelected['1'] or -1

    __config = self:Deserialize(__FILE_COMMON_CONFIG) or {
      ['labelX'] = 0, ['labelY'] = 0,
    }
  end

  --* 描画
  members.DrawUI = function(self, _frame)
    local menuX = 0
    local menuY = -30
    local labelX = 30
    local labelY = -160
    if (_frame:GetName() == 'joystickquickslot') then
      menuX = -26
      menuY = 1
      labelX = 0
      labelY = 25
    end
    labelX = labelX + __config['labelX']
    labelY = labelY + __config['labelY']
    -- 基準点
    local refreshBtn = GET_CHILD(_frame, "refreshBtn", "ui::CButton")
    -- メニューボタン
    local mqsMenu = _frame:CreateOrGetControl(
      'button', 'mqsMenu', refreshBtn:GetX() + menuX, refreshBtn:GetY() + menuY, 20, 25)
    mqsMenu:SetFontName('white_10_ol')
    mqsMenu:SetText('◆')
    mqsMenu:SetEventScript(ui.LBUTTONUP, 'MULTIPLEQUICKSLOT_ON_OPEN_MENU')
    -- スロットセットラベル
    local mqsQCName = _frame:CreateOrGetControl(
      'text', 'mqsQCName', refreshBtn:GetX() + labelX, refreshBtn:GetY() + labelY, 100, 20)
    mqsQCName:SetFontName('white_14_ol')
    mqsQCName:SetText(
      string.format('<%s>', __lastSelected == -1 and '' or __slotsetNames[__lastSelected]))
    mqsQCName:EnableHitTest(1)
    mqsQCName:SetEventScript(ui.RBUTTONUP, 'MULTIPLEQUICKSLOT_ON_OPEN_SLOTSET_LIST')
  end

  --* クイックスロット復元
  members.LoadSlotset = function(self, index, frame)
    local slotsetName = __slotsetNames[index]
    self:Log('Loading '..slotsetName..' ...')
    local cid = info.GetCID(session.GetMyHandle())
    local slotset = self:Deserialize(cid..'_'..Conv2CP932(slotsetName)..'.txt') or {}

    for i = 1, MAX_QUICKSLOT_CNT do
      local slot = GET_CHILD_RECURSIVELY(frame, "slot"..i, "ui::CSlot")
      local slotInfo = slotset[tostring(i)]
      self:Dbg(string.format('slotInfo-%d -> %s %s %s',
        i, slotInfo.category, slotInfo.type, slotInfo.iesid))
      if (slotInfo.category == 'None') then
        slot:ClearText()
        CLEAR_QUICKSLOT_SLOT(slot, 0, true)
      else
        SET_QUICK_SLOT(
          frame, slot, slotInfo.category, slotInfo.type, slotInfo.iesid, 0, true, true)
      end
      slot:Invalidate()
    end
    __lastSelected = index

    -- キーアサイン復元
    QUICKSLOTNEXPBAR_UPDATE_HOTKEYNAME(frame)

    self:Log('Loading '..slotsetName..' Successfully.')
  end

  --* スロットセットの取得
  members.GetSlotsetNameList = function(self)
    return __slotsetNames
  end

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

  --* シリアライズ
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

  --* デシリアライズ
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
function MULTIPLEQUICKSLOT_ON_INIT(addon, frame)
  -- 設定読み込み
  g.i:LoadConfig()

  -- クイックスロット上にUI描画
  g.i:Override('QUICKSLOTNEXPBAR_ON_INIT', function(_addon, _frame)
    g.i:Override('QUICKSLOTNEXPBAR_ON_INIT')(_addon, _frame)
    g.i:DrawUI(ui.GetFrame('quickslotnexpbar'))
  end)
  g.i:Override('JOYSTICKQUICKSLOT_ON_INIT', function(_addon, _frame)
    g.i:Override('JOYSTICKQUICKSLOT_ON_INIT')(_addon, _frame)
    g.i:DrawUI(ui.GetFrame('joystickquickslot'))
  end)
  
  -- テストコード
  QUICKSLOTNEXPBAR_ON_INIT(addon, ui.GetFrame('quickslotnexpbar'))
  JOYSTICKQUICKSLOT_ON_INIT(addon, ui.GetFrame('joystickquickslot'))
end

--* === イベントハンドラー === --
function MULTIPLEQUICKSLOT_ON_OPEN_MENU(frame, ctrl, str, num)
  local menuTitle = 'MultipleQuickSlot'
  local context = ui.CreateContextMenu(
    'CONTEXT_MULTIPLEQUICKSLOT_ON_MENU_SELECT', menuTitle, 0, 0, string.len(menuTitle) * 12, 100)

  ui.AddContextMenuItem(context, 'AddNew', 'MULTIPLEQUICKSLOT_ON_INPUTNEWSLOTNAME')
  ui.AddContextMenuItem(context, 'Delete', 'MULTIPLEQUICKSLOT_ON_DELETESLOTSET')
  ui.AddContextMenuItem(context, 'Reload', 'MULTIPLEQUICKSLOT_ON_RELOAD')
  ui.AddContextMenuItem(context, 'ClearAll', 'MULTIPLEQUICKSLOT_ON_CLEARALL')

  ui.AddContextMenuItem(context, 'Cancel', 'None')
  ui.OpenContextMenu(context)
end

function MULTIPLEQUICKSLOT_ON_INPUTNEWSLOTNAME()
  MULTIPLEQUICKSLOT_ON_ADD = function(frame, newSlotName)
    local res = g.i:AddNewSlotset(newSlotName)
    if (res ~= g.i.RETURN_NORMALY) then
      return
    end
    g.i:DrawUI(ui.GetFrame('quickslotnexpbar'))
    g.i:DrawUI(ui.GetFrame('joystickquickslot'))
  end
  INPUT_STRING_BOX_CB(
    ui.GetFrame('quickslotnexpbar'), 'Input your new quickslot-set name.', "MULTIPLEQUICKSLOT_ON_ADD", "", nil, 0, 50)
end

function MULTIPLEQUICKSLOT_ON_DELETESLOTSET()
  MULTIPLEQUICKSLOT_ON_DELETE = function(frame, deleteSlotName)
    local res = g.i:DeleteSlotset(deleteSlotName)
    if (res ~= g.i.RETURN_NORMALY) then
      return
    end
    g.i:DrawUI(ui.GetFrame('quickslotnexpbar'))
    g.i:DrawUI(ui.GetFrame('joystickquickslot'))
  end
  INPUT_STRING_BOX_CB(
    ui.GetFrame('quickslotnexpbar'), 'Input quickslot-set name that you want to delete.', "MULTIPLEQUICKSLOT_ON_DELETE", "", nil, 0, 50)
end

function MULTIPLEQUICKSLOT_ON_RELOAD()
  g.i:LoadConfig()
  g.i:DrawUI(ui.GetFrame('quickslotnexpbar'))
  g.i:DrawUI(ui.GetFrame('joystickquickslot'))
end

function MULTIPLEQUICKSLOT_ON_CLEARALL()
  MULTIPLEQUICKSLOT_ON_CLEARALL_EXECUTE = function()
    local frame = ui.GetFrame('quickslotnexpbar')
    for i = 1, MAX_QUICKSLOT_CNT do
      local slot = GET_CHILD_RECURSIVELY(frame, "slot"..i, "ui::CSlot")
      slot:ClearText()
      CLEAR_QUICKSLOT_SLOT(slot, 0, true)
      slot:Invalidate()
    end
    local frame2 = ui.GetFrame('joystickquickslot')
    for i = 1, MAX_QUICKSLOT_CNT do
      local slot = GET_CHILD_RECURSIVELY(frame2, "slot"..i, "ui::CSlot")
      slot:ClearText()
      CLEAR_QUICKSLOT_SLOT(slot, 0, true)
      slot:Invalidate()
    end
    QUICKSLOTNEXPBAR_UPDATE_HOTKEYNAME(frame)
  end
  ui.MsgBox('All current quickslot will REMOVED. Are you sure?',
    'MULTIPLEQUICKSLOT_ON_CLEARALL_EXECUTE', 'None')
end

function MULTIPLEQUICKSLOT_ON_OPEN_SLOTSET_LIST()
  local menuTitle = 'MultipleQuickSlot'
  local context = ui.CreateContextMenu(
    'CONTEXT_MULTIPLEQUICKSLOT_ON_MENU_SELECT', menuTitle, 0, 0, string.len(menuTitle) * 12, 100)

  MULTIPLEQUICKSLOT_ON_CHANGESLOTSET = function(index)
    g.i:LoadSlotset(tostring(index), ui.GetFrame('quickslotnexpbar'))
    g.i:LoadSlotset(tostring(index), ui.GetFrame('joystickquickslot'))
    g.i:DrawUI(ui.GetFrame('quickslotnexpbar'))
    g.i:DrawUI(ui.GetFrame('joystickquickslot'))
  end
  for k, v in pairs(g.i:GetSlotsetNameList()) do
    ui.AddContextMenuItem(context, v,
      string.format('MULTIPLEQUICKSLOT_ON_CHANGESLOTSET("%d")', k))
  end

  ui.AddContextMenuItem(context, 'Cancel', 'None')
  ui.OpenContextMenu(context)
end

--* インスタンス作成
if (g.i ~= nil) then
  g.i:Destroy();
end
g.i = g();
