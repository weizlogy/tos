SlotMac = {};
SlotMac.List = {};

-- constructor.
function SlotMac.new(self)
  -- initialize members.
  local members = {};
  members.path = "../addons/slotmac";

  -- load macro from file.
  members.LoadMacro = function(self, name)
    -- load from file.
    local cid = info.GetCID(session.GetMyHandle());
    local f, e = io.open(string.format("%s/%s/%s.txt", self.path, cid, name), "r");
    if (f == nil) then
      return;
    end
    -- save macro.
    local macro = {};
    for s in f:lines() do
      --CHAT_SYSTEM("["..s.."]")
      local cmds = self:AnalyzeMacro(s);
      table.insert(macro, cmds);  -- for i, m in ipairs(macro) do
    end
    SlotMac.List[name] = macro;
    f:close();
  end

  -- analyze, too long code...
  members.AnalyzeMacro = function(self, input)
    local cmds = MacroCommand();
    cmds.act = cmds.NoOp;
    -- extract emoticon.
    -- <emoticon_nnnn>
    local extra = string.gsub(input, "<(emoticon\_.-)>", "{img %1 0 0}{/}");
    if (input ~= extra) then
      --CHAT_SYSTEM("extracted => ".."["..extra.."]")
      input = extra;
    end
    -- chat alias.
    -- /xxx
    if (string.find(input, "/", 1, true) == 1) then
      cmds.cc = input;
      cmds.act = cmds.ChatAlias;
      return cmds;
    end
    -- analyze custom commands.
    local id, cc = string.match(input, "^#(.-)# (.+)");
    cmds.id = id;
    cmds.cc = cc;
    --CHAT_SYSTEM(id.." - "..cc);

    -- slot skill.
    -- #skill# nnn
    if (id == "skill") then
      cmds.act = cmds.Skill;
      return cmds;
    end
    -- system msg.
    -- #system# xxx
    if (id == "system") then
      cmds.act = cmds.System;
      return cmds;
    end
    -- pose.
    -- #pose# xxx
    if (id == "pose") then
      cmds.act = cmds.Pose;
      return cmds;
    end
    -- timer.
    -- #timer# nnn xxx
    if (id == "timer") then
      local time, timedcmd = string.match(cmds.cc, "^(%d+) (.+)$");
      timedcmd = self:AnalyzeMacro(timedcmd);
      cmds.cc = timedcmd;
      cmds.dd = time;
      cmds.act = cmds.Timer;
      return cmds;
    end
    -- equip.
    -- #equip# xxx yyy
    if (id == "equip") then
      -- convert item name to className.
      local tempSlotName, tempItemName = string.match(cmds.cc, "^(.-) (.-)$");
      tempItemName = string.lower(tempItemName);
      local converted = 0;
      -- from equiping.
      local equiplist = session.GetEquipItemList();
      for i = 0, equiplist:Count() - 1 do
        local equipItem = equiplist:Element(i);
        local itemCls = GetIES(equipItem:GetObject());
        --CHAT_SYSTEM(item.GetEquipSpotName(equipItem.equipSpot).." - "..itemCls.ClassName);
        local name = string.lower(dictionary.ReplaceDicIDInCompStr(itemCls.Name));		
        local index = string.find(name, tempItemName);
        if (index == 1) then
          cmds.cc = tempSlotName.." "..itemCls.ClassName;
          converted = 1;
        end
      end
      -- from inventory.
      if (converted == 0) then
        session.BuildInvItemSortedList();
        local sortedList = session.GetInvItemSortedList();
        for i = 0, sortedList:size() - 1 do
          local invItem = sortedList:at(i);
          local itemCls = GetIES(invItem:GetObject());	
          if (itemCls.ItemType == "Equip") then
            local name = string.lower(dictionary.ReplaceDicIDInCompStr(itemCls.Name));		
            local index = string.find(name, tempItemName);
            if (index == 1) then
              cmds.cc = tempSlotName.." "..itemCls.ClassName;
              converted = 1;
            end
          end
        end
      end
      if (converted == 0) then
        CHAT_SYSTEM(string.format("[slotmac] equip item [%s] is not found.", tempItemName));
        return cmds;
      end
      cmds.act = cmds.Equip;
      return cmds;
    end
    -- unequip.
    -- #unequip# xxx
    if (id == "unequip") then
      cmds.act = cmds.UnEquip;
      return cmds;
    end

    -- chaim.

    return cmds;
  end

  -- load macro from file.
  members.UseMacro = function(self, frame, slot, argStr, argNum)
    local name = slot:GetName();
    local oh = self:WillSkillOverHeat(slot);
    if (oh ~= 0) then
      name = name.."-oh";
    end
    --CHAT_SYSTEM(name);
    local macro = SlotMac.List[name];
    if (macro == nil) then
      slmc.QUICKSLOTNEXPBAR_SLOT_USE(frame, slot, argStr, argNum);
      return;
    end
    for i, m in ipairs(macro) do
      m.act(m, frame, slot, argStr, argNum);
    end
  end

  members.HasSkillOverHeat = function(self, slot)
    local obj = GET_SLOT_SKILL_OBJ(slot);
    if (obj == nil or obj.OverHeatGroup == "None") then
      return 0;
    end
    return 1;
  end

  members.WillSkillOverHeat = function(self, slot)
    local obj = GET_SLOT_SKILL_OBJ(slot);
    if (obj == nil or obj.OverHeatGroup == "None") then
      return 0;
    end
    local sklType = obj.ClassID;
    local skl = session.GetSkill(sklType);
    skl = GetIES(skl:GetObject());
    local useOverHeat = skl.SklUseOverHeat;
    local curHeat = session.GetSklOverHeat(sklType) + useOverHeat;
	  local maxOverHeat = session.GetSklMaxOverHeat(sklType);
    return maxOverHeat - curHeat;
  end

  members.Destroy = function(self)
    QUICKSLOTNEXPBAR_SLOT_USE = slmc.QUICKSLOTNEXPBAR_SLOT_USE;
    slmc.QUICKSLOTNEXPBAR_SLOT_USE = nil;
    SKILLTREE_OPEN = slmc.SKILLTREE_OPEN;
    slmc.SKILLTREE_OPEN = nil;
  end

  return setmetatable(members, {__index = self});
