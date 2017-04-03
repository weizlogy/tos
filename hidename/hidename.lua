-- class definitions.
HideName = {}

-- constructor.
function HideName.new(self)
  -- initialize members.
  local members = {};
  -- hide name.
  members.Hide = function(self)
    -- invisible name at head.
    local headsup = ui.GetFrame("headsupdisplay");
    local headsupName = GET_CHILD(headsup, "name_text", "ui::CRichText");
    headsupName:SetText("");
    -- invisible name below a character.
    local my = ui.GetFrame("charbaseinfo1_my");
    local givenName = GET_CHILD(my, "givenName", "ui::CRichText");
    givenName:SetText("");
    local familyName = GET_CHILD(my, "familyName", "ui::CRichText");
    familyName:SetText("");
    local name = GET_CHILD(my, "name", "ui::CRichText");
    name:SetText("");
  end
  -- destroy.
  members.Destroy = function(self)
    HEADSUPDISPLAY_ON_MSG = hina.HEADSUPDISPLAY_ON_MSG;
    hina.HEADSUPDISPLAY_ON_MSG = nil;
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(HideName, {__call = HideName.new});

-- frame initialize.
function HIDENAME_ON_INIT(addon, frame)
  if (hina.HEADSUPDISPLAY_ON_MSG == nil) then
    hina.HEADSUPDISPLAY_ON_MSG = HEADSUPDISPLAY_ON_MSG;
  end
  HEADSUPDISPLAY_ON_MSG = function(frame, msg, argStr, argNum)
    hina.HEADSUPDISPLAY_ON_MSG(frame, msg, argStr, argNum);
    hina:Hide();
  end
  addon:RegisterMsg("GAME_START_3SEC", "HIDENAME_GAME_START_3SEC");
end

function HIDENAME_GAME_START_3SEC(frame)
  local my = ui.GetFrame("charbaseinfo1_my");
  my:SetOpenScript("HIDENAME_CHARBASEINFO1_MY_OPEN");
  hina:Hide();
end

-- charbaseinfo1_my open script.
function HIDENAME_CHARBASEINFO1_MY_OPEN()
  hina:Hide();
end

-- create instance.
if (hina ~= nil) then
  hina:Destroy();
end
hina = HideName();

