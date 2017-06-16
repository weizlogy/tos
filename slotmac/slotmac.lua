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
    local cmds = {
      act = function() end
    };
    -- extract emoticon.
    local extra = string.gsub(input, "<(emoticon\_.-)>", "{img %1 0 0}{/}");
    if (input ~= extra) then
      --CHAT_SYSTEM("extracted => ".."["..extra.."]")
      input = extra;
    end
    -- chat alias.
    if (string.find(input, "/", 1, true) == 1) then
      cmds.act = function(frame, slot, argStr, argNum)
        local temp = string.gsub(input, "^\/s ", "");  -- for normal chat.
        ui.Chat(temp);
      end
      return cmds;
    end
    -- custom commands.
    local id, cc = string.match(input, "^#(.-)# (.+)");
    cmds.id = id;
    cmds.cc = cc;
    --CHAT_SYSTEM(id.." - "..cc);
    -- slot skill.
    if (id == "skill") then
      cmds.act = function(frame, slot, argStr, argNum)
        if (cmds.cc ~= "0") then
          -- use other slot skill.
          local frame = ui.GetFrame('quickslotnexpbar');
		      slot = GET_CHILD_RECURSIVELY(frame, "slot"..cmds.cc, "ui::CSlot");
        end
        slmc.QUICKSLOTNEXPBAR_SLOT_USE(frame, slot, argStr, argNum);
      end
      return cmds;
    end
    -- system msg.
    if (id == "system") then
      cmds.act = function(frame, slot, argStr, argNum)
        CHAT_SYSTEM(cmds.cc);
      end
      return cmds;
    end
    -- pose.
    if (id == "pose") then
      cmds.act = function(frame, slot, argStr, argNum)
        control.Pose(cmds.cc);
      end
      return cmds;
    end
    -- timer.
    if (id == "timer") then
      cmds.act = function(frame, slot, argStr, argNum)
        local time, timedcmd = string.match(cmds.cc, "^(%d+) (.+)$");
        timedcmd = self:AnalyzeMacro(timedcmd);
        local timeHandleName = "SLOTMAC_TIMER_"..IMCRandom(1, 100000);
        _G[timeHandleName] = function()
          timedcmd.act(frame, slot, argStr, argNum);
          _G[timeHandleName] = nil;
        end
        DebounceScript(timeHandleName, time);
      end
      return cmds;
    end
    return cmds;
  end

  -- load macro from file.
  members.UseMacro = function(self, frame, slot, argStr, argNum)
    local name = slot:GetName();
    --CHAT_SYSTEM(name);
    local macro = SlotMac.List[name];
    if (macro == nil) then
      slmc.QUICKSLOTNEXPBAR_SLOT_USE(frame, slot, argStr, argNum);
      return;
    end
    for i, m in ipairs(macro) do
      m.act(frame, slot, argStr, argNum);
    end
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
  SLOTMAC_RELOAD();
end

function SLOTMAC_RELOAD(parent, sender, argStr, argNum)
  local frame = ui.GetFrame('quickslotnexpbar');
  for i = 0, MAX_QUICKSLOT_CNT - 1 do
		local slot = GET_CHILD_RECURSIVELY(frame, "slot"..(i + 1), "ui::CSlot");
    slmc:LoadMacro(slot:GetName());
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
