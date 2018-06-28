-- 領域定義
local author = 'weizlogy'
local addonName = 'summoncounter'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  local members = {};

  -- 捕捉した召喚物のハンドル
  members.Handles = {}

  -- UI位置座標
  members.x = -1
  members.y = -1
  members.w = -1
  members.h = -1
  
  -- 設定ファイルへのパス
  members.path = '../addons/summoncounter'

  -- 召喚物のカウントを開始する
  -- slot     召喚スキルのクイックスロット
  -- maxCount 召喚物の最大量
  -- findfn   補足対象の召喚物判定関数
  -- findhfn  オーナーハンドル取得関数
  members.Start = function(self, slot, maxCount, findfn, findhfn)
    if (findhfn == nil) then
      findhfn = 'Common_MySession'
    end
    slot:SetUserValue('SUMMONCOUNTER_MAXCOUNT', maxCount)
    slot:SetUserValue('SUMMONCOUNTER_FINDFUNCTION', findfn)
    slot:SetUserValue('SUMMONCOUNTER_FINDHANDLEFUNCTION', findhfn)
    slot:RunUpdateScript('SUMMONCOUNTER_UPDATE', 0, 0, 0, 1)
  end

  -- 設定ファイルを読み込む
  members.LoadSettings = function(self)
    dofile(self.path..'/settings.txt')
  end

  -- UIの初期値を設定する
  members.LoadPositions = function(self)
    local bufferW = 90
    local bufferH = 250
    local frame = ui.GetFrame('charbaseinfo1_my')
    self.x = frame:GetX() + bufferW / 2
    self.y = frame:GetY() - bufferH
    self.w = frame:GetWidth() - bufferW
    self.h = frame:GetHeight() + bufferH
  end

  -- ボコル - ゾンビフィーの召喚物を判定する
  members.Bokor_Zombify = function(name)
    return
         name == 'summons_zombie'
      or name == 'Zombie_Overwatcher'
      or name == 'Zombie_hoplite'
  end
  -- ネクロマンサー - レイズデッドの召喚物を判定する
  members.Necromancer_RaiseDead = function(name)
    return name == 'pcskill_skullsoldier'
  end
  -- ネクロマンサー - レイズスカルアーチャーの召喚物を判定する
  members.Necromancer_RaiseSkullarcher = function(name)
    return name == 'pcskill_skullarcher'
  end
  -- ネクロマンサー - コープスタワーの召喚物を判定する
  members.Necromancer_CorpseTower = function(name)
    return name == 'pcskill_skullsoldier'
  end
  -- ネクロマンサー - クリエイトショゴスの召喚物を判定する
  members.Necromancer_CreateShoggoth = function(name)
    return name == 'pcskill_shogogoth'
  end

  -- デフォルトのオーナーハンドルを取得する
  members.Common_MySession = function()
    return session.GetMyHandle()
  end
  -- ネクロマンサー - コープスタワーのオーナーハンドルを取得する
  -- コープスタワーの特性でスケルトンソルジャーが発生するが、オーナーはコープスタワーじゃないの...？
  members.Necromancer_CorpseTower_FindHandle = function()
    local handle = -1
    local list, count = SelectBaseObject(GetMyPCObject(), 500, 'ALL')
    for i = 1 , count do
      local obj = list[i]
      local iesObj = GetBaseObjectIES(obj)
      if (iesObj.ClassName == 'pcskill_CorpseTower') then
        local actor = tolua.cast(obj, 'CFSMActor')
        handle = actor:GetHandleVal()
        break
      end
    end
    return handle
  end

  -- 召喚物の情報をUIに表示する
  members.Show = function(self)
    -- キャンバス作成
    local frame = ui.GetFrame('summoncounter')
    frame:SetSkinName('downbox')
    frame:SetAlpha(0)
    frame:Resize(suco.w, suco.h)
    frame:SetOffset(suco.x, suco.y)
    frame:ShowWindow(1)
    frame:EnableMove(0)
    frame:EnableHittestFrame(0)

    for key, value in pairs(self.Handles) do
      -- 設定ファイルで指定されたUIの設定を取得する
      local config = suco.config[key]
      if (config == nil) then
        CHAT_SYSTEM('[summoncounter] something wrong at config file with key='..key)
        return
      end

      -- 自分で作ったものは片付ける
      DESTROY_CHILD_BYNAME(frame, 'vw_'..key..'_')

      -- ストラテジーを決めてー
      local modeLogic = nil
      if (config.mode == 'hpbar') then
        modeLogic = ModeHPBar()
      elseif (config.mode == 'icon1') then
        modeLogic = ModeIcon1()
      elseif (config.mode == 'icon2') then
        modeLogic = ModeIcon2()
      end

      -- 実行する
      modeLogic.Key = key
      modeLogic.Handles = value
      modeLogic:Execute(frame, config)
    end
  end

  -- 捕捉した召喚物のハンドルを消す
  -- findfn 補足対象の召喚物判定関数
  members.ClearHandle = function(self, findfn)
    self.Handles[findfn] = {}
  end

  -- 捕捉した召喚物のハンドルを消す
  -- handle 削除対象ハンドル
  -- findfn 補足対象の召喚物判定関数
  members.PutHandle = function(self, handle, findfn)
    table.insert(self.Handles[findfn], handle)
  end

  -- デストラクター
  members.Destroy = function(self)
    --UI_CHAT = suco.UI_CHAT
  end
  -- おまじない
  return setmetatable(members, {__index = self});
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new});

