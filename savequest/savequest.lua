SaveQuest = {};

-- constructor.
function SaveQuest.new(self)
  -- initialize members.
  local members = {};
  members.path = "../addons/savequest/quests_%s.txt";
  members.pathShortCutLoc = "../addons/savequest/quests_scl_%s.txt";
  members.savemark = "{ol}saved."
  members.questInfo = {};

  members.framePrefix = "savequest_";
  members.questShortCutInfo = {};

  -- save questInfo contents to local.
  members.SaveQuest = function(self)
    local cid = info.GetCID(session.GetMyHandle());
    local f, e = io.open(string.format(self.path, cid), "w");
    if (f == nil) then
      return;
    end
    for k, v in pairs(self.questInfo) do
      if (v == 1) then
        f:write(k.."\n");
      end
    end
    f:flush();
    f:close();
  end

  -- load local to questInfo.
  members.LoadQuest = function(self)
    self.questInfo = {};
    local cid = info.GetCID(session.GetMyHandle());
    local f, e = io.open(string.format(self.path, cid), "r");
    if (f == nil) then
      f, e = io.open(string.format(self.path, cid), "w");
      f:close();
      return;
    end
    for s in f:lines() do
      self.questInfo[s] = 1;
    end
    f:close();
  end

  -- save shortcut ui location.
  members.SaveShortCutLoc = function(self, name, remove)
    -- save memory.
    local frame = ui.GetFrame(name);
    if (frame == nil or remove == 1) then
      self.questShortCutInfo[name] = nil;
    else
      self.questShortCutInfo[name] = { x = frame:GetX(), y = frame:GetY() };
    end
    -- persistence.
    local cid = info.GetCID(session.GetMyHandle());
    local f, e = io.open(string.format(self.pathShortCutLoc, cid), "w");
    if (f == nil) then
      return;
    end
    for k, v in pairs(self.questShortCutInfo) do
      f:write(string.format("saqu.questShortCutInfo.%s = { x = %d, y = %d };\n", k, v.x, v.y));
    end
    f:flush();
    f:close();
  end

  -- load shortcut ui location.
  members.LoadShortCutLoc = function(self)
    -- load from file.
    self.questShortCutInfo = {};
    local cid = info.GetCID(session.GetMyHandle());
    dofile(string.format(self.pathShortCutLoc, cid));
    -- recreate.
    for k, v in pairs(self.questShortCutInfo) do
      self:CreateShortCut(string.gsub(k, self.framePrefix, ""), v.x, v.y);
    end
  end

  -- create menu script, save state text.
  members.UpdateQuestUI = function(self)
    local frame2 = ui.GetFrame('questinfoset_2')
    local gbox = GET_CHILD(frame2, "member", "ui::CGroupBox");
    -- loop current shown quest at right side.
    local cnt = quest.GetCheckQuestCount();
    for i = 0, cnt - 1 do
      -- convert questid to target control.
      local questID = quest.GetCheckQuest(i);
      local questIES = GetClassByType("QuestProgressCheck", questID);
      local translated_QuestGroup = dictionary.ReplaceDicIDInCompStr(questIES.QuestGroup);
      local ctrlname = "_Q_" .. questIES.ClassID;
      if (translated_QuestGroup ~= "None") then
        local strFindStart, strFindEnd = string.find(translated_QuestGroup, "/");
        local questGroupName  = string.sub(translated_QuestGroup, 1, strFindStart - 1);
        ctrlname = "_Q_" .. questGroupName;
      end
      local ctrlset = gbox:GetChild(ctrlname);
      tolua.cast(ctrlset, 'ui::CControlSet');
      if (ctrlset ~= nil) then
        --CHAT_SYSTEM(ctrlset:GetChild("statepicture"):GetUserValue("PC_FID"))
        -- remove old state.
        DESTROY_CHILD_BYNAME(ctrlset, "savemark");
        -- get quest result, use warp.
        local result = ctrlset:GetSValue();

        -- create right click menu on success and warp-able quest.
        local content = GET_CHILD(ctrlset, 'groupQuest_title', "ui::CRichText");
        content:EnableHitTest(0);

        if (self:IsWarpableQuest(questIES) == 1) then
          content:EnableHitTest(1);
          content:SetEventScript(ui.RBUTTONUP, 'SAVEQUEST_RBUP_MENU');
          content:SetEventScriptArgString(ui.RBUTTONUP, questIES.Name);
          content:SetEventScriptArgNumber(ui.RBUTTONUP, questIES.ClassID);
          -- show text for already saved.
          local saveQuest = self.questInfo[""..questIES.ClassID];
          if (saveQuest == 1) then
            local savemark = ctrlset:CreateOrGetControl('richtext', "savemark", 0, 0, 20, 10);
            tolua.cast(savemark, "ui::CRichText");
            savemark:SetText(self.savemark);
            savemark:SetOffset(36, 35);
          end
        end
      end
    end
  end

  -- save quest menu.
  members.QuestMenu = function(self, questName, questID)
    local menuTitle = string.format("[%d] %s", questID, questName);
    local context = ui.CreateContextMenu(
      "CONTEXT_SAVE_QUEST", menuTitle, 0, 0, string.len(menuTitle) * 6, 100);
    ui.AddContextMenuItem(context, "Save", string.format("SAVEQUEST_SAVE(%d)", questID));	
    ui.AddContextMenuItem(context, "Release", string.format("SAVEQUEST_RELEASE(%d)", questID));	
    ui.AddContextMenuItem(context, "ShortCut", string.format("SAVEQUEST_SHORTCUT(%d)", questID));	
    ui.AddContextMenuItem(context, "Cancel", "None");
    ui.OpenContextMenu(context);
  end

  -- save quest to local.
  members.Save = function(self, questID)
    self.questInfo[""..questID] = 1;
    local questIES = GetClassByType("QuestProgressCheck", questID);
	  local result = SCR_QUEST_CHECK_C(GetMyPCObject(), questIES.ClassName);
    self.questInfo[questIES[CONVERT_STATE(result) .. 'NPC']] = 1;
  end

  -- remove quest from local.
  members.Release = function(self, questID)
    self.questInfo[""..questID] = 0;
    local questIES = GetClassByType("QuestProgressCheck", questID);
	  local result = SCR_QUEST_CHECK_C(GetMyPCObject(), questIES.ClassName);
    self.questInfo[questIES[CONVERT_STATE(result) .. 'NPC']] = 0;
  end

  -- remove quest npc character.
  members.RemoveQuestNpc = function(self, handle)
    local gentype = world.GetActor(handle):GetNPCStateType()
    local pc = GetMyPCObject();
    local genList = SCR_GET_XML_IES('GenType_'..GetZoneName(pc), 'GenType', gentype)
    for i = 1, #genList do
      local genobj = genList[i];
      -- CHAT_SYSTEM(genobj.ClassType.." - "..genobj.Dialog)
      local isSaved = self.questInfo[genobj.Dialog];
      if (isSaved == 1) then
        world.Leave(handle, 0.0);
      end
    end
  end

  --
  members.UpdateQuestListUI = function(self, questCtrl, classID)
    DESTROY_CHILD_BYNAME(questCtrl, "savemark");
    local saveQuest = self.questInfo[""..classID];
    --CHAT_SYSTEM(""..classID.." - "..saveQuest);
    if (saveQuest == 1) then
      -- show saved mark.
      local savemark = questCtrl:CreateOrGetControl('richtext', "savemark", 0, 0, 20, 10);
      tolua.cast(savemark, "ui::CRichText");
      savemark:SetText(self.savemark);
      savemark:SetOffset(20, 0);
    end
    local questIES = GetClassByType("QuestProgressCheck", classID);
    if (self:IsWarpableQuest(questIES) == 1) then
      -- create menu.
      questCtrl:EnableHitTest(1);
      questCtrl:SetEventScript(ui.RBUTTONUP, 'SAVEQUEST_RBUP_MENU');
      questCtrl:SetEventScriptArgString(ui.RBUTTONUP, questIES.Name);
      questCtrl:SetEventScriptArgNumber(ui.RBUTTONUP, questIES.ClassID);
      --CHAT_SYSTEM(questCtrl:GetName().." - "..questIES.ClassID)
      -- create warp icon.
      local picture = self:CreateStatePicture(questCtrl, questIES);
    end
  end

  members.CreateStatePicture = function(self, frame, questIES)
    local picture = frame:CreateOrGetControl('picture', "statepicture", 0, 0, 20, 20);
    tolua.cast(picture, "ui::CPicture");
    picture:SetEnableStretch(1);
    picture:SetImage("questinfo_return");
    picture:SetAngleLoop(-3);
    picture:SetUserValue("PC_FID", GET_QUESTINFO_PC_FID());
    picture:SetUserValue("RETURN_QUEST_NAME", questIES.ClassName);
    picture:EnableHitTest(1);
    picture:SetEventScript(ui.LBUTTONUP, "QUESTION_QUEST_WARP");
    picture:SetEventScriptArgNumber(ui.LBUTTONUP, questIES.ClassID);
    return picture;
  end

  -- create quest warp shortcut.
  members.CreateShortCut = function(self, questID, x, y)
    -- check exists.
    local frameName = self.framePrefix..questID;
    local frame = ui.GetFrame(frameName);
    if (frame == nil) then
      frame = ui.CreateNewFrame("savequest", frameName);
    end
    -- get ies.
    local questIES = GetClassByType("QuestProgressCheck", questID);
    -- get map info.
    local result = SCR_QUEST_CHECK_Q(SCR_QUESTINFO_GET_PC(), questIES.ClassName);
    local state = CONVERT_STATE(result);
    local map = questIES[state .. 'Map'];
    local zoneName = GetClassString('Map', map, 'Name');

    -- create ui.
    frame:SetSkinName("downbox");
    frame:SetAlpha(50);
    frame:SetEventScript(ui.LBUTTONUP, "SAVEQUEST_END_DRAG");

    local picture = self:CreateStatePicture(frame, questIES);
    picture:SetTooltipType('texthelp');
    picture:SetTooltipArg(questIES.Name);
    picture:SetEventScript(ui.RBUTTONUP, "SAVEQUEST_REMOVE_SHORTCUT");

    local mapInfo = frame:CreateOrGetControl('richtext', "mapinfo", 0, 0, 100, 40);
    tolua.cast(mapInfo, "ui::CRichText");
    mapInfo:SetOffset(22, 4);
    mapInfo:SetText("{s12}{ol}"..zoneName);
    mapInfo:EnableHitTest(0)

    frame:SetOffset(x, y);
    frame:Resize(#zoneName / 7 * 12 + 30, 20);
    frame:ShowWindow(1);
    return frame;
  end

  -- 1 : warpable quest, 0 : otherwise.
  -- logic refs questinfoset_2.lua MAKE_QUEST_INFO_COMMON
  members.IsWarpableQuest = function(self, questIES)
    local result = SCR_QUEST_CHECK_C(GetMyPCObject(), questIES.ClassName);
    if (GET_QUEST_NPC_STATE(questIES, result) == nil) then
      return 0;
    end
    if (result == 'POSSIBLE' and questIES.POSSI_WARP == 'YES')
      or (result == 'PROGRESS' and questIES.PROG_WARP == 'YES')
      or (result == 'SUCCESS' and questIES.SUCC_WARP == 'YES') then
      return 1;
    end
    return 0;
  end

  -- recover addon state.
  members.Destroy = function(self)
    UPDATE_QUESTINFOSET_2 = saqu.UPDATE_QUESTINFOSET_2;
    saqu.UPDATE_QUESTINFOSET_2 = nil;
    Q_CTRL_BASIC_SET = saqu.Q_CTRL_BASIC_SET;
    saqu.Q_CTRL_BASIC_SET = nil;
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(SaveQuest, {__call = SaveQuest.new});

-- frame initialize.
function SAVEQUEST_ON_INIT(addon, frame)
  -- override quest update event.
  if (saqu.UPDATE_QUESTINFOSET_2 == nil) then
    saqu.UPDATE_QUESTINFOSET_2 = UPDATE_QUESTINFOSET_2;
  end
  UPDATE_QUESTINFOSET_2 = function(frame, msg, check, updateQuestID)
    -- call original.
    saqu.UPDATE_QUESTINFOSET_2(frame, msg, check, updateQuestID);
    -- call my custom logics.
    saqu:LoadQuest();
    saqu:UpdateQuestUI();
    addon:RegisterMsg("TARGET_SET", "SAVEQUEST_REMOVE_NPC");
  end
  -- override open quest list savemark.
  if (saqu.Q_CTRL_BASIC_SET == nil) then
    saqu.Q_CTRL_BASIC_SET = Q_CTRL_BASIC_SET;
  end
  Q_CTRL_BASIC_SET = function(Quest_Ctrl, classID, isNew)
    saqu.Q_CTRL_BASIC_SET(Quest_Ctrl, classID, isNew);
    saqu:UpdateQuestListUI(Quest_Ctrl, classID);
  end
  saqu:LoadQuest();
  saqu:LoadShortCutLoc();
end

-- remove npc event handler.
function SAVEQUEST_REMOVE_NPC(frame, msg, argStr, argNum)
  saqu:RemoveQuestNpc(session.GetTargetHandle());
end

-- show menu dialog event handler.
function SAVEQUEST_RBUP_MENU(frame, ctrl, str, num)
  saqu:QuestMenu(str, num);
end

-- save menu selected event.
function SAVEQUEST_SAVE(questID)
  saqu:Save(questID);
  saqu:SaveQuest();
  saqu:UpdateQuestUI();
  local questList = ui.GetFrame("quest");
  if (questList:IsVisible() == 1) then
    local questBasicSet = GET_CHILD_RECURSIVELY(questList, "_Q_"..questID, "ui::CControlSet");
    saqu:UpdateQuestListUI(questBasicSet, questID, 0);
  end
end

-- release menu selected event.
function SAVEQUEST_RELEASE(questID)
  saqu:Release(questID);
  saqu:SaveQuest();
  saqu:UpdateQuestUI();
  local questList = ui.GetFrame("quest");
  if (questList:IsVisible() == 1) then
    local questBasicSet = GET_CHILD_RECURSIVELY(questList, "_Q_"..questID, "ui::CControlSet");
    saqu:UpdateQuestListUI(questBasicSet, questID, 0);
  end
end

-- shortcut menu selected event.
function SAVEQUEST_SHORTCUT(questID)
  local basePos = 200;
  local width = 50;
  local x = basePos + IMCRandom(-1 * width, width);
  local y = basePos + IMCRandom(-1 * width, width);
  saqu:CreateShortCut(questID, x, y);
end

function SAVEQUEST_REMOVE_SHORTCUT(ctrl)
  local name = ctrl:GetName();
  ui.DestroyFrame(name);
  saqu:SaveShortCutLoc(name, 1);
end

-- frame drag end.
function SAVEQUEST_END_DRAG(frame)
  saqu:SaveShortCutLoc(frame:GetName());
end

-- remove old state.
if (saqu ~= nil) then
  saqu:Destroy();
end
-- create instance.
saqu = SaveQuest();
