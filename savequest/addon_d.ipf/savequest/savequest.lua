_G["SAVEQUEST"]=_G["SAVEQUEST"] or {}
local SaveQuest = _G["SAVEQUEST"]["SAVEQUEST"] or {}
SaveQuest.FRAME_SHORTCUT_USERVALUE_LAYERLEVEL = "SAVEQUEST_LAYERLEVEL"
local saqu=_G["SAVEQUEST"]["SAQU"]

-- constructor.
function SaveQuest.new(self)
  -- initialize members.
  local members = {};

  members.path = "../addons/savequest/quests_%s.txt";
  members.pathShortCutLoc = "../addons/savequest/quests_scl_%s.txt";
  members.pathGlobalConfing = "../addons/savequest/settings.txt";
  members.savemark = "{ol}saved."
  members.questInfo = {};

  members.framePrefix = "savequest_";
  members.questShortCutInfo = {};

  members.globalConfig = {};

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
  members.SaveShortCutPos = function(self, name, remove, locked)
    -- save memory.
    local frame = ui.GetFrame(name);
    if (frame == nil or remove == 1) then
      self.questShortCutInfo[name] = nil;
    else
      local layerlevel = frame:GetUserIValue(SaveQuest.FRAME_SHORTCUT_USERVALUE_LAYERLEVEL)
      if (frame:GetUserValue(SaveQuest.FRAME_SHORTCUT_USERVALUE_LAYERLEVEL) == 'None') then
        layerlevel = 199
      end
      self.questShortCutInfo[name] = { x = frame:GetX(), y = frame:GetY(), ls = locked, ll = layerlevel };
    end
    -- persistence.
    local cid = info.GetCID(session.GetMyHandle());
    local f, e = io.open(string.format(self.pathShortCutLoc, cid), "w");
    if (f == nil) then
      return;
    end
    for k, v in pairs(self.questShortCutInfo) do
      f:write(string.format("saqu.questShortCutInfo.%s = { x = %d, y = %d, ls = %d, ll = %d };\n", k, v.x, v.y, v.ls, v.ll));
    end
    f:flush();
    f:close();
  end

  -- 設定ファイルからショートカット情報を取得して画面に復元する
  --  self：
  --  customLayerLevel：０より大きい場合、任意のレイヤーレベルを設定して復元する
  members.LoadShortCutLoc = function(self, customLayerLevel)
    -- ファイルから設定を読み込む
    self.questShortCutInfo = {};
    local cid = info.GetCID(session.GetMyHandle());
    local s, e = pcall(dofile, string.format(self.pathShortCutLoc, cid))
    if (not s) then
      return
    end
    -- ショートカットの数だけ生成処理
    for k, v in pairs(self.questShortCutInfo) do
      -- 任意のレイヤーレベルを設定
      if (customLayerLevel > 0) then
        v.ll = customLayerLevel
        ui.GetFrame(k):SetUserValue(SaveQuest.FRAME_SHORTCUT_USERVALUE_LAYERLEVEL, v.ll)
        self:SaveShortCutPos(k, 0, v.ls)
      end
      -- バージョンで過不足のあるものを調整する
      -- for v1.2.0 up to v1.2.1.
      if (v.ls == nil) then
        v.ls = 0;
        self:SaveShortCutPos(k, 0, v.ls);
      end
      -- for v1.2.1 up to v1.2.2.
      if (v.ll == nil) then
        v.ll = 199;
        self:SaveShortCutPos(k, 0, v.ls);
      end
      -- ショートカット生成
      self:CreateShortCut(string.gsub(k, self.framePrefix, ""), v.x, v.y, v.ls, v.ll);
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
    ui.AddContextMenuItem(context, "Slot", string.format("saqu:CreateSlot(%d)", questID));
    ui.AddContextMenuItem(context, "Cancel", "None");
    ui.OpenContextMenu(context);
  end

  -- shortcut menu.
  members.ShortcutMenu = function(self, questID, locked)
    local questIES = GetClassByType("QuestProgressCheck", questID);
    local menuTitle = string.format("[%d] %s", questID, questIES.Name);
    local context = ui.CreateContextMenu(
      "CONTEXT_SAVE_QUEST_SHORTCUT", menuTitle, 0, 0, string.len(menuTitle) * 6, 100);
    if (locked == "0") then
      ui.AddContextMenuItem(context, "Lock", string.format("SAVEQUEST_LOCK_OR_UNLOCK_SHORTCUT(%d, 1)", questID));
    else
      ui.AddContextMenuItem(context, "UnLock", string.format("SAVEQUEST_LOCK_OR_UNLOCK_SHORTCUT(%d, 0)", questID));
    end

    if (session.party.GetMyPartyObj(PARTY_NORMAL)) then
      if (self:IsPartySharedQuest(questID)) then
        ui.AddContextMenuItem(context, "UnShare", string.format("saqu:UnShareWithParty(%d)", questID));
      else
        ui.AddContextMenuItem(context, "Share", string.format("saqu:ShareWithParty(%d)", questID));
      end
    end

    ui.AddContextMenuItem(context, "FlattenLayerLv", string.format("saqu:FlattenLayerLv(%d)", questID));

    local fixedWidth = tonumber(self.globalConfig['fixedwidth']) or 0
    ui.AddContextMenuItem(context, fixedWidth == 0 and "FixedWidth" or "UnFixedWidth", "saqu:ToggleFixedWidth()");

    ui.AddContextMenuItem(context, "Remove", string.format("SAVEQUEST_REMOVE_SHORTCUT(%d)", questID));
    ui.AddContextMenuItem(context, "Cancel", "None");
    ui.OpenContextMenu(context);
  end

  -- スロットを一時的に作成
  members.CreateSlot = function(self, questID)
    local questIES = GetClassByType('QuestProgressCheck', questID)
    local zoneName =
      GetClassString(
        'Map',
        questIES[CONVERT_STATE(SCR_QUEST_CHECK_Q(SCR_QUESTINFO_GET_PC(), questIES.ClassName)) .. 'Map'],
        'Name')

    local frameName = 'savequest_tempslot'
    local frame = ui.GetFrame(frameName) or ui.CreateNewFrame('savequest', frameName)
    frame:SetSkinName("downbox")
    frame:SetAlpha(10)
    frame:Resize(40, 40)
    frame:SetOffset(mouse.GetX(), mouse.GetY())
    local slot = frame:CreateOrGetControl('slot', 'slot', 0, 0, 40, 40)
    tolua.cast(slot, 'ui::CSlot')
    local icon = CreateIcon(slot)
    icon:Set('questinfo_return', 'WarpAction', questID, 0, 0)
    icon:SetTextTooltip(zoneName..' - '..questIES.Name)
    SAVEQUEST_TEMPSLOT_ON_RIGHTBUTTONUP = function(frame, ctrl, str, num)
      ui.DestroyFrame(frame:GetName())
    end
    slot:SetEventScript(ui.RBUTTONUP, 'SAVEQUEST_TEMPSLOT_ON_RIGHTBUTTONUP')
  end

  members.CreateSharePartyIcon = function(self, frame)
		local icon = frame:CreateOrGetControl("picture", "SHARE_PARTY", 30, 30, 0, 0, 0, 0, 0, 0);
    icon:SetOffset(frame:GetWidth() - 30, 0);
		icon:ShowWindow(1);
		icon = tolua.cast(icon, "ui::CPicture");
		icon:SetImage("party_indi_icon");
    icon:SetEnableStretch(1);
    return icon;
  end

  members.ShareWithParty = function(self, questID)
    party.ReqChangeMemberProperty(PARTY_NORMAL, "Shared_Quest", questID);
    REQUEST_QUEST_SHARE_PARTY_PROGRESS(questID)
    QUEST_UPDATE_ALL(ui.GetFrame("quest"));
    -- create share party icon.
    local frame = ui.GetFrame(saqu:GetFrameNameFromQuestID(questID));
    self:CreateSharePartyIcon(frame);
  end

  members.UnShareWithParty = function(self, questID)
    CANCEL_QUEST_SHARE_PARTY_MEMBER()
    QUEST_UPDATE_ALL(ui.GetFrame("quest"));

    local frame = ui.GetFrame(saqu:GetFrameNameFromQuestID(questID));
    frame:RemoveChild("SHARE_PARTY");
  end

  -- check share with party.
  members.IsPartySharedQuest = function(self, questID)
    return IS_SHARED_QUEST(questID)
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
    -- CHAT_SYSTEM(""..classID.." - "..tostring(saveQuest));
    if (saveQuest == 1) then
      -- show saved mark.
      local savemark = questCtrl:CreateOrGetControl('richtext', "savemark", 0, 0, 20, 10);
      tolua.cast(savemark, "ui::CRichText");
      savemark:SetText(self.savemark);
      savemark:SetOffset(340, 0);
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
      picture:SetOffset(380, 5);
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
  members.CreateShortCut = function(self, questID, x, y, locked, layerlevel)
    -- check exists.
    local frameName = self:GetFrameNameFromQuestID(questID);
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
    frame:SetEventScript(ui.MOUSEWHEEL, "SAVEQUEST_END_WHEEL");

    frame:SetUserValue("SAVEQUEST_QUESTID", questID);
    self:LockOrUnlockShortCut(frameName, locked);

    frame:SetUserValue(SaveQuest.FRAME_SHORTCUT_USERVALUE_LAYERLEVEL, layerlevel)
    frame:SetLayerLevel(layerlevel)

    local picture = self:CreateStatePicture(frame, questIES);
    picture:SetTooltipType('texthelp');
    picture:SetTooltipArg(questIES.Name);
    picture:SetEventScript(ui.RBUTTONUP, "SAVEQUEST_OPEN_SHORTCUT_MENU");

    local fontSize = 12;
    local mapInfo = frame:CreateOrGetControl('richtext', "mapinfo", 0, 0, 100, 40);
    tolua.cast(mapInfo, "ui::CRichText");
    mapInfo:SetOffset(22, 4);
    mapInfo:SetText(string.format("{s%d}{ol}%s", fontSize, zoneName));
    mapInfo:EnableHitTest(0)

    frame:SetOffset(x, y);

    local sharePartyIconSpace = 12;
    frame:Resize(mapInfo:GetWidth() + 35 + sharePartyIconSpace, 20);
    if ((tonumber(self.globalConfig['fixedwidth']) or 0) == 1) then
      frame:Resize(#zoneName / 7 * fontSize + 30 + sharePartyIconSpace, 20);
    end
    frame:ShowWindow(1);

    DESTROY_CHILD_BYNAME(frame, 'SHARE_PARTY')
    if (self:IsPartySharedQuest(tostring(questID))) then
      self:CreateSharePartyIcon(frame);
    end

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

  members.GetFrameNameFromQuestID = function(self, questID)
    return self.framePrefix..questID;
  end

  members.LockOrUnlockShortCut = function(self, frameName, locked)
    local frame = ui.GetFrame(frameName);
    frame:SetUserValue("SAVEQUEST_LOCKSTATE", locked);
    local movable = 1 - locked;  -- reverse flag.
    frame:EnableMove(movable);
  end

  -- ショートカットのレイヤーレベルを統一する
  members.FlattenLayerLv = function(self, questID)
    CHAT_SYSTEM('[savequest] flatten layer level start.')
    local frame = ui.GetFrame(self:GetFrameNameFromQuestID(questID))
    local layerlevel = frame:GetUserIValue(SaveQuest.FRAME_SHORTCUT_USERVALUE_LAYERLEVEL)
    if (frame:GetUserValue(SaveQuest.FRAME_SHORTCUT_USERVALUE_LAYERLEVEL) == 'None') then
      layerlevel = 199
    end
    CHAT_SYSTEM('[savequest] change to ' .. layerlevel)
    self:LoadShortCutLoc(layerlevel)
    CHAT_SYSTEM('[savequest] flatten layer level end.')
  end

  -- ショートカットの幅を固定するか否か
  members.ToggleFixedWidth = function(self)
    -- 初回は 0 -> 1 で固定幅化
    local s, e = pcall(dofile, self.pathGlobalConfing)
    if (not s) then
      self.globalConfig['fixedwidth'] = 0
    else
      self.globalConfig['fixedwidth'] = tonumber(e)
    end
    local state = self.globalConfig['fixedwidth']
    self.globalConfig['fixedwidth'] = math.abs(state - 1)
    -- 保存
    local f, e = io.open(self.pathGlobalConfing, "w");
    if (f == nil) then
      return;
    end
    f:write(string.format('return %d', self.globalConfig['fixedwidth']))
    f:flush();
    f:close();
    -- 再描画
    self:LoadShortCutLoc(0)
  end

  -- recover addon state.
  members.Destroy = function(self)
    UPDATE_QUESTINFOSET_2 = saqu.UPDATE_QUESTINFOSET_2;
    saqu.UPDATE_QUESTINFOSET_2 = nil;
    if (saqu.UPDATE_QUEST_CTRL ~= nil) then
      UPDATE_QUEST_CTRL = saqu.UPDATE_QUEST_CTRL;
      end
    SHARE_QUEST_WITH_PARTY = saqu.SHARE_QUEST_WITH_PARTY;
    saqu.SHARE_QUEST_WITH_PARTY = nil;
    CANCEL_SHARE_QUEST_WITH_PARTY = saqu.CANCEL_SHARE_QUEST_WITH_PARTY;
    saqu.CANCEL_SHARE_QUEST_WITH_PARTY = nil;
    EXEC_ABANDON_QUEST = saqu.EXEC_ABANDON_QUEST;
    saqu.EXEC_ABANDON_QUEST = nil;
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(SaveQuest, {__call = SaveQuest.new});

-- frame initialize.
function SAVEQUEST_ON_INIT(addon, frame)
  -- remove old state.
	if (saqu ~= nil) then
		saqu:Destroy()
	end
	-- create instance.
	saqu = SaveQuest()
	_G["SAVEQUEST"]["SAQU"]=saqu
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
    saqu:LoadShortCutLoc(0)
  end

  -- override open quest list savemark.
  if (saqu.UPDATE_QUEST_CTRL == nil) then
    saqu.UPDATE_QUEST_CTRL = UPDATE_QUEST_CTRL;
  end
  UPDATE_QUEST_CTRL = function(ctrl, questInfo)
    saqu.UPDATE_QUEST_CTRL(ctrl, questInfo);
    saqu:UpdateQuestListUI(ctrl, questInfo.QuestClassID);
  end

  -- override (un)share party process.
  if (saqu.SHARE_QUEST_WITH_PARTY == nil) then
    saqu.SHARE_QUEST_WITH_PARTY = SHARE_QUEST_WITH_PARTY;
  end
  SHARE_QUEST_WITH_PARTY = function(parent, ctrlSet)
    saqu.SHARE_QUEST_WITH_PARTY(parent, ctrlSet);
    saqu:ShareWithParty(parent:GetUserIValue("QUEST_CLASSID"));
  end
  if (saqu.CANCEL_SHARE_QUEST_WITH_PARTY == nil) then
    saqu.CANCEL_SHARE_QUEST_WITH_PARTY = CANCEL_SHARE_QUEST_WITH_PARTY;
  end
  CANCEL_SHARE_QUEST_WITH_PARTY = function(parent, ctrlSet)
    saqu:UnShareWithParty(parent:GetUserIValue("QUEST_CLASSID"));
    saqu.CANCEL_SHARE_QUEST_WITH_PARTY(parent, ctrlSet);
  end
  -- 保存済みのクエストを破棄すると困ったことになることの対応
  -- なんでこんな操作をするかな...
  if (saqu.EXEC_ABANDON_QUEST == nil) then
    saqu.EXEC_ABANDON_QUEST = EXEC_ABANDON_QUEST
  end
  EXEC_ABANDON_QUEST = function(questID)
    saqu.EXEC_ABANDON_QUEST(questID)
    SAVEQUEST_RELEASE(questID)
  end
  addon:RegisterMsg("TARGET_SET", "SAVEQUEST_REMOVE_NPC");
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
  saqu:CreateShortCut(questID, x, y, 0, 199);
end

function SAVEQUEST_OPEN_SHORTCUT_MENU(ctrl)
  saqu:ShortcutMenu(ctrl:GetUserValue("SAVEQUEST_QUESTID"), ctrl:GetUserValue("SAVEQUEST_LOCKSTATE"));
end

function SAVEQUEST_LOCK_OR_UNLOCK_SHORTCUT(questID, locked)
  local frameName = saqu:GetFrameNameFromQuestID(questID);
  saqu:LockOrUnlockShortCut(frameName, locked);
  saqu:SaveShortCutPos(frameName, 0, locked);
end

function SAVEQUEST_REMOVE_SHORTCUT(questID)
  local name = saqu:GetFrameNameFromQuestID(questID);
  ui.DestroyFrame(name);
  saqu:SaveShortCutPos(name, 1);
end

-- frame drag end.
function SAVEQUEST_END_DRAG(frame)
  saqu:SaveShortCutPos(frame:GetName(), 0, frame:GetUserValue("SAVEQUEST_LOCKSTATE"));
end

function SAVEQUEST_END_WHEEL(frame, ctrl, delta, argNum)
  local locked = frame:GetUserIValue("SAVEQUEST_LOCKSTATE")
  if (locked == 1) then
    return
  end
  local level = frame:GetUserIValue(SaveQuest.FRAME_SHORTCUT_USERVALUE_LAYERLEVEL)
  if (frame:GetUserValue(SaveQuest.FRAME_SHORTCUT_USERVALUE_LAYERLEVEL) == 'None') then
    level = 199
    frame:SetUserValue(SaveQuest.FRAME_SHORTCUT_USERVALUE_LAYERLEVEL, level)
  end
  if (level < 0) then
    return
  end
  if (delta > 0) then
    level = level + 1
  elseif (delta < 0) then
    level = level - 1
  else
    CHAT_SYSTEM('[savequest] delta is 0.')
  end
  CHAT_SYSTEM(string.format('[savequest] %s LayerLevel to %d', frame:GetName(), level))
  frame:SetUserValue(SaveQuest.FRAME_SHORTCUT_USERVALUE_LAYERLEVEL, level)
  frame:SetLayerLevel(level)
end

-- いる？

_G["SAVEQUEST"]["SAQU"]=saqu
_G["SAVEQUEST"]["SAVEQUEST"] =SaveQuest