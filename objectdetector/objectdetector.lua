ObjectDetector = {};
-- constructor.
function ObjectDetector.new(self)
  -- initialize members.
  local members = {};
  members.range = 700;
  members.lock = 0;
  members.objectList = {};
  members.path = "../addons/objectdetector/settings.txt";
  members.config = {};

  members.searchName = "";

  -- initialize class.
  members.Initialize = function(self)
    dofile(self.path);
  end

  -- search all objects and output it.
  members.Update = function(self, frame, msg, str, myhandle)
    if (self.lock == 1) then
      return;
    end
    self.lock = 1;
    self.objectList = {};
    local list, count = SelectBaseObject(GetMyPCObject(), self.range, "ALL");
    for i = 1 , count do
      local obj = list[i];
      local iesObj = GetBaseObjectIES(obj);
      local actor = tolua.cast(obj, "CFSMActor");
      local handle = actor:GetHandleVal();
      self.objectList[handle] = 1;
      -- do nothing for my pc.
      if (myhandle ~= handle) then
        self:ShowDetectorObject(ui.GetFrame('map'), actor, iesObj);
        self:ShowDetectorObject(ui.GetFrame('minimap'), actor, iesObj);
      end
    end
    self.lock = 0;
  end
  -- show object to maps.
  members.ShowDetectorObject = function(self, frame, actor, iesObj)
    -- check object info.
    local oi = self:GetDetectObjectInfo(actor, iesObj);
    if (oi.isVisible ~= 1) then
      return;
    end
    local handle = actor:GetHandleVal();
    local pos = actor:GetPos();
    -- create icon on maps.
    local picName = "icon_"..handle;
    if (frame:GetChild(picName) ~= nil) then
      frame:GetChild(picName):ShowWindow(1);
      return;
    end

    local picSize = oi.size;
    local pic = frame:CreateOrGetControl('picture', picName, 0, 0, picSize, picSize);
    tolua.cast(pic, "ui::CPicture");
    pic:SetImage("fullblack");
    pic:SetEnableStretch(1);
    pic:SetTooltipType('texthelp');
    pic:SetTooltipArg(oi.tooltipText);

    local toneSize = picSize - 2;
    local borderSize = 1;
    local pictone = pic:CreateOrGetControl('picture', "tone", borderSize, borderSize, toneSize, toneSize);
    tolua.cast(pictone, "ui::CPicture");
    pictone:SetImage("fullwhite");
    pictone:SetColorTone(oi.color);
    pictone:SetEnableStretch(1);
    pictone:SetTooltipType('texthelp');
    pictone:SetTooltipArg(oi.tooltipText);
    
    if (oi.isBlink == 1) then
      pictone:SetBlink(600000.0, 1.0, oi.color);
    end

    if (oi.found == 1) then
      local foundSize = toneSize - 2;
      local foundBorderSize = 2;
      local picfound = pic:CreateOrGetControl('picture', "found", foundBorderSize, foundBorderSize, foundSize, foundSize);
      tolua.cast(picfound, "ui::CPicture");
      picfound:SetImage("fullwhite");
      picfound:SetColorTone(oi.color);
      picfound:SetEnableStretch(1);
      picfound:SetBlink(600000.0, 1.0, oi.color);
      picfound:SetTooltipType('texthelp');
      picfound:SetTooltipArg(oi.tooltipText);
    end

    pic:SetUserValue("HANDLE", handle);

    if (frame:GetName() == "map") then
      pic:RunUpdateScript("UPDATE_MAP_STATE");
    elseif (frame:GetName() == "minimap") then
      pic:RunUpdateScript("UPDATE_MINIMAP_STATE");
    end
  end
  -- convert object to picture metadata.
  members.GetDetectObjectInfo = function(self, actor, iesObj)
    -- create object info.
    local oi = {
      isVisible = 1,
      isBlink = 0,
      tooltipText = "...",
      color = "FF000000",
      size = 6,
      found = 0
    };
    -- insert info by object type, faction, and some conditions.
    local objType = actor:GetObjType();
    local faction = actor:GetFactionStr();
    if (objType == GT_MONSTER) then
      local rank = iesObj.MonRank;
      local tempConfig = self.config.mon[faction];
      if (tempConfig == nil) then
        tempConfig = self.config.mon;
      end
      oi.color = tempConfig.color;
      oi.isVisible = tempConfig.isVisible;
      oi.isBlink = tempConfig.isBlink;
      oi.tooltipText = string.format("[Lv.%s]%s(%s) f=%s r=%s",
       actor:GetLv(), actor:GetName(), iesObj.ClassName, faction, rank);
      -- monster size related by it's icon size.
      local sdr = SCR_Get_MON_SDR(iesObj);
      if (sdr >= 5) then
        sdr = sdr - 5;
      end
      -- ボス判定
      -- サモニングはクラス名の接頭詞としてpc_summon_付いているのでそれで除外判定する
      if (rank == 'Boss' and string.find(iesObj.ClassName, 'pc_summon_') == nil) then
        sdr = oi.size * 2
      end
      oi.size = oi.size + sdr;
      -- check treasure.
      if (string.find(iesObj.ClassName, "treasure") ~= nil) then
        local trConfig = self.config.treasure;
        if (trConfig ~= nil) then
          oi.color = trConfig.color;
          oi.isVisible = trConfig.isVisible;
          oi.isBlink = trConfig.isBlink;
        end
      end
      -- check clover.
      local handle = actor:GetHandleVal();
      local buffCount = info.GetBuffCount(handle);
			for i = 0, buffCount - 1 do
				local buff = info.GetBuffIndexed(handle, i);
        local cls = GetClassByType("Buff", buff.buffID);
        if (cls.Icon == "clover") then
          oi.tooltipText = oi.tooltipText.." b="..cls.ClassName;
          --CHAT_SYSTEM(string.format("!!! clover !!! %d", buff.buffID));
          local clConfig = self.config.clover[cls.ClassName];
          if (clConfig == nil) then
            clConfig = self.config.clover;
          end
          oi.color = clConfig.color;
          oi.isVisible = clConfig.isVisible;
          oi.isBlink = clConfig.isBlink;
        end
			end
    elseif (objType == GT_PC) then
      oi.color = self.config.pc.color;
      oi.isVisible = self.config.pc.isVisible;
      oi.tooltipText = string.format("[Lv.%s]%s %s",
       actor:GetLv(), actor:GetName(), actor:GetPCApc():GetFamilyName());
