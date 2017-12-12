-- class definitions.
CompactHeadsupDisplay = {}

-- constructor.
function CompactHeadsupDisplay.new(self)
  -- initialize members.
  local members = {};

  members.HideGauge = function(self, frame)
    local stamina = frame:GetChild('sta1')
    stamina:Resize(0, 0)
    local hp = frame:GetChild('hp')
    hp:Resize(0, 0)
    local sp = frame:GetChild('sp')
    sp:Resize(0, 0)
    local myhpspleft = frame:GetChild('myhpspleft')
    myhpspleft:SetAlpha(0)
    local myhpspright = frame:GetChild('myhpspright')
    myhpspright:SetAlpha(0)
    local gaugelight1 = frame:GetChild('gaugelight1')
    gaugelight1:SetAlpha(0)
    local gaugelight2 = frame:GetChild('gaugelight2')
    gaugelight2:SetAlpha(0)
    frame:Resize(100, frame:GetHeight())
  end

  -- destroy.
  members.Destroy = function(self)
    HEADSUPDISPLAY_ON_MSG = chsd.HEADSUPDISPLAY_ON_MSG;
    chsd.HEADSUPDISPLAY_ON_MSG = nil;
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(CompactHeadsupDisplay, {__call = CompactHeadsupDisplay.new});

-- frame initialize.
function COMPACTHEADSUPDISPLAY_ON_INIT(addon, frame)
  if (chsd.HEADSUPDISPLAY_ON_MSG == nil) then
    chsd.HEADSUPDISPLAY_ON_MSG = HEADSUPDISPLAY_ON_MSG;
  end
  HEADSUPDISPLAY_ON_MSG = function(frame, msg, argStr, argNum)
    chsd.HEADSUPDISPLAY_ON_MSG(frame, msg, argStr, argNum);
    chsd:HideGauge(frame);
  end
end

-- create instance.
if (chsd ~= nil) then
  chsd:Destroy();
end
chsd = CompactHeadsupDisplay();

