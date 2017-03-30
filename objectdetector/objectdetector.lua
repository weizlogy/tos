ObjectDetector = {};
-- constructor.
function ObjectDetector.new(self)
  -- initialize members.
  local members = {};
  members.Range = 700;
  members.Lock = 0;
  members.ObjectList = {};
  -- search all objects and output it.
  members.Update = function(self, frame, msg, str, myhandle)
    if (self.Lock == 1) then
      return;
    end
    self.Lock = 1;
    ObjectList = {};
    local list, count = SelectBaseObject(GetMyPCObject(), self.Range, "ALL");
    for i = 1 , count do
      local obj = list[i];
      local iesObj = GetBaseObjectIES(obj);
      local actor = tolua.cast(obj, "CFSMActor");
      local handle = actor:GetHandleVal();
      ObjectList[handle] = 1;
      -- do nothing for my pc.
      if (myhandle ~= handle) then
        self:ShowDetectorObject(ui.GetFrame('map'), actor, iesObj);
        self:ShowDetectorObject(ui.GetFrame('minimap'), actor, iesObj);
      end
    end
    self.Lock = 0;
  end
  -- show object to maps.
  members.ShowDetectorObject = function(self, frame, actor, iesObj)
    -- check object info.
    local oi = self:GetDetectObjectInfo(actor, iesObj);
    if (oi.IsVisible ~= 1) then
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
    local pic = frame:CreateOrGetControl('picture', picName, 0, 0, 7, 7);
    tolua.cast(pic, "ui::CPicture");
    pic:SetImage("fullblack");
    pic:SetEnableStretch(1);
    pic:SetTooltipType('texthelp');
    pic:SetTooltipArg(oi.TooltipText);

    local pictone = pic:CreateOrGetControl('picture', "tone", 1, 1, 5, 5);
    tolua.cast(pictone, "ui::CPicture");
    pictone:SetImage("fullwhite");
    pictone:SetColorTone(oi.Color:ARGB());
    pictone:SetEnableStretch(1);
    pictone:SetTooltipType('texthelp');
    pictone:SetTooltipArg(oi.TooltipText);

    if (oi.IsBlink == 1) then
      pictone:SetBlink(600000.0, 1.0, oi.Color:ARGB());
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
      IsVisible = 1,
      IsBlink = 0,
      TooltipText = "...",
      Color = {
        A = "FF",
        R = "00",
        G = "00",
        B = "00",
        ARGB = function(self)
          return self.A..self.R..self.G..self.B;
        end
      }
    };
    -- insert info by object type, faction, and some conditions.
    local objType = actor:GetObjType();
    local faction = actor:GetFactionStr();
    if (objType == GT_MONSTER) then
      local rank = iesObj.MonRank;
      oi.Color.R = "99";
      oi.TooltipText = string.format("[Lv.%s]%s(%s) r=%s f=%s",
       actor:GetLv(), actor:GetName(), iesObj.ClassName, rank, faction);
      -- check faction.
      if (faction == "Pet") then
        oi.IsVisible = 0;
        return oi;
      elseif (faction == "RootCrystal") then
        oi.Color.B = "99";
      elseif (faction == "Neutral" or faction == "Peaceful" or faction == "Our_Forces" ) then
        oi.Color.R = "FF";
        oi.Color.G = "99";
        -- check rank.
        if (rank == "NPC" or rank == "MISC" or rank == "Normal" or rank == "Material") then
          oi.Color.G = "66";
        else
          oi.Color.R = "00";
          oi.Color.G = "00";
          oi.Color.B = "00";
        end
      elseif (faction == "Monster") then
        oi.Color.R = "66";
      elseif (faction == "Monster_Chaos1" or faction == "Monster_Chaos2") then
        oi.Color.R = "33";
      elseif (faction == "Law") then
        oi.Color.R = "FF";
      elseif (faction == "IceWall") then
        oi.Color.R = "00";
        oi.Color.G = "00";
        oi.Color.B = "00";
      elseif (faction == "Hidden_tgt") then
        oi.Color.R = "66";
        oi.Color.G = "66";
        oi.Color.B = "66";
      else
        oi.Color.R = "00";
        oi.Color.G = "00";
        oi.Color.B = "00";
      end
      -- check treasure.
      if (string.find(iesObj.ClassName, "treasure") ~= nil) then
        oi.IsBlink = 1;
      end
      -- check clover.
      local handle = actor:GetHandleVal();
      local buffCount = info.GetBuffCount(handle);
			for i = 0, buffCount - 1 do
				local buff = info.GetBuffIndexed(handle, i);
        local cls = GetClassByType("Buff", buff.buffID);
        if (cls.Icon == "clover") then
          --CHAT_SYSTEM(string.format("!!! clover !!! %d", buff.buffID));
          oi.IsBlink = 1;
        end
			end
    elseif (objType == GT_PC) then
      oi.Color.B = "99";
      oi.TooltipText = string.format("[Lv.%s]%s %s",
       actor:GetLv(), actor:GetName(), actor:GetPCApc():GetFamilyName());
    elseif (objType == GT_END) then
      oi.Color.G = "99";
      CHAT_SYSTEM("GT_END=>"..type(iesObj));
    elseif (objType == GT_ITEM) then
      oi.Color.R = "99";
      oi.Color.G = "99";
      oi.Color.B = "99";
      oi.TooltipText = string.format("[Lv.%s]%s",
       GET_ITEM_LEVEL(iesObj), actor:GetName());
    else
      -- CHAT_SYSTEM("unknown object type. => "..objType);
    end
    return oi;
  end
  -- update object state.
  members.UpdateObjectState = function(self, frame, parent, calculateAxis)
    local handle = frame:GetUserIValue("HANDLE");
    local actor = world.GetActor(handle);
    if (ObjectList[handle] == nil or actor:IsDead() == 1) then
      frame:ShowWindow(0);
      --ui.DestroyFrame(frame:GetName());
      return 1;
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
  -- clear output objects.
  members.Clear = function(self)
    DESTROY_CHILD_BYNAME(ui.GetFrame('map'), "icon_");
    DESTROY_CHILD_BYNAME(ui.GetFrame('minimap'), "icon_");
  end
  -- destroy.
  members.Destroy = function(self)
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(ObjectDetector, {__call = ObjectDetector.new});
-- frame initialize.
function OBJECTDETECTOR_ON_INIT(addon, frame)
  -- clear objects.
  obde:Clear();
  -- regist check object handler.
  addon:RegisterMsg('MAP_CHARACTER_UPDATE', 'DETECTOR_UPDATE');
  addon:RegisterMsg('FPS_UPDATE', 'DETECTOR_UPDATE');
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