--[[
    elseif (objType == GT_END) then
      oi.color = self.config.end.color;
      CHAT_SYSTEM("GT_END=>"..type(iesObj));
]]
    elseif (objType == GT_ITEM) then
      oi.color = self.config.item.color;
      oi.isVisible = self.config.item.isVisible;
      oi.tooltipText = string.format("[Lv.%s]%s",
       GET_ITEM_LEVEL(iesObj), actor:GetName());
    else
      -- CHAT_SYSTEM("unknown object type. => "..objType);
    end
    
    if (self.searchName ~= "") then
      local dicName = dictionary.ReplaceDicIDInCompStr(actor:GetName());
      if (dicName == self.searchName) then
        oi.found = 1;
        oi.tooltipText = oi.tooltipText.." found!";
      end
    end
    return oi;
  end
  -- update object state.
  members.UpdateObjectState = function(self, frame, parent, calculateAxis)
    local handle = frame:GetUserIValue("HANDLE");
    local actor = world.GetActor(handle);
    if (self.objectList[handle] == nil or actor:IsDead() == 1) then
      frame:ShowWindow(0);
      DESTROY_CHILD_BYNAME(ui.GetFrame('map'), "icon_"..handle);
      DESTROY_CHILD_BYNAME(ui.GetFrame('minimap'), "icon_"..handle);
      return 0;
    end
    local axis = calculateAxis(self, parent, actor);
    axis.x = axis.x - frame:GetWidth() / 2;
    axis.y = axis.y - frame:GetHeight() / 2;
    frame:SetOffset(axis.x, axis.y);
    frame:ShowWindow(1);
    return 1;
  end
  -- calculate axis for map.
  members.CalculateMapAxis = function(self, parent, actor)
    local pos = actor:GetPos();
    local mapprop = session.GetCurrentMapProp();
    local mmpos = mapprop:WorldPosToMinimapPos(pos, m_mapWidth, m_mapHeight);
    return {
      x = mmpos.x + m_offsetX,
      y = mmpos.y + m_offsetY
    };
  end
  -- calculate axis for minimap.
  members.CalculateMinimapAxis = function(self, parent, actor)
    local cursize = GET_MINIMAPSIZE();
    local pictureui = GET_CHILD(parent, "map", "ui::CPicture");
    local mmw = pictureui:GetImageWidth() * (100 + cursize) / 100;
    local mmh = pictureui:GetImageHeight() * (100 + cursize) / 100;

    local mypos = info.GetPositionInMap(session.GetMyHandle(), mmw, mmh);

    local pos = actor:GetPos();
    local mapprop = session.GetCurrentMapProp();
    local mmpos = mapprop:WorldPosToMinimapPos(pos, mmw, mmh);
    return {
      x = mmpos.x - (mypos.x - mini_frame_hw),
      y = mmpos.y - (mypos.y - mini_frame_hh)
    };
  end
  -- 
  members.SetSearchName = function(self, name)
    self.searchName = name;
    CHAT_SYSTEM("[objectdetector] Searching <"..self.searchName.."> ...");
  end
  -- clear output objects.
  members.Clear = function(self)
    DESTROY_CHILD_BYNAME(ui.GetFrame('map'), "icon_");
    DESTROY_CHILD_BYNAME(ui.GetFrame('minimap'), "icon_");
  end
  -- destroy.
  members.Destroy = function(self)
    UI_CHAT = obde.UI_CHAT;
  end
  return setmetatable(members, {__index = self});