end

-- set call.
setmetatable(SlotMac, {__call = SlotMac.new});

-- frame initialize.
function SLOTMAC_ON_INIT(addon, frame)
  if (slmc.QUICKSLOTNEXPBAR_SLOT_USE == nil) then
    slmc.QUICKSLOTNEXPBAR_SLOT_USE = QUICKSLOTNEXPBAR_SLOT_USE;
  end
  QUICKSLOTNEXPBAR_SLOT_USE = function(frame, slot, argStr, argNum)
    slmc:UseMacro(frame, slot, argStr, argNum);
  end

  if (slmc.SKILLTREE_OPEN == nil) then
    slmc.SKILLTREE_OPEN = SKILLTREE_OPEN;
  end
  SKILLTREE_OPEN = function(frame)
    slmc.SKILLTREE_OPEN(frame);
    DESTROY_CHILD_BYNAME(frame, "slmcReload");
    local reload = frame:CreateOrGetControl("button", "slmcReload", 0, 600, 60, 40);
    reload:SetGravity(ui.RIGHT, ui.BOTTOM);
    reload:SetMargin(10, 10, 10, 80);
    reload:SetText("[slmc]Reload");
    reload:SetEventScript(ui.LBUTTONUP, "SLOTMAC_RELOAD");
    reload:SetEventScript(ui.RBUTTONUP, "SLOTMAC_CREATEDIR");
    reload:ShowWindow(1);
  end
  addon:RegisterMsg('GAME_START_3SEC', 'SLOTMAC_LOAD');
end

function SLOTMAC_LOAD(frame)
  SLOTMAC_RELOAD(frame, nil, nil, nil);
end

function SLOTMAC_RELOAD(parent, sender, argStr, argNum)
  SlotMac.List = {};
  local frame = ui.GetFrame('quickslotnexpbar');
  for i = 0, MAX_QUICKSLOT_CNT - 1 do
		local slot = GET_CHILD_RECURSIVELY(frame, "slot"..(i + 1), "ui::CSlot");
    slmc:LoadMacro(slot:GetName());
    -- check overheat.
    local oh = slmc:HasSkillOverHeat(slot);
    if (oh == 1) then
      slmc:LoadMacro(slot:GetName().."-oh");
    end
  end
  if (argStr ~= nil) then
    local cid = info.GetCID(session.GetMyHandle());
    CHAT_SYSTEM(string.format("[slotmac] macro reloaded. cid=[%s]", cid));
  end
end

function SLOTMAC_CREATEDIR(parent, sender, argStr, argNum)
  local cid = info.GetCID(session.GetMyHandle());
  local f, e = io.open(string.format("%s/%s", slmc.path, cid), "w");
  f:close();
end

--
if (slmc ~= nil) then
  slmc:Destroy();
end

-- create instance.
slmc = SlotMac();


-- sub classes.
MacroCommand = {}
function MacroCommand.new(self)
  local members = {};
  members.id = "";
  members.cc = "";

  members.NoOp = function(self, frame, slot, argStr, argNum)
  end

  members.Skill = function(self, frame, slot, argStr, argNum)
    if (self.cc ~= "0") then
      -- use other slot skill.
      local frame = ui.GetFrame('quickslotnexpbar');
      slot = GET_CHILD_RECURSIVELY(frame, "slot"..self.cc, "ui::CSlot");
    end
    slmc.QUICKSLOTNEXPBAR_SLOT_USE(frame, slot, argStr, argNum);
  end

  members.ChatAlias = function(self, frame, slot, argStr, argNum)
    local temp = string.gsub(self.cc, "^\/s ", "");  -- for normal chat.
    ui.Chat(temp);
  end

  members.System = function(self, frame, slot, argStr, argNum)
    CHAT_SYSTEM(self.cc);
  end

  members.Pose = function(self, frame, slot, argStr, argNum)
    control.Pose(self.cc);
  end

  members.Timer = function(self, frame, slot, argStr, argNum)
    local timeHandleName = "SLOTMAC_TIMER_"..IMCRandom(1, 100000);
    _G[timeHandleName] = function()
      self.cc.act(self.cc, frame, slot, argStr, argNum);
      _G[timeHandleName] = nil;
    end
    DebounceScript(timeHandleName, self.dd);
  end

  members.Equip = function(self, frame, slot, argStr, argNum)
    local slotName, className = string.match(self.cc, "^(.-) (.-)$");
    local invItem = session.GetInvItemByName(className);
    item.Equip(slotName, invItem.invIndex);
  end

  members.UnEquip = function(self, frame, slot, argStr, argNum)
    item.UnEquip(item.GetEquipSpotNum(self.cc));
  end

  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(MacroCommand, {__call = MacroCommand.new});