-- 自フレーム初期化処理
function SUMMONCOUNTER_ON_INIT(addon, frame)
  addon:RegisterMsg('GAME_START_3SEC', 'SUMMONCOUNTER_REFRESH_KICKER')
  addon:RegisterMsg('GAME_START_3SEC', 'SUMMONCOUNTER_LOAD_AT_ONCE')

  -- チャットコマンド作成
  if (suco.UI_CHAT == nil) then
    suco.UI_CHAT = UI_CHAT
  end
  UI_CHAT = function(msg)
    if (msg == '/summonc reload') then
      suco:LoadSettings()
      CHAT_SYSTEM('[summoncounter] settings reloaded.')
    end
    suco.UI_CHAT(msg)
  end
end

-- 設定ファイル読み込み
function SUMMONCOUNTER_LOAD_AT_ONCE()
  suco:LoadSettings()
  suco:LoadPositions()
end

function SUMMONCOUNTER_REFRESH_KICKER()
  SUMMONCOUNTER_REFRESH(ui.GetFrame('quickslotnexpbar'))
  SUMMONCOUNTER_REFRESH(ui.GetFrame('joystickquickslot'))
end

-- 召喚物の補足を開始する
function SUMMONCOUNTER_REFRESH(frame)
  local pc = GetMyPCObject()
  -- 召喚スキルのクイックスロットを探して、召喚物をカウントし始める
  for i = 0, MAX_QUICKSLOT_CNT - 1 do
    local quickSlotInfo = quickslot.GetInfoByIndex(i)
    if (quickSlotInfo.category == 'Skill') then
      local slot = GET_CHILD_RECURSIVELY(frame, 'slot'..(i + 1), 'ui::CSlot')
      local skill = session.GetSkill(quickSlotInfo.type)
      local obj = GetIES(skill:GetObject())
      if (obj.ClassName == 'Bokor_Zombify') then
        -- ８固定になった
        suco:Start(slot, 8, obj.ClassName)
      elseif (obj.ClassName == 'Necromancer_RaiseDead') then
        suco:Start(slot, obj.Level, obj.ClassName)
      elseif (obj.ClassName == 'Necromancer_RaiseSkullarcher') then
        suco:Start(slot, obj.Level, obj.ClassName)
      elseif (obj.ClassName == 'Necromancer_CorpseTower') then
        -- g:Start(slot, obj.Level, obj.ClassName, obj.ClassName..'_FindHandle')
      elseif (obj.ClassName == 'Necromancer_CreateShoggoth') then
        suco:Start(slot, 1, obj.ClassName)
      end
    end
  end
