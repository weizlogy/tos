SummonCounter = {};

-- constructor.
function SummonCounter.new(self)
  -- initialize members.
  local members = {};

  -- for ui.
  members.Handles = {};

  -- for save location.
  members.x = -1;
  members.y = -1;
  members.w = -1;
  members.h = -1;
  members.path = "../addons/summoncounter";

  -- start summons watcher.
  members.Start = function(self, slot, maxCount, findfn, findhfn)
    if (findhfn == nil) then
      findhfn = "Common_MySession"
    end
    slot:SetUserValue("SUMMONCOUNTER_MAXCOUNT", maxCount);
    slot:SetUserValue("SUMMONCOUNTER_FINDFUNCTION", findfn);
    slot:SetUserValue("SUMMONCOUNTER_FINDHANDLEFUNCTION", findhfn);
    slot:RunUpdateScript("SUMMONCOUNTER_UPDATE", 0, 0, 0, 1)
  end

  members.LoadSettings = function(self)
    dofile(self.path.."/settings.txt");
  end

  members.LoadPositions = function(self)
    local bufferW = 90;
    local bufferH = 250;
    local frame = ui.GetFrame("charbaseinfo1_my");
    self.x = frame:GetX() + bufferW / 2;
    self.y = frame:GetY() - bufferH;
    self.w = frame:GetWidth() - bufferW;
    self.h = frame:GetHeight() + bufferH;
  end

  -- check logic for bokor.
  members.Bokor_Zombify = function(name)
    return
         name == "summons_zombie"
      or name == "Zombie_Overwatcher"
      or name == "Zombie_hoplite";
  end
  -- check logic for necro.
  members.Necromancer_RaiseDead = function(name)
    return name == "pcskill_skullsoldier";
  end
  -- check logic for necro.
  members.Necromancer_RaiseSkullarcher = function(name)
    return name == "pcskill_skullarcher";
  end
  -- check logic for necro.
  members.Necromancer_CorpseTower = function(name)
    return name == "pcskill_skullsoldier";
  end
  -- check logic for necro.
  members.Necromancer_CreateShoggoth = function(name)
    return name == "pcskill_shogogoth";
  end

  -- logic for owner handle.
  members.Common_MySession = function()
    return session.GetMyHandle();
  end
  -- logic for owner handle.
  members.Necromancer_CorpseTower_FindHandle = function()
    local handle = -1;
    local list, count = SelectBaseObject(GetMyPCObject(), 500, "ALL");
    for i = 1 , count do
      local obj = list[i];
      local iesObj = GetBaseObjectIES(obj);
      if (iesObj.ClassName == "pcskill_CorpseTower") then
        local actor = tolua.cast(obj, "CFSMActor");
        handle = actor:GetHandleVal();
        break;
      end
    end
    return handle;
  end

  -- show ui v2.
  members.Show = function(self)
    -- create canvas.
    local frame = ui.GetFrame("summoncounter");
    frame:SetSkinName("downbox");
    frame:SetAlpha(0);
    frame:Resize(suco.w, suco.h);
    frame:SetOffset(suco.x, suco.y);
    frame:ShowWindow(1);
    frame:EnableMove(0);
    frame:EnableHittestFrame(0);

    for key, value in pairs(self.Handles) do
      -- check config.
      local config = suco.config[key];
      if (config == nil) then
        CHAT_SYSTEM("[summoncounter] something wrong at config file with key="..key);
        return;
      end

      DESTROY_CHILD_BYNAME(frame, "vw_"..key.."_");

      local modeLogic = nil;
      if (config.mode == "hpbar") then
        modeLogic = ModeHPBar();
      elseif (config.mode == "icon1") then
        modeLogic = ModeIcon1();
      elseif (config.mode == "icon2") then
        modeLogic = ModeIcon2();
      end

      modeLogic.Key = key;
      modeLogic.Handles = value;
      modeLogic:Execute(frame, config);
    end
  end

  members.ClearHandle = function(self, findfn)
    self.Handles[findfn] = {};
  end

  -- put handle to member.
  members.PutHandle = function(self, handle, findfn)
    table.insert(self.Handles[findfn], handle);
  end

  -- destroy.
  members.Destroy = function(self)
    --UI_CHAT = suco.UI_CHAT;
  end
  return setmetatable(members, {__index = self});
end

-- set call.
setmetatable(SummonCounter, {__call = SummonCounter.new});

