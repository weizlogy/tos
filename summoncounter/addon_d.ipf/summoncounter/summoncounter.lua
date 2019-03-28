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
  -- 設定ファイルなどなどの保存先
  local __ADDON_DIR = '../addons/'..addonName

  local members = {};

  -- 捕捉した召喚物のハンドル
  members.Handles = {}

  -- UI位置座標
  members.x = -1
  members.y = -1
  members.w = -1
  members.h = -1

  -- スキル別設定
  members.skillConfig = {}

  -- 召喚物のカウントを開始する
  -- slot      召喚スキルのクイックスロット
  -- slv       スキルレベル
  -- className クラス名
  members.Start = function(self, slot, slv, className)
  -- maxCount 召喚物の最大量
  -- findfn   補足対象の召喚物判定関数
  -- findhfn  オーナーハンドル取得関数
    local findfn = className
    local findhfn = 'Common_MySession'
    local maxCountfn = self[className..'_MaxCount']

    if (maxCountfn == nil) then
      return
    end

    -- スキル個別自動設定を取得
    if (not self.skillConfig[className]) then
      self.skillConfig[className] = self:Deserialize(className..'.txt')
    end

    slot:SetUserValue('SUMMONCOUNTER_MAXCOUNT', maxCountfn(slv))
    slot:SetUserValue('SUMMONCOUNTER_FINDFUNCTION', findfn)
    slot:SetUserValue('SUMMONCOUNTER_FINDHANDLEFUNCTION', findhfn)
    slot:RunUpdateScript('SUMMONCOUNTER_UPDATE', 0, 0, 0, 1)
  end

  -- 設定ファイルを読み込む
  members.LoadSettings = function(self)
    dofile(__ADDON_DIR..'/settings.txt')
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

  -- ******************************************** --
  -- ***             クリオマンサー           *** --
  -- ******************************************** --

  members.Cryomancer_FrostPillar = function(name)
    return 'attract_pillar'
  end
  members.Cryomancer_FrostPillar_MaxCount = function(slv)
    return 1
  end

  -- ******************************************** --
  -- ***                ボコル                *** --
  -- ******************************************** --

  -- ゾンビフィーの召喚物を判定する
  members.Bokor_Zombify = function(name)
    return
         name == 'summons_zombie'
      or name == 'Zombie_Overwatcher'
      or name == 'Zombie_hoplite'
  end
  members.Bokor_Zombify_MaxCount = function(slv)
    return 8
  end

  -- ******************************************** --
  -- ***             ネクロマンサー           *** --
  -- ******************************************** --

  -- レイズデッドの召喚物を判定する
  members.Necromancer_RaiseDead = function(name)
    return name == 'pcskill_skullsoldier'
  end
  members.Necromancer_RaiseDead_MaxCount = function(slv)
    return 5
  end
  -- レイズスカルアーチャーの召喚物を判定する
  members.Necromancer_RaiseSkullarcher = function(name)
    return name == 'pcskill_skullarcher'
  end
  members.Necromancer_RaiseSkullarcher_MaxCount = function(slv)
    return 5
  end
  -- レイズスカルウィザードの召喚物を判定する
  members.Necromancer_RaiseSkullwizard = function(name)
    return name == 'pcskill_skullwizard'
  end
  members.Necromancer_RaiseSkullwizard_MaxCount = function(slv)
    return 5
  end
  -- コープスタワーの召喚物を判定する
  members.Necromancer_CorpseTower = function(name)
    return name == 'pcskill_CorpseTower'
  end
  members.Necromancer_CorpseTower_MaxCount = function(slv)
    return 1
  end
  -- クリエイトショゴスの召喚物を判定する
  members.Necromancer_CreateShoggoth = function(name)
    return name == 'pcskill_shogogoth'
  end
  members.Necromancer_CreateShoggoth_MaxCount = function(slv)
    return 1
  end

  -- ******************************************** --
  -- ***               ソーサラー             *** --
  -- ******************************************** --

  -- サモニングの召喚物を判定する
  members.Sorcerer_Summoning = function(name)
    return name == '??'
  end
  members.Sorcerer_Summoning_MaxCount = function(slv)
    return 1
  end

  -- サモニングの召喚物を判定する
  members.Sorcerer_SummonSalamion = function(name)
    return name == 'Saloon'
  end
  members.Sorcerer_SummonSalamion_MaxCount = function(slv)
    return 1
  end

  -- サモニングの召喚物を判定する
  members.Sorcerer_SummonServant = function(name)
    return name == 'russianblue'
  end
  members.Sorcerer_SummonServant_MaxCount = function(slv)
    return 1
  end

  -- ******************************************** --
  -- ***             フェザーフット           *** --
  -- ******************************************** --

  -- ボーンポインティングの召喚物を判定する
  members.Featherfoot_BonePointing = function(name)
    return name == 'pcskill_bone'
  end
  members.Featherfoot_BonePointing_MaxCount = function(slv)
    return 1
  end

  -- ******************************************** --
  -- ***                 陰陽師               *** --
  -- ******************************************** --

  -- 狐火式神の召喚物を判定する
  members.Onmyoji_FireFoxShikigami = function(name)
    return
         name == 'pcskill_FireFoxShikigami'
      or name == 'pcskill_Big_FireFoxShikigami'
  end
  members.Onmyoji_FireFoxShikigami_MaxCount = function(slv)
    return 1
  end

  -- ******************************************** --
  -- ***             ティルドルビー           *** --
  -- ******************************************** --

  -- ジェミナ像の召喚物を判定する
  members.Dievdirbys_CarveZemina = function(name)
    return name == 'pcskill_wood_zemina2'
  end
  members.Dievdirbys_CarveZemina_MaxCount = function(slv)
    return 1
  end

  -- ライマ像の召喚物を判定する
  members.Dievdirbys_CarveLaima = function(name)
    return name == 'pcskill_wood_laima2'
  end
  members.Dievdirbys_CarveLaima_MaxCount = function(slv)
    return 1
  end

  -- フクロウの彫像の召喚物を判定する
  members.Dievdirbys_CarveOwl = function(name)
    return name == 'pcskill_wood_owl2'
  end
  members.Dievdirbys_CarveOwl_MaxCount = function(slv)
    return 2
  end

  -- 世界樹の彫刻の召喚物を判定する
  members.Dievdirbys_CarveAustrasKoks = function(name)
    return name == 'pcskill_wood_AustrasKoks2'
  end
  members.Dievdirbys_CarveAustrasKoks_MaxCount = function(slv)
    return 1
  end

  -- アウシュリネ女神像の召喚物を判定する
  members.Dievdirbys_CarveAusirine = function(name)
    return name == 'pcskill_wood_ausrine2'
  end
  members.Dievdirbys_CarveAusirine_MaxCount = function(slv)
    return 1
  end

  -- ******************************************** --
  -- ***                ドルイド              *** --
  -- ******************************************** --

  -- カーニヴァリーの召喚物を判定する
  members.Druid_Carnivory = function(name)
    return name == 'pcskill_Corpse_Flower_green'
  end
  members.Druid_Carnivory_MaxCount = function(slv)
    return math.ceil(1 + ((slv * 1) / 2))
  end

  -- === クラス別召喚物の定義はここまで === --

  -- デフォルトのオーナーハンドルを取得する
  members.Common_MySession = function()
    return session.GetMyHandle()
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
        return 0
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
      elseif (config.mode == 'party') then
        modeLogic = ModeParty()
      end

      -- 実行する
      if (modeLogic ~= nil) then
        modeLogic.Key = key
        modeLogic.Handles = value
        modeLogic:Execute(frame, config, self.skillConfig[key])
      end

      -- トークモード判定
      if (config.talk) then
        local talk = ModeTalk()
        talk.Handles = value
        talk:Execute(__ADDON_DIR, config.talk)
      end
    end

    return 1
  end

  members.ResetHandle = function(self, findfn)
    self.Handles = {}
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

  -- シリアライズ(スキル別)
  members.Serialize = function(self, key, x, y)
    local f, e = io.open(string.format('%s/%s', __ADDON_DIR, key..'.txt'), 'w')
    if (e) then
      self:Err(tostring(e))
      return
    end
    f:write('local s = {}\n')
    f:write(string.format('s[\'%s\'] = {', 'loc_frame'))
    f:write(string.format(' x = %d, y = %d', x, y))
    f:write('}\n')
    f:write('return s')
    f:flush()
    f:close()
    -- 即座に復元
    self.skillConfig[key] = self:Deserialize(key..'.txt')
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