end

-- 召喚物をカウントする
function SUMMONCOUNTER_UPDATE(slot)
  local findfunc = slot:GetUserValue('SUMMONCOUNTER_FINDFUNCTION')
  local findhfunc = slot:GetUserValue('SUMMONCOUNTER_FINDHANDLEFUNCTION')

  suco:ClearHandle(findfunc)

  local summons = 0
  local list, count = SelectBaseObject(GetMyPCObject(), 500, 'ALL')
  for i = 1 , count do
    local obj = list[i]
    local iesObj = GetBaseObjectIES(obj)
    local actor = tolua.cast(obj, 'CFSMActor')
    local handle = actor:GetHandleVal()
    local ownerHandle = info.GetOwner(handle)
    if (ownerHandle == suco[findhfunc]() and suco[findfunc](iesObj.ClassName)) then
      summons = summons + 1
      suco:PutHandle(handle, findfunc)
    end
  end
  local maxsummons = slot:GetUserValue('SUMMONCOUNTER_MAXCOUNT')
  local counter = slot:CreateOrGetControl('richtext', 'summon_count', 0, 0, 20, 10)
  tolua.cast(counter, 'ui::CRichText')
  counter:SetText('{ol}{s14}'..summons..'/'..maxsummons)
  counter:SetOffset(slot:GetWidth() - counter:GetWidth(), 0)

  suco:Show()
  return 1
end

-- インスタンス作成
if (suco ~= nil) then
  suco:Destroy()
end
suco = g()

-- ===================== --
-- ここからサブクラス群  --
-- ===================== --

-- HPバー表示モード
-- 召喚物のHP合計をMAXとしたHPバーを生成する
ModeHPBar = {}

-- コンストラクター
function ModeHPBar.new(self)
  
  local members = {}

  members.Key = ''
  members.Handles = {}

  -- モード処理を実行する
  -- frame  UI生成先フレーム
  -- config モード用設定
  members.Execute = function(self, frame, config)
    local totalHP, totalMHP = self:CalculateHP()
    if (totalHP <= 0) then
      DESTROY_CHILD_BYNAME(frame, 'summonsHPGauge_'..self.Key)
      DESTROY_CHILD_BYNAME(frame, 'summonsHPGaugeName_'..self.Key)
      return
    end

    local locframe = config['loc_frame']
    frame:SetOffset(locframe.x, locframe.y)

    local locbar = config['loc_bar']

    local summonsHPGauge = frame:CreateOrGetControl(
      'gauge', 'summonsHPGauge_'..self.Key, 0, 0, 188 - 10, 0)
    tolua.cast(summonsHPGauge, 'ui::CGauge')
    summonsHPGauge:SetMargin(20, 20, 20, 20)
    summonsHPGauge:Resize(summonsHPGauge:GetWidth(), 30)
    summonsHPGauge:SetOffset(locbar.x, locbar.y)
    summonsHPGauge:SetPoint(totalHP, totalMHP)

    summonsHPGauge:SetSkinName('necronomicon_amount')
    summonsHPGauge:SetColorTone('FFCCCCCC')

    if summonsHPGauge:GetStat() == 0 then
      summonsHPGauge:AddStat('%v / %m')
      summonsHPGauge:SetStatFont(0, 'white_14_ol')
      summonsHPGauge:SetStatOffset(0, 0, -3)
      summonsHPGauge:SetStatAlign(0, 'center', 'center')
    end

    summonsHPGauge:EnableHitTest(0)
    summonsHPGauge:ShowWindow(1)
    frame:ShowWindow(1)
  end

  -- 召喚物のHP、MAXHPの合計を取得する
  members.CalculateHP = function(self)
    local totalHP = 0
    local totalMHP = 0
    for i, handle in ipairs(self.Handles) do
      local stat = info.GetStat(handle)
        totalHP = totalHP + stat.HP
        totalMHP = totalMHP + stat.maxHP
    end
    -- for create empty gauge.
    if (totalMHP == 0) then
      totalHP = -1
      totalMHP = 1
    end
    return totalHP, totalMHP
  end

  -- おまじない
  return setmetatable(members, {__index = self})
