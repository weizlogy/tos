DPSMeter = {};
DPSMeter.Scores = {};

-- constructor.
function DPSMeter.new(self)
  -- initialize members.
  local members = {};
  members.timeBased = 0;
  members.timeElapsed = 0;
  members.hpBased = 0;
  members.hpElapsed = 0;
  members.name = "";
  -- start count.
  members.Start = function(self, handle)
		local stat = info.GetStat(handle);
    self.timeBased = imcTime.GetAppTimeMS();
    self.hpBased = stat.HP;
    self.name = info.GetName(handle);
  end
  -- stop count.
  members.Stop = function(self, handle)
    if (self.hpElapsed == 0) then
      return;
    end
    local dps = self.hpElapsed / (self.timeElapsed / 1000);
    CHAT_SYSTEM(string.format("%d dps on %s", dps, self.name));
  end
  -- update count.
  members.Update = function(self, handle)
		local stat = info.GetStat(handle);
    self.timeElapsed = self.timeElapsed + (imcTime.GetAppTimeMS() - self.timeBased);
    self.hpElapsed = self.hpElapsed + (self.hpBased - stat.HP);
  end
  -- clear create objects.
  members.Clear = function(self)
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(DPSMeter, {__call = DPSMeter.new});
-- frame initialize.
function DPSMETER_ON_INIT(addon, frame)
  -- for normal monsters.
	addon:RegisterMsg('TARGET_SET', 'DPSMETER_START');
	addon:RegisterMsg('TARGET_CLOSE', 'DPSMETER_STOP');
	addon:RegisterMsg('TARGET_CLEAR', 'DPSMETER_STOP');
	addon:RegisterMsg('TARGET_UPDATE', 'DPSMETER_UPDATE');
  -- for bosses.
	addon:RegisterMsg('TARGET_SET_BOSS', 'DPSMETER_START');
	addon:RegisterMsg('TARGET_CLEAR_BOSS', 'DPSMETER_STOP');
end
function DPSMETER_START(frame, msg, str, num)
  local handle = session.GetTargetHandle();
  local frame = ui.GetFrame("monb_" .. handle);
  if (frame == nil) then
    return;
  end
  local score = DPSMeter.Scores[handle];
  if (score == nil) then
    score = DPSMeter();
    DPSMeter.Scores[handle] = score;
  end
  score:Start(handle);
end
function DPSMETER_STOP(frame, msg, str, handle)
  local score = DPSMeter.Scores[handle];
  score:Stop(handle);
  score:Clear();
  DPSMeter.Scores[handle] = nil;
end
function DPSMETER_UPDATE(frame, msg, str, num)
  local handle = session.GetTargetHandle();
  local score = DPSMeter.Scores[handle];
  score:Update(handle);
end
