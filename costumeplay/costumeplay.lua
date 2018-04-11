-- 領域定義
local author = 'weizlogy'
local addonName = 'costumeplay'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  local members = {}

  -- コスチューム名入力欄オブジェクト名（なが
  local __SAVE_COSTUME_NAME = 'save_costume_name'
  -- 設定ファイルなどなどの保存先
  local __ADDON_DIR = '../addons/'..addonName
  -- 装備部位データ
  -- SPOT名で引き当て
  local __EQUIP_SPOT_DATA = {
    HAT = { JP = 'ヘアコス１', use = 1, unequip = 'NoHat'},
    HAT_L = { JP = 'ヘアコス３', use = 1, unequip = 'NoHat'},
    HAIR = { JP = '　　　ヘア', use = 1, unequip = 'NoHair'},
    SHIRT = { JP = '　　上半身', use = 0, unequip = 'NoShirt'},
    GLOVES = { JP = '　　　手袋', use = 0, unequip = 'NoGloves'},
    BOOTS = { JP = '　　　　靴', use = 0, unequip = 'NoBoots'},
    HELMET = { JP = 'ヘルメット', use = 0, unequip = 'NoHelmet'},
    ARMBAND = { JP = '　　バンド', use = 1, unequip = 'NoArmband'},
    RH = { JP = '　　　右手', use = 1, unequip = 'NoWeapon'},
    LH = { JP = '　　　左手', use = 1, unequip = 'NoWeapon'},
    OUTER = { JP = '　　　コス', use = 1, unequip = 'NoOuter'},
    OUTERADD1 = { JP = '　　　　　', use = 0, unequip = 'NoOuter'},
    OUTERADD2 = { JP = '　　　　　', use = 0, unequip = 'NoOuter'},
    BODY = { JP = '　　　　　', use = 0, unequip = 'NoOuter'},
    PANTS = { JP = '　　下半身', use = 0, unequip = 'NoRing'},
    PANTSADD1 = { JP = '　　　　　', use = 0, unequip = 'NoRing'},
    PANTSADD2 = { JP = '　　　　　', use = 0, unequip = 'NoRing'},
    RING1 = { JP = '　ブレス右', use = 0, unequip = 'NoRing'},
    RING2 = { JP = '　ブレス左', use = 0, unequip = 'NoRing'},
    NECK = { JP = 'ネックレス', use = 0, unequip = 'NoNeck'},
    HAT_T = { JP = 'ヘアコス２', use = 1, unequip = 'NoHat'},
    LENS = { JP = 'コンタクト', use = 1, unequip = 'NoOuter'},
    WING = { JP = '　　　　翼', use = 1, unequip = 'NoOuter'},
    SPECIALCOSTUME = { JP = '　スペコス', use = 1, unequip = 'NoOuter'},
    EFFECTCOSTUME = { JP = 'エフェクト', use = 1, unequip = 'NoOuter'},
    -- 変換処理
    Convert = function(self, key)
      local translated = self[key][GetServerNation()]
      if (translated == nil) then
        return key
      end
      return translated
    end,
    -- デフォルト使用可否取得
    -- 0：未使用 / 1：使用
    IsUse = function(self, key)
      return self[key]['use']
    end,
    -- 未装備クラス名取得
    UnEquip = function(self, key)
      return self[key]['unequip']
    end
  }
  
  -- 全コスチュームデータ
  local _costumes = {}

  -- システムメニューのインベントリボタンをカスタマイズ
  members.CustomSysMenu = function(self)
    local sysmenuInv = ui.GetFrame('sysmenu'):GetChild('inven')
    sysmenuInv = tolua.cast(sysmenuInv, 'ui::CButton')
    sysmenuInv:SetEventScript(ui.RBUTTONUP, 'COSTUMEPLAY_ON_INVEN_SELECT_MENU')
  end

  --- コスチューム選択メニュー - コスチューム選択
  members.ShowCostumeInvenSelectMenu = function(self)
    self:Dbg('ShowCostumeInvenSelectMenu called.')
    local menuTitle = 'CostumePlay'
    local context = ui.CreateContextMenu(
      'CONTEXT_COSTUMEPLAY_ON_COSTUME_SELECT', menuTitle, 0, 0, string.len(menuTitle) * 12, 100)
    -- コスチューム情報からメニューを作る
    for title, equips in pairs(_costumes) do
      ui.AddContextMenuItem(context, title, string.format('COSTUMEPLAY_SELECT_ON_EQUIP("%s")', title))
    end
    ui.AddContextMenuItem(context, 'Cancel', 'None')
    ui.OpenContextMenu(context)
  end

  -- コスチューム装備
  members.CostumeSelectOnEquip = function(self, title)
    self:Dbg('CostumeSelectOnEquip called.'..title)
    local equips = _costumes[title]
    if (equips == nil) then
      self:Err('Target costume data not found. ('..title)
    end
    -- 装備処理
    -- item.equipを連続コールすると素直にお着替えできないのでいろいろがんばる
    self:Log('Costume change start.'..title)
    local useCount = 0  -- 着替え回数（これをDebounceScriptの第二引数に渡して間隔調整する
    for index, equip in ipairs(equips) do
      -- 装備対象だけ
      if (equip.use == 1) then
        useCount = useCount + 1
        local itemCls = GetClassByType('Item', equip.id)
        local className = itemCls.ClassName
        local spotkey = item.GetEquipSpotName(equip.slot)
        -- 装備解除の場合
        if (__EQUIP_SPOT_DATA:UnEquip(spotkey) == className) then
          -- 動的に装備関数を作ってDebounceScriptで一定時間後に呼び出すことで
          -- 時間差でお着替えさせる
          local tempFuncName = 'COSTUMEPLAY_ON_UNEQUIP'..spotkey
          _G[tempFuncName] = function()
            self:Log('UnEquip '..__EQUIP_SPOT_DATA:Convert(spotkey))
            item.UnEquip(equip.slot)
            _G[tempFuncName] = nil
            DebounceScript('COSTUMEPLAY_ON_EQUIP_END', 3.0)
          end
          DebounceScript(tempFuncName, useCount / 2)
        else
          -- インベントリにあるものだけ
          local invItem = session.GetInvItemByName(className)
          if (invItem ~= nil) then
            local tempFuncName = 'COSTUMEPLAY_ON_EQUIP'..spotkey..invItem.invIndex
            _G[tempFuncName] = function()
              self:Log('Equip '..__EQUIP_SPOT_DATA:Convert(spotkey)..' -> '..itemCls.Name)
              item.Equip(spotkey, invItem.invIndex)
              _G[tempFuncName] = nil
              -- 装備完了ログ出力用の動的関数
              -- DebounceScriptで同名関数は時間を上書きするので最後の一回のみ呼ばれる
              DebounceScript('COSTUMEPLAY_ON_EQUIP_END', 3.0)
            end
            DebounceScript(tempFuncName, useCount / 2)
          end
        end
      end
    end
  end

  -- コスチューム管理メニュー
  members.ShowCostumeManageMenu = function(self, ctrl, title, num)
    self:Dbg('ShowCostumeManageMenu called.')
    local menuTitle = title
    local context = ui.CreateContextMenu(
      'CONTEXT_COSTUMEPLAY_ON_COSTUME_MANAGE', menuTitle, 0, 0, string.len(menuTitle) * 12, 100)
    ui.AddContextMenuItem(context, 'Remove', string.format('COSTUMEPLAY_MANAGE_ON_REMOVE("%s")', title))
    ui.AddContextMenuItem(context, 'Cancel', 'None')
    ui.OpenContextMenu(context)
  end

  -- コスチューム管理メニュー - 削除（ファイルに永続化
  members.CostumeManageOnRemove = function(self, title)
    self:Dbg('CostumeManageOnRemove called.')
    _costumes[title] = nil
    self:Log(title..' is Removed.')
    self:__Serialize()
  end

  -- コスチュームの使用可否を個別に切り替える
  members.ToggleCostumeUse = function(self, ctrl, title, index)
    self:Dbg('ToggleCostumeUse called.'..'('..title..' - '..index)
    local equip = _costumes[title][index]
    if (equip == nil) then
      self:Dbg('Selected item is nil.')
      return
    end
    equip.use = equip.use == 0 and 1 or 0
    self:__DecorateEquipUI(ctrl, title, equip, index)
  end

  -- インベントリ系関数をフックして任意のコードを実行させる
  members.HookInventry = function(self)
    -- インベントリを開くときに自フレームも追従
    if (self.INVENTORY_OPEN == nil) then
      self.INVENTORY_OPEN = INVENTORY_OPEN
    end
    INVENTORY_OPEN = function(frame)
      self.INVENTORY_OPEN(frame)
      DebounceScript('COSTUMEPLAY_ON_OPEN', 1.0)
    end
    -- インベントリを閉じるときに自フレームも追従
    if (self.INVENTORY_CLOSE == nil) then
      self.INVENTORY_CLOSE = INVENTORY_CLOSE
    end
    INVENTORY_CLOSE = function(frame)
      self.INVENTORY_CLOSE(frame)
      ui.GetFrame('costumeplay'):ShowWindow(0)
    end
  end

  -- 自フレーム生成
  members.CreateFrame = function(self)
    local frame = ui.GetFrame('inventory')
    local costumeplay = ui.GetFrame('costumeplay')
    -- インベントリの横に5px開けて付ける
    -- frame:GetX()としたいところだが、inventoryがopen=pip指定のため定まらないっぽい
    costumeplay:Resize(350, 500)
    costumeplay:SetOffset(1430 - costumeplay:GetWidth() - 5, frame:GetY())
    costumeplay:SetSkinName('test_frame_low')
    costumeplay:EnableMove(0)
    -- 保存するコスチューム名の入力欄
    local savecosname = costumeplay:CreateOrGetControl('edit', __SAVE_COSTUME_NAME,10 , 10, 250, 30)
    tolua.cast(savecosname, 'ui::CEditControl')
    savecosname:SetEnableEditTag(1)
    savecosname:SetFontName('white_14_ol')
    -- 保存ボタン
    local save = costumeplay:CreateOrGetControl('button', 'save', 10 + savecosname:GetWidth(), 10, 60, 30)
    tolua.cast(save, 'ui::CButton')
    save:SetText('{s14}{ol}save')
    save:SetEventScript(ui.LBUTTONUP, 'COSTUMEPLAY_SAVE')
    -- コスチューム一覧背景
    local bgInitY = 50
    local bg = costumeplay:CreateOrGetControl('groupbox', 'bg', 0, 0, 0, 0)
    tolua.cast(bg, 'ui::CGroupBox')
    bg:SetSkinName('None')
    bg:Resize(costumeplay:GetWidth() - 5, costumeplay:GetHeight() - bgInitY - 10)
    bg:SetOffset(0, bgInitY)
    bg:EnableScrollBar(1)
    -- コスチューム一覧
    DESTROY_CHILD_BYNAME(bg, 'costumebox_')
    local i = 0
    local boxHeight = 130
    local boxMargin = 5
    for title, equips in pairs(_costumes) do
      -- 入れ物作って
      local box = bg:CreateOrGetControl('groupbox', 'costumebox_'..title, 0, 0, 0, 0)
      tolua.cast(box, 'ui::CGroupBox')
      box:SetSkinName('downbox')
      box:Resize(costumeplay:GetWidth() - 40, boxHeight)
      box:SetOffset(10, i * (box:GetHeight() + boxMargin))
      box:SetEventScript(ui.RBUTTONUP, 'COSTUMEPLAY_ON_MANAGE_MENU')
      box:SetEventScriptArgString(ui.RBUTTONUP, title)
      box:SetEventScriptArgNumber(ui.RBUTTONUP, 0)
      box:EnableHitTest(1)
      box:EnableHittestGroupBox(true)
        i = i + 1
      -- 入れ物の中身
      local titleText = box:CreateOrGetControl('richtext', 'text_'..title, 0, 0, 0, 0)
      titleText:SetText('{s14}{ol}'..title)
      titleText:Resize(100, 20)
      for j, equip in ipairs(equips) do
        local equipText = box:CreateOrGetControl('richtext', 'equip_'..j, 0, 0, 0, 0)
        self:__DecorateEquipUI(equipText, title, equip, j)
      end
    end
    costumeplay:SetAlpha(75)
    costumeplay:ShowWindow(1)
    costumeplay:Invalidate()
  end

  -- コスチューム個々のUIを装飾
  -- 登録/更新時に使えるように
  members.__DecorateEquipUI = function(self, equipText, title, equip, index)
    local itemCls = GetClassByType('Item', equip.id)
    local spotkey = item.GetEquipSpotName(equip.slot)
    equipText:SetText('{s14}{ol}'..__EQUIP_SPOT_DATA:Convert(spotkey)..' - '..itemCls.Name)
    equipText:SetTextTooltip(itemCls.Name)
    equipText:Resize(100, 20)
    equipText:SetOffset(10, 20 * index)
    equipText:SetColorTone('00000000')
    if (equip.use == 0) then
      equipText:SetColorTone('66000000')
    end
    equipText:SetEventScript(ui.LBUTTONUP, 'COSTUMEPLAY_ON_TOGGLE_USE')
    equipText:SetEventScriptArgString(ui.LBUTTONUP, title)
    equipText:SetEventScriptArgNumber(ui.LBUTTONUP, index)
    equipText:EnableHitTest(1)
  end

  -- コスチューム保存名を取得
  -- 入力欄が空だったら適当な名前を付ける
  members.GetSaveTitleOrDefault = function(self, frame)
    local title = GET_CHILD(frame, __SAVE_COSTUME_NAME, 'ui::CEditControl'):GetText()
    if (title == '') then
      -- 衝突確率を低く抑え...
      title = 'CP-'..IMCRandom(100, 999)..IMCRandom(100, 999)
    end
    return title
  end

  -- コスチューム保存（ファイルに永続化
  members.Save = function(self, title)
    self:Log('Saving...'..title)
    local data = self:__CollectEquipData()
    _costumes[title] = data
    self:__Serialize()
  end

  -- データ収集
  members.__CollectEquipData = function(self)
    local data = {}
    local equiplist = session.GetEquipItemList()
    for i = 0, equiplist:Count() - 1 do
      local equipInfo = {}
      local equipItem = equiplist:Element(i)
      local itemCls = GetIES(equipItem:GetObject())
      local name = string.lower(dictionary.ReplaceDicIDInCompStr(itemCls.Name))
      self:Dbg(item.GetEquipSpotName(equipItem.equipSpot).." - "..name..'('..itemCls.ClassName)
      equipInfo.slot = equipItem.equipSpot
      equipInfo.id = itemCls.ClassID
      equipInfo.use = __EQUIP_SPOT_DATA:IsUse(item.GetEquipSpotName(equipItem.equipSpot))
      table.insert(data, equipInfo)
    end
    return data
  end

  -- ファイルに保存する
  members.__Serialize = function(self)
    local cid = info.GetCID(session.GetMyHandle())
    local f, e = io.open(string.format('%s/%s', __ADDON_DIR, cid), 'w')
    if (e) then
      self:Err('Failed to save costumes to file.'..cid)
      self:Err(tostring(e))
      return
    end
    f:write('local s = {}\n')
    for title, costume in pairs(_costumes) do
      f:write(string.format('s[\'%s\'] = {', title))
      for i, equip in ipairs(costume) do
        f:write(string.format('{slot=%s,id=%s,use=%s},', equip.slot, equip.id, equip.use))
      end
      f:write('}\n')
    end
    f:write('return s')
    f:flush()
    f:close()
    self:Log('Save costumes to file.'..cid)
  end

  -- ファイルから読み込む
  members.LoadCostumes = function(self)
    local cid = info.GetCID(session.GetMyHandle())
    self:Dbg('Loading costumes file...'..cid)
    local file = string.format('%s/%s', __ADDON_DIR, cid)
    local f, e = io.open(file, 'r')
    if (e or f == nil) then
      self:Dbg('Nothing to load costumes from file.')
      return
    end
    f:close()
    _costumes = dofile(file)
    self:Log('Load costumes from file.')
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
    if (self.INVENTORY_OPEN ~= nil) then
      INVENTORY_OPEN = self.INVENTORY_OPEN
    end
    if (self.INVENTORY_CLOSE ~= nil) then
      INVENTORY_CLOSE = self.INVENTORY_CLOSE
    end
  end
  -- おまじない
  return setmetatable(members, {__index = self})
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new})