-- frame initialize.
function SUMMONCOUNTER_ON_INIT(addon, frame)
  addon:RegisterMsg('GAME_START_3SEC', 'SUMMONCOUNTER_REFRESH');
  addon:RegisterMsg('GAME_START_3SEC', 'SUMMONCOUNTER_LOAD_AT_ONCE');

  if (suco.UI_CHAT == nil) then
    suco.UI_CHAT = UI_CHAT;
  end
  UI_CHAT = function(msg)
    if (msg == "/summonc reload") then
      suco:LoadSettings();
      CHAT_SYSTEM("[summoncounter] settings reloaded.");
    end
    suco.UI_CHAT(msg);
  end
end

function SUMMONCOUNTER_LOAD_AT_ONCE()
  suco:LoadSettings();
  suco:LoadPositions();
end

--
function SUMMONCOUNTER_REFRESH()
  local pc = GetMyPCObject();
  local frame = ui.GetFrame('quickslotnexpbar');
  local quickSlotList = session.GetQuickSlotList();
  for i = 0, MAX_QUICKSLOT_CNT - 1 do
    local quickSlotInfo = quickSlotList:Element(i);		
    if (quickSlotInfo.category == 'Skill') then
      local slot = GET_CHILD_RECURSIVELY(frame, "slot"..(i + 1), "ui::CSlot");
      local skill = session.GetSkill(quickSlotInfo.type);
      local obj = GetIES(skill:GetObject());
      if (obj.ClassName == "Bokor_Zombify") then
        suco:Start(slot, obj.Level + 4, obj.ClassName);
      elseif (obj.ClassName == "Necromancer_RaiseDead") then
        suco:Start(slot, obj.Level, obj.ClassName);
      elseif (obj.ClassName == "Necromancer_RaiseSkullarcher") then
        suco:Start(slot, obj.Level, obj.ClassName);
      elseif (obj.ClassName == "Necromancer_CorpseTower") then
        -- suco:Start(slot, obj.Level, obj.ClassName, obj.ClassName.."_FindHandle");
      elseif (obj.ClassName == "Necromancer_CreateShoggoth") then
        suco:Start(slot, 1, obj.ClassName);
      end
    end
  end
end

--
function SUMMONCOUNTER_UPDATE(slot)
  local findfunc = slot:GetUserValue("SUMMONCOUNTER_FINDFUNCTION");
  local findhfunc = slot:GetUserValue("SUMMONCOUNTER_FINDHANDLEFUNCTION");

  suco:ClearHandle(findfunc);

  local summons = 0;
  local list, count = SelectBaseObject(GetMyPCObject(), 500, "ALL");
  for i = 1 , count do
    local obj = list[i];
    local iesObj = GetBaseObjectIES(obj);
    local actor = tolua.cast(obj, "CFSMActor");
    local handle = actor:GetHandleVal();
    local ownerHandle = info.GetOwner(handle);
    if (ownerHandle == suco[findhfunc]() and suco[findfunc](iesObj.ClassName)) then
      summons = summons + 1;
      suco:PutHandle(handle, findfunc);
    end
  end
  local maxsummons = slot:GetUserValue("SUMMONCOUNTER_MAXCOUNT");
  local counter = slot:CreateOrGetControl('richtext', "summon_count", 0, 0, 20, 10);
  tolua.cast(counter, "ui::CRichText");
  counter:SetText("{ol}{s14}"..summons.."/"..maxsummons);
  counter:SetOffset(slot:GetWidth() - counter:GetWidth(), 0);

  suco:Show();
  return 1;
end

--
if (suco ~= nil) then
  suco:Destroy();
end
-- create instance.
suco = SummonCounter();


