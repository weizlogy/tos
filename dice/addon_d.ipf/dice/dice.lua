Dice = {};

-- constructor.
function Dice.new(self)
  -- initialize members.
  local members = {};
  members.min = 0;
  members.max = 999;

  -- throw dice.
  members.Throw = function(self)
    local server = GetServerNation();
    local name = GETMYFAMILYNAME();
    local dice = IMCRandom(self.min, self.max);
    if (server ~= "JP") then
      return string.format("Dice(%d-%d)!%s got %d on it!", self.min, self.max, name, dice);
    end
    return string.format("ダイス(%d-%d)！%sは、%dを出した！", self.min, self.max, name, dice);
  end

  members.ChangeRange = function(self, min, max)
    if (min == nil) then
      min = 0;
    end
    if (max == nil) then
      max = 999;
    end
    self.min = min;
    self.max = max;
    CHAT_SYSTEM(string.format("[dice] set dice range %d - %d", min, max));
  end

  -- destroy.
  members.Destroy = function(self)
    if (dice.UI_CHAT ~= nil) then
      UI_CHAT = dice.UI_CHAT;
      dice.UI_CHAT = nil
    end
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(Dice, {__call = Dice.new});

-- frame initialize.
function DICE_ON_INIT(addon, frame)
  if (dice.UI_CHAT == nil) then
    dice.UI_CHAT = UI_CHAT;
  end
  UI_CHAT = function(msg)
    if (msg == "/random") then
      msg = dice:Throw();
    elseif (string.find(msg, "/random set", 1, true) == 1) then
      local min, max = string.match(msg, "^/random set (%d+) (%d+)$");
      dice:ChangeRange(min, max);
    end
    dice.UI_CHAT(msg);
  end
end

-- create instance.
if (dice ~= nil) then
  dice:Destroy();
end
dice = Dice();
