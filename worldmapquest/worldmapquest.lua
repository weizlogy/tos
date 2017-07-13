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
  members.InsertPossibleQuestCount = function(self, mapCls, gbox, parentGBox, ctrlSet)
    parentGBox:RemoveChild("questText_"..mapCls.ClassID);
    local count = self.possibleQuests[mapCls.ClassID];
    if (count == nil or count <= 0) then
      return;
    end
    -- calculate height.
    local heightBuff = 0;
    local mapType = TryGetProp(mapCls, 'MapType');
    if mapType == 'Dungeon' then
      heightBuff = 30;
    end
    -- create count text.
    local questText = parentGBox:CreateOrGetControl(
      "richtext", "questText_"..mapCls.ClassID, gbox:GetX(), gbox:GetY(), 30, 30);
    questText:SetText(string.format("{@st66e}[%d]", count));
    questText:SetOffset(gbox:GetOffsetX() - questText:GetWidth() + 2, gbox:GetOffsetY() + heightBuff);
    questText:EnableHitTest(1);
    questText:SetEventScript(ui.RBUTTONUP, 'WORLDMAPQUEST_RBUP_MENU');
  end
  --
  members.InsertQuestWarpIcon = function(self, parentGBox, spaceX, startX, spaceY, startY)
    -- get worldmap scale.
    local curSize = config.GetConfigInt("WORLDMAP_SCALE", 6);
    local sizeRatio = 1 + curSize * 0.25;
    -- get warpable quests.
    local warpableQuestList = GetQuestProgressClassByState("SUCCESS");
    -- create worldmap warp objects.
    for i = 1, #warpableQuestList do
      local questIES = warpableQuestList[i];
      if (SCR_QUEST_CHECK_C(GetMyPCObject(), questIES.ClassName) == "SUCCESS" and questIES.SUCC_WARP == "YES") then
        local mapCls = GetClass('Map', questIES.EndMap);
        local x, y, dir, index = GET_WORLDMAP_POSITION(mapCls.WorldMap);
        local oid = "statepicture_"..mapCls.ClassID;
        local picX = startX + x * spaceX * sizeRatio + 120;
        local picY = startY - y * spaceY * sizeRatio + 25;
        -- create warp icon.
        local mapName = parentGBox:CreateOrGetControl('richtext', oid, picX, picY, 24, 100);
        tolua.cast(mapName, "ui::CRichText");
        mapName:SetText("{ol}"..mapCls.Name);
        local picture = parentGBox:CreateOrGetControl('picture', oid.."_p", picX - 24, picY - 2, 24, 24);
        tolua.cast(picture, "ui::CPicture");
        picture:SetEnableStretch(1);
        picture:SetImage("questinfo_return");
        picture:SetAngleLoop(-3);
        picture:SetUserValue("PC_FID", GET_QUESTINFO_PC_FID());
        picture:SetUserValue("RETURN_QUEST_NAME", mapCls.Name.." - "..questIES.Name);
        picture:EnableHitTest(1);
        picture:SetEventScript(ui.LBUTTONUP, "WORLDMAPQUEST_QUESTION_QUEST_WARP");
        picture:SetEventScriptArgNumber(ui.LBUTTONUP, questIES.ClassID);
      end
    end
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
    CREATE_ALL_WARP_CONTROLS = woqu.CREATE_ALL_WARP_CONTROLS;
    woqu.CREATE_ALL_WARP_CONTROLS = nil;
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
  OPEN_WORLDMAP = function(frame)
    -- clear old state.
    local pic = frame:GetChild("pic");
    local worldMapBox = pic:GetChild("GBOX_WorldMap");
    if (worldMapBox ~= nil) then
      DESTROY_CHILD_BYNAME(worldMapBox, "questText_");
      DESTROY_CHILD_BYNAME(worldMapBox, "statepicture_");
    end
    if (keyboard.IsKeyPressed("LALT") == 1) then
      frame:SetUserValue('Type', "QuestWarp");
    end
    -- Key "N" => None - None
    -- Statue  => None - NPC
    -- Scroll  => Scroll_Warp_quest - None
    local warp = frame:GetUserValue("SCROLL_WARP");
    local type = frame:GetUserValue('Type');
    if (warp == "None" and type == "None") then
      woqu:CreatePossibleQuests();
    end
    woqu.OPEN_WORLDMAP(frame);
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
      local ctrlSet = gbox:CreateOrGetControlSet('worldmap_zone', "ZONE_CTRL_" .. mapCls.ClassID, ui.LEFT, ui.TOP, 0, 0, 0, 0);
      -- call interrupt function.
      woqu:InsertPossibleQuestCount(mapCls, gbox, parentGBox, ctrlSet);
  end
  -- override create warp worldmap control function.
  if (woqu.CREATE_ALL_WARP_CONTROLS == nil) then
    woqu.CREATE_ALL_WARP_CONTROLS = CREATE_ALL_WARP_CONTROLS;
  end
  CREATE_ALL_WARP_CONTROLS = function(
      frame, parentGBox, makeWorldMapImage, changeDirection, mapName,
      currentDirection, spaceX, startX, spaceY, startY, pictureStartY)
    local type = frame:GetUserValue('Type');
    if (type == "QuestWarp") then
      local pic = frame:GetChild("pic");
      local worldMapBox = pic:GetChild("GBOX_WorldMap");
      woqu:InsertQuestWarpIcon(worldMapBox, spaceX, startX, spaceY, startY);
      return;
    end
    woqu.CREATE_ALL_WARP_CONTROLS(
      frame, parentGBox, makeWorldMapImage, changeDirection, mapName,
      currentDirection, spaceX, startX, spaceY, startY, pictureStartY);
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
--
function WORLDMAPQUEST_QUESTION_QUEST_WARP(frame, ctrl, argStr, questID)
  local map = ui.GetFrame("worldmap");
  if (map:IsVisible() == 1) then
    map:ShowWindow(0);
  end
  QUESTION_QUEST_WARP(frame, ctrl, argStr, questID);
end

-- create instance.
if (woqu ~= nil) then
  woqu:Destroy();
end
woqu = WorldmapQuest();