-- sub classes.
-- mode hpbar for zombie.
ModeHPBar = {};
function ModeHPBar.new(self)
  -- initialize members.
  local members = {};

  members.Key = "";
  members.Handles = {};

  members.Execute = function(self, frame, config)
    local totalHP, totalMHP = self:CalculateHP();
    if (totalHP <= 0) then
      DESTROY_CHILD_BYNAME(frame, "summonsHPGauge_"..self.Key);
      DESTROY_CHILD_BYNAME(frame, "summonsHPGaugeName_"..self.Key);
      return;
    end

    local locframe = config["loc_frame"];
    frame:SetOffset(locframe.x, locframe.y);

    local locbar = config["loc_bar"];

    local summonsHPGauge = frame:CreateOrGetControl(
      "gauge", "summonsHPGauge_"..self.Key, 0, 0, 188 - 10, 0);
    tolua.cast(summonsHPGauge, "ui::CGauge");
    summonsHPGauge:SetMargin(20, 20, 20, 20);
    summonsHPGauge:Resize(summonsHPGauge:GetWidth(), 30);
    summonsHPGauge:SetOffset(locbar.x, locbar.y);
    summonsHPGauge:SetPoint(totalHP, totalMHP);

    summonsHPGauge:SetSkinName("necronomicon_amount");
    summonsHPGauge:SetColorTone("FFCCCCCC");

    if summonsHPGauge:GetStat() == 0 then
      summonsHPGauge:AddStat("%v / %m");
      summonsHPGauge:SetStatFont(0, 'white_14_ol');
      summonsHPGauge:SetStatOffset(0, 0, -3);
      summonsHPGauge:SetStatAlign(0, 'center', 'center');
    end

    summonsHPGauge:EnableHitTest(0);
    summonsHPGauge:ShowWindow(1);
    frame:ShowWindow(1);
  end

  -- calc total hp and mhp.
  members.CalculateHP = function(self)
    local totalHP = 0;
    local totalMHP = 0;
    for i, handle in ipairs(self.Handles) do
      local stat = info.GetStat(handle);
        totalHP = totalHP + stat.HP;
        totalMHP = totalMHP + stat.maxHP;
    end
    -- for create empty gauge.
    if (totalMHP == 0) then
      totalHP = -1;
      totalMHP = 1;
    end
    return totalHP, totalMHP;
  end

  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(ModeHPBar, {__call = ModeHPBar.new});

-- mode icon1 for skulls.
ModeIcon1 = {};
function ModeIcon1.new(self)
  -- initialize members.
  local members = {};
  
  members.Key = "";
  members.Handles = {};

  members.Execute = function(self ,frame, config)
    -- loop handle unit by skill.
    for i, handle in ipairs(self.Handles) do
      self:CreateSummonIcon(frame, handle, config, i);
    end
  end

  members.CreateSummonIcon = function(self, frame, handle, config, index)
    local iconName = "vw_"..self.Key.."_"..handle;

    local iconSize = 35;
    local iconPos = config.loc;
    local iconXBase = 0;

    if (iconPos == "left") then
      iconXBase = 3;
    elseif (iconPos == "right") then
      iconXBase = 1.6;
    end

    local pic = frame:CreateOrGetControl('picture', iconName, 0, 0, iconSize, iconSize);
    tolua.cast(pic, "ui::CPicture");

    local loc = config["loc"..index];
    local x = frame:GetWidth() / iconXBase + loc.x;
    local y = 90 + loc.y;

    pic:SetImage("summoncounter_necro_skull");
    pic:SetEnableStretch(1);
    pic:SetOffset(x, y);
    pic:EnableHitTest(0);
  end

  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(ModeIcon1, {__call = ModeIcon1.new});

-- mode icon2 for shogoth.
ModeIcon2 = {};
function ModeIcon2.new(self)
  -- initialize members.
  local members = {};
  
  members.Key = "";
  members.Handles = {};

  members.Execute = function(self, frame, config)
    -- loop handle unit by skill.
    for i, handle in ipairs(self.Handles) do
      self:CreateSummonIcon(frame, handle, config, i);
    end
  end

  members.CreateSummonIcon = function(self, frame, handle, config, index)
    local iconName = "vw_"..self.Key.."_"..handle;

    local iconSize = 60;
    local iconPos = config.loc;
    local iconYBase = 0;
    local iconCenterMarginX = -27;

    if (iconPos == "up") then
      iconYBase = 0.4;
    elseif (iconPos == "down") then
      iconYBase = 3.6;
    end

    local pic = frame:CreateOrGetControl('picture', iconName, 0, 0, iconSize, iconSize);
    tolua.cast(pic, "ui::CPicture");

    local loc = config["loc"..index];
    local x = (frame:GetWidth() / 2) + loc.x + iconCenterMarginX;
    local y = (90 + loc.y) * iconYBase;

    pic:SetImage("summoncounter_necro_circle");
    pic:SetEnableStretch(1);
    pic:SetOffset(x, y);
    pic:EnableHitTest(0);
  end

  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(ModeIcon2, {__call = ModeIcon2.new});