-- 自フレーム初期化処理
function SUMMONCOUNTER_ON_INIT(addon, frame)
  addon:RegisterMsg('GAME_START_3SEC', 'SUMMONCOUNTER_REFRESH_KICKER')
  -- addon:RegisterMsg('GAME_START_3SEC', 'SUMMONCOUNTER_LOAD_AT_ONCE')
end

-- 設定ファイル読み込み
function SUMMONCOUNTER_LOAD_AT_ONCE()
  suco:LoadSettings()
  suco:LoadPositions()
end

function SUMMONCOUNTER_REFRESH_KICKER()
  suco:ResetHandle()
  SUMMONCOUNTER_LOAD_AT_ONCE()
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
      if (skill ~= nil) then
        local obj = GetIES(skill:GetObject())
        suco:Start(slot, obj.Level, obj.ClassName)
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
  if (tonumber(maxsummons) > 1) then
    local counter = slot:CreateOrGetControl('richtext', 'summon_count', 0, 0, 20, 10)
    tolua.cast(counter, 'ui::CRichText')
    counter:SetText('{ol}{s14}'..summons..'/'..maxsummons)
    counter:SetOffset(slot:GetWidth() - counter:GetWidth(), 0)
  end

  return suco:Show()
end

function SUMMONCOUNTER_ON_END_DRAG(frame, str, num)
  suco:Serialize(str, frame:GetX(), frame:GetY())
end

function SUMMONCOUNTER_ON_RBUTTONUP(frame)
  SUMMONCOUNTER_LOAD_AT_ONCE()
  suco:Log('Settings reloaded.')
end

-- インスタンス作成
if (suco ~= nil) then
  suco:Destroy()
end
suco = g()
