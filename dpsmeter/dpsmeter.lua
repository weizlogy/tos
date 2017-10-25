DPSMeter = {};
DPSMeter.Scores = {};
DPSMeter.IsLock = 0;
DPSMeter.IgnoreChat = 1;

-- constructor.
function DPSMeter.new(self)
  -- initialize members.
  local members = {};
  -- dps caclulate values.
  members.timeBased = 0;
  members.timeElapsed = 0;
  members.hpBased = 0;
  members.hpElapsed = 0;
  members.maxdps = 0;
  members.name = "";
  members.counting = 0;
  members.totaldamage = 0;
  members.beforeHp = 0;
  -- start count.
  members.Start = function(self, handle)
    -- show UI.
    local frameName = "dpsmeter_" .. handle;
    local frame = ui.GetFrame(frameName);
    if (frame == nil) then
      frame = ui.CreateNewFrame("dpsmeter", frameName, 0);
    end
    frame:SetLayerLevel(1);
    frame:Resize(500, 20);
    frame:ShowWindow(1);

    local dpstext = frame:CreateOrGetControl('richtext', "dpstext", 0, 0, frame:GetWidth(), frame:GetHeight());
    dpstext:ShowWindow(0);
    dpstext:EnableHitTest(1);
    dpstext:SetEventScriptArgNumber(ui.RBUTTONUP, handle);
    dpstext:SetEventScript(ui.RBUTTONUP, 'DPSMETER_RBUP_MENU');

    local w, h = 0;
    FRAME_AUTO_POS_TO_OBJ(frame, handle, w, h, 1, 1, 1);
    frame:RunUpdateScript("DPSMETER_UPDATE");
  end
  -- update count.
  members.Update = function(self, frame, handle)
		local stat = info.GetStat(handle);
    -- when first attack, dps count start.
    if (self.counting == 0 and stat.HP == stat.maxHP) then
      return 1;
    end
    if (self.counting == 0) then
      -- first attack = damage / 1sec.
      self.counting = 1;
      self.timeBased = imcTime.GetAppTimeMS() - 1000;
      self.hpBased = stat.maxHP;
      self.name = info.GetName(handle);
      self.beforeHp = stat.maxHP;
    end
    -- calculate dps.
    local dpstext = GET_CHILD(frame, "dpstext", "ui::CRichText");		
    dpstext:ShowWindow(1);
    self.timeElapsed = self.timeElapsed + (imcTime.GetAppTimeMS() - self.timeBased);
    self.hpElapsed = self.hpElapsed + (self.hpBased - stat.HP);
    local dps = self.hpElapsed / (self.timeElapsed / 1000);
    -- save max dps.
    self.maxdps = math.max(self.maxdps, dps);
    -- calculate current average, if hp changed.
    if (self.beforeHp ~= stat.HP) then
      self.counting = self.counting + 1;
      self.totaldamage = self.totaldamage + dps;
      self.beforeHp = stat.HP;
    end
    local average = self.totaldamage / self.counting;
    -- show dps.
    --dpstext:SetColorTone("FFFFFFFF");
    dpstext:SetText(string.format("{ol}%.2f[{#99ffff}%.2f][{#ff9999}%.2f] dps", dps, average, self.maxdps));
    -- target dead -> show max dps to chat.
    local isDead = world.GetActor(handle):IsDead();
    if (isDead == 1) then
      if (DPSMeter.IgnoreChat == 0) then
        CHAT_SYSTEM(string.format(
          "[dpsmeter] max %5.2f, average %5.2f dps - %s", self.maxdps, average, self.name));
      end
      --ui.DestroyFrame(frame:GetName());
      local score = DPSMeter.Scores[handle];
      DPSMeter.Scores[handle] = nil;
      return 0;
    end
    return 1;
  end
  members.toggleChat = function(self, handle)

  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(DPSMeter, {__call = DPSMeter.new});

-- frame initialize.
function DPSMETER_ON_INIT(addon, frame)
  DPSMeter.IsLock = 1;
  -- register handlers.
  addon:RegisterMsg('MAP_CHARACTER_UPDATE', 'DPSMETER_START');
  addon:RegisterMsg('FPS_UPDATE', 'DPSMETER_START');

  if (DPSMeter.UI_CHAT == nil) then
    DPSMeter.UI_CHAT = UI_CHAT;
  end
  UI_CHAT = function(msg)
    if (msg == "/dpsm on") then
      DPSMeter.IsLock = 0;
    elseif (msg == "/dpsm off") then
      DPSMeter.IsLock = 1;
    end
    DPSMeter.UI_CHAT(msg);
  end
end

function DPSMETER_START(frame, msg, str, myhandle)
  if (DPSMeter.IsLock == 1) then
    return;
  end
  DPSMeter.IsLock = 1;
  local list, count = SelectBaseObject(GetMyPCObject(), 500, "ALL");
  for i = 1 , count do
    local obj = list[i];
    local iesObj = GetBaseObjectIES(obj);
    local actor = tolua.cast(obj, "CFSMActor");
    local handle = actor:GetHandleVal();
    -- do nothing for my pc.
    if (myhandle ~= handle) then
      local objType = actor:GetObjType();
      local faction = actor:GetFactionStr();
      if (objType == GT_MONSTER and faction ~= "Pet" and faction ~= "Summon") then
        local score = DPSMeter.Scores[handle];
        if (score == nil) then
          score = DPSMeter();
          DPSMeter.Scores[handle] = score;
        end
        score:Start(handle);
      end
    end
  end
  DPSMeter.IsLock = 0;
end
function DPSMETER_UPDATE(frame)
  local handle = frame:GetUserIValue("_AT_OFFSET_HANDLE");    -- Setting by FRAME_AUTO_POS_TO_OBJ
  local score = DPSMeter.Scores[handle];
  return score:Update(frame, handle);
end
function DPSMETER_RBUP_MENU(frame, ctrl, str, num)
  local handle = num;
  local menuTitle = string.format("[%d] %s", handle, "dpsmeter");
  local context = ui.CreateContextMenu(
    "CONTEXT_DPSMETER", menuTitle, 0, 0, string.len(menuTitle) * 10, 100);
  ui.AddContextMenuItem(context, "toggleChat", string.format("DPSMETER_TOGGLE_CHAT(%d)", handle));	
  ui.AddContextMenuItem(context, "Cancel", "None");
  ui.OpenContextMenu(context);
end
function DPSMETER_TOGGLE_CHAT(handle)
  if (DPSMeter.IgnoreChat == 1) then
    DPSMeter.IgnoreChat = 0;
    return;
  end
  DPSMeter.IgnoreChat = 1;
end
