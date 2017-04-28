-- class definitions.
WorldmapQuest = {};

-- constructor.
function WorldmapQuest.new(self)
  -- initialize members.
  local members = {};
  members.possibleQuests = {};
  members.IgnoreRepeatQuest = 0;
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
        if (self.IgnoreRepeatQuest == 1 and questIES.QuestMode == "REPEAT") then
          self.possibleQuests[mapCls.ClassID] = count - 1;
        end
      end
    end
  end
  --
  members.InsertPossibleQuestCount = function(self, mapCls, gbox, parentGBox)
    parentGBox:RemoveChild("questText_"..mapCls.ClassID);
    local count = self.possibleQuests[mapCls.ClassID];
    if (count == nil or count <= 0) then
      return;
    end
    local questText = parentGBox:CreateOrGetControl(
      "richtext", "questText_"..mapCls.ClassID, gbox:GetX(), gbox:GetY(), 30, 30);
    questText:SetText(string.format("{@st66e}[%d]", count));
    questText:SetOffset(gbox:GetOffsetX() + (gbox:GetWidth() / 2) - 14, gbox:GetOffsetY() - 20);
    questText:EnableHitTest(1);
    questText:SetEventScript(ui.RBUTTONUP, 'WORLDMAPQUEST_RBUP_MENU');
  end
  --
  members.ToggleRepeatQuest = function(self)
    if (self.IgnoreRepeatQuest == 1) then
      self.IgnoreRepeatQuest = 0;
      return;
    end
    self.IgnoreRepeatQuest = 1;
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
    -- call interrupt function.
    woqu:InsertPossibleQuestCount(mapCls, gbox, parentGBox);
  end
end
--
function WORLDMAPQUEST_RBUP_MENU(frame, ctrl, str, num)
  local menuTitle = "worldmapquest";
  local context = ui.CreateContextMenu(
    "CONTEXT_WORLDMAPQUEST", menuTitle, 0, 0, string.len(menuTitle) * 10, 100);
  ui.AddContextMenuItem(context, "toggleRepeatQuest", "WORLDMAPQUEST_TOGGLE_REPEAT_QUEST()");	
  ui.AddContextMenuItem(context, "Cancel", "None");
  ui.OpenContextMenu(context);
end
--
function WORLDMAPQUEST_TOGGLE_REPEAT_QUEST()
  woqu:ToggleRepeatQuest();
end

-- create instance.
if (woqu ~= nil) then
  woqu:Destroy();
end
woqu = WorldmapQuest();