end
setmetatable(ModeHPBar, {__call = ModeHPBar.new})

-- アイコン表示モード１
-- 召喚物をアイコンで、キャラクターの左右に表示する
ModeIcon1 = {}

-- コンストラクター
function ModeIcon1.new(self)
  local members = {}
  
  members.Key = ''
  members.Handles = {}

  -- モード処理を実行する
  -- frame  UI生成先フレーム
  -- config モード用設定
  members.Execute = function(self ,frame, config)
    for i, handle in ipairs(self.Handles) do
      self:CreateSummonIcon(frame, handle, config, i)
    end
  end

  -- 召喚物アイコンを作成する
  -- frame  UI生成先フレーム
  -- handle 召喚物のハンドル
  -- config モード用設定
  -- index  表示位置
  members.CreateSummonIcon = function(self, frame, handle, config, index)
    local iconName = 'vw_'..self.Key..'_'..handle

    local iconSize = 35
    local iconPos = config.loc
    local iconXBase = 0

    if (iconPos == 'left') then
      iconXBase = 3
    elseif (iconPos == 'right') then
      iconXBase = 1.6
    end

    local pic = frame:CreateOrGetControl('picture', iconName, 0, 0, iconSize, iconSize)
    tolua.cast(pic, 'ui::CPicture')

    local loc = config['loc'..index]
    local x = frame:GetWidth() / iconXBase + loc.x
    local y = 90 + loc.y

    pic:SetImage('summoncounter_necro_skull')
    pic:SetEnableStretch(1)
    pic:SetOffset(x, y)
    pic:EnableHitTest(0)
  end

  return setmetatable(members, {__index = self})
end
setmetatable(ModeIcon1, {__call = ModeIcon1.new})

-- アイコン表示モード２
-- 召喚物をアイコンで、キャラクターの上下に表示する
ModeIcon2 = {}

function ModeIcon2.new(self)
  local members = {}
  
  members.Key = ''
  members.Handles = {}

  -- モード処理を実行する
  -- frame  UI生成先フレーム
  -- config モード用設定
  members.Execute = function(self, frame, config)
    for i, handle in ipairs(self.Handles) do
      self:CreateSummonIcon(frame, handle, config, i)
    end
  end

  -- 召喚物アイコンを作成する
  -- frame  UI生成先フレーム
  -- handle 召喚物のハンドル
  -- config モード用設定
  -- index  表示位置
  members.CreateSummonIcon = function(self, frame, handle, config, index)
    local iconName = 'vw_'..self.Key..'_'..handle

    local iconSize = 60
    local iconPos = config.loc
    local iconYBase = 0
    local iconCenterMarginX = -27

    if (iconPos == 'up') then
      iconYBase = 0.4
    elseif (iconPos == 'down') then
      iconYBase = 3.6
    end

    local pic = frame:CreateOrGetControl('picture', iconName, 0, 0, iconSize, iconSize)
    tolua.cast(pic, 'ui::CPicture')

    local loc = config['loc'..index]
    local x = (frame:GetWidth() / 2) + loc.x + iconCenterMarginX
    local y = (90 + loc.y) * iconYBase

    pic:SetImage('summoncounter_necro_circle')
    pic:SetEnableStretch(1)
    pic:SetOffset(x, y)
    pic:EnableHitTest(0)
  end

  return setmetatable(members, {__index = self})
end
setmetatable(ModeIcon2, {__call = ModeIcon2.new})
