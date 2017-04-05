-- class definitions.
WorldmapQuest = {};

-- constructor.
function WorldmapQuest.new(self)
  -- initialize members.
  local members = {};
  members.possibleQuests = {};
  --
  members.CreatePossibleQuests = function(self)
    self.possibleQuests = {}
    local possibleQuestList = GetQuestProgressClassByState("POSSIBLE");
    for i = 1, #possibleQuestList do
      local questIES = possibleQuestList[i];
      if (questIES.StartMap ~= "None") then
        local mapCls = GetClass('Map', questIES.StartMap);
        local count = self.possibleQuests[mapCls.ClassID];
        if (count == nil) then
          count = 0;
        end
        self.possibleQuests[mapCls.ClassID] = count + 1;
      end
    end
  end
  --
  members.InsertPossibleQuestCount = function(self, mapCls, textObj)
    local value = textObj:GetTextByKey("value");
    local count = self.possibleQuests[mapCls.ClassID];
    if (count == nil) then
      return;
    end
    textObj:SetTextByKey(
      "value", string.format("{@st66e}[%d]", count).."{nl}"..value);
  end
  -- destroy.
  members.Destroy = function(self)
    CREATE_WORLDMAP_MAP_CONTROLS = woqu.CREATE_WORLDMAP_MAP_CONTROLS;
    woqu.CREATE_WORLDMAP_MAP_CONTROLS = nil;
    OPEN_WORLDMAP = woqu.OPEN_WORLDMAP;
    woqu.OPEN_WORLDMAP = nil;
  end
  return setmetatable(members, {__index = self});
end

-- set call.
setmetatable(WorldmapQuest, {__call = WorldmapQuest.new});

-- frame initialize.
function WORLDMAPQUEST_ON_INIT(addon, frame)
  -- override worldmap init function.
  if (woqu.OPEN_WORLDMAP == nil) then
    woqu.OPEN_WORLDMAP = OPEN_WORLDMAP;
  end
  OPEN_WORLDMAP = function(addon, frame)
    woqu:CreatePossibleQuests();
    woqu.OPEN_WORLDMAP(addon, frame);
  end
  -- override create worldmap map control function.
  if (woqu.CREATE_WORLDMAP_MAP_CONTROLS == nil) then
    woqu.CREATE_WORLDMAP_MAP_CONTROLS = CREATE_WORLDMAP_MAP_CONTROLS;
  end
  CREATE_WORLDMAP_MAP_CONTROLS = function(
      parentGBox, makeWorldMapImage, changeDirection, nowMapIES, 
      mapCls, questPossible, nowMapWorldPos, gBoxName, 
      x, spaceX, startX, y, spaceY, startY, pictureStartY)
    -- call original.
    woqu.CREATE_WORLDMAP_MAP_CONTROLS(
      parentGBox, makeWorldMapImage, changeDirection, nowMapIES, 
      mapCls, questPossible, nowMapWorldPos, gBoxName, 
      x, spaceX, startX, y, spaceY, startY, pictureStartY);
    -- create params.
    local gbox = GET_CHILD(parentGBox, gBoxName, "ui::CGroupBox");
    local ctrlSet = GET_CHILD(
      gbox, "ZONE_CTRL_" .. mapCls.ClassID, "ui::CControlSet");
    local text = ctrlSet:GetChild("text");
    -- call interrupt function.
    woqu:InsertPossibleQuestCount(mapCls, text);
  end
end

-- create instance.
if (woqu ~= nil) then
  woqu:Destroy();
end
woqu = WorldmapQuest();