-- 自フレーム初期化処理
function COSTUMEPLAY_ON_INIT(addon, frame)
  g.instance:Dbg('COSTUMEPLAY_ON_INIT called.')
  addon:RegisterMsg('GAME_START_3SEC', 'COSTUMEPLAY_GAME_START_3SEC')
end

-- 自フレーム初期化処理の続き
function COSTUMEPLAY_GAME_START_3SEC()
  g.instance:LoadCostumes()
  g.instance:CustomSysMenu()
  g.instance:HookInventry()
end

-- 自フレームオープン処理
-- 連打対策いろいろ
function COSTUMEPLAY_ON_OPEN()
  local frame = ui.GetFrame('inventory')
  -- 表示アクション中ならリトライ
  if (frame:IsPIPMoving() == 1) then
    DebounceScript('COSTUMEPLAY_ON_OPEN', 1.0)
    return
  end
  -- アクション終わってフレーム消えてたらおしまい
  if (frame:IsVisible() == 0) then
    return
  end
  -- 表示する
  g.instance:CreateFrame()
end

-- 自フレームクローズ処理
-- ESCキーでインベントリだけ残ってしまうので、自分が消えたらインベントリも消す
function COSTUMEPLAY_ON_CLOSE()
  INVENTORY_CLOSE(ui.GetFrame('inventory'))