end

-- set call.
setmetatable(ObjectDetector, {__call = ObjectDetector.new});

-- frame initialize.
function OBJECTDETECTOR_ON_INIT(addon, frame)
  -- clear objects.
  obde:Clear();
  -- initialize.
  obde:Initialize();
  -- regist check object handler.
  addon:RegisterMsg('MAP_CHARACTER_UPDATE', 'DETECTOR_UPDATE');
  addon:RegisterMsg('FPS_UPDATE', 'DETECTOR_UPDATE');
  -- override chat command.
  if (obde.UI_CHAT == nil) then
    obde.UI_CHAT = UI_CHAT;
  end
  UI_CHAT = function(msg)
    local temp = msg;
    temp = string.gsub(temp, '/g', '');
    temp = string.gsub(temp, '/p', '');
    temp = string.gsub(temp, '/y', '');
    if (string.find(temp, "/detector search", 1, true) == 1) then
      local name = string.match(temp, "^/detector search (.+)$");
      obde:SetSearchName(name);
    end
    obde.UI_CHAT(msg);
  end
end

-- check object handler.
function DETECTOR_UPDATE(frame, msg, str, handle)
  obde:Update(frame, msg, str, handle);
end

-- picture update handler.
function UPDATE_MAP_STATE(frame)
  return obde:UpdateObjectState(frame, ui.GetFrame('map'), obde.CalculateMapAxis);
end

-- picture update handler.
function UPDATE_MINIMAP_STATE(frame)
  return obde:UpdateObjectState(frame, ui.GetFrame('minimap'), obde.CalculateMinimapAxis);
end

-- create instance.
if (obde ~= nil) then
  obde:Destroy();
end
obde = ObjectDetector();
