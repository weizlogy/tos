SummonCounter = {};

-- constructor.
function SummonCounter.new(self)
  -- initialize members.
  local members = {};
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

  -- destroy.
  members.Destroy = function(self)
  end
  return setmetatable(members, {__index = self});
end

-- set call.
setmetatable(SummonCounter, {__call = SummonCounter.new});

-- frame initialize.
function SUMMONCOUNTER_ON_INIT(addon, frame)
  addon:RegisterMsg('GAME_START_3SEC', 'SUMMONCOUNTER_REFRESH');
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
      end
    end
  end
end

--
function SUMMONCOUNTER_UPDATE(slot)
  local findfunc = slot:GetUserValue("SUMMONCOUNTER_FINDFUNCTION");
  local findhfunc = slot:GetUserValue("SUMMONCOUNTER_FINDHANDLEFUNCTION");
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
    end
  end
  local maxsummons = slot:GetUserValue("SUMMONCOUNTER_MAXCOUNT");
  local counter = slot:CreateOrGetControl('richtext', "summon_count", 0, 0, 20, 10);
  tolua.cast(counter, "ui::CRichText");
  counter:SetText("{ol}{s14}"..summons.."/"..maxsummons);
  counter:SetOffset(slot:GetWidth() - counter:GetWidth(), 0);
  return 1;
end

--
if (suco ~= nil) then
  suco:Destroy();
end
-- create instance.
suco = SummonCounter();