end

-- コスチューム選択メニュー表示
function COSTUMEPLAY_ON_INVEN_SELECT_MENU()
  g.instance:ShowCostumeInvenSelectMenu()
end

-- コスチューム装備
function COSTUMEPLAY_SELECT_ON_EQUIP(title)
  g.instance:CostumeSelectOnEquip(title)
end

-- コスチューム管理メニュー表示
function COSTUMEPLAY_ON_MANAGE_MENU(frame, ctrl, str, num)
  g.instance:ShowCostumeManageMenu(ctrl, str, num)
end

-- コスチューム削除して再描画
function COSTUMEPLAY_MANAGE_ON_REMOVE(title)
  g.instance:CostumeManageOnRemove(title)
  g.instance:CreateFrame()
end

-- コスチューム切り替えの一時的な切り替え操作
function COSTUMEPLAY_ON_TOGGLE_USE(frame, ctrl, str, num)
  g.instance:ToggleCostumeUse(ctrl, str, num)
end

-- 現在の装備を保存して再描画
function COSTUMEPLAY_SAVE(frame, ctrl, str, num)
  g.instance:Dbg('COSTUMEPLAY_SAVE called.')
  local title = g.instance:GetSaveTitleOrDefault(frame)
  g.instance:Save(title)
  g.instance:CreateFrame()
end

function COSTUMEPLAY_ON_EQUIP_END()
  g.instance:Log('Equip costumes finished.')
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy()
end
g.instance = g()
