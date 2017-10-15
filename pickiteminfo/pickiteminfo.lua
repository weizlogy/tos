PickItemInfo = {};

-- constructor.
function PickItemInfo.new(self)
  -- initialize members.
  local members = {};
  -- update.
  members.Update = function(self, frame, msg, str, handle)
    local list, count = SelectBaseObject(GetMyPCObject(), 300, "ALL");
    for i = 1 , count do
      local obj = list[i];
      local iesObj = GetBaseObjectIES(obj);
      local actor = tolua.cast(obj, "CFSMActor");
      local handle = actor:GetHandleVal();
      local objType = actor:GetObjType();
      if (objType == GT_ITEM) then
        self:ShowUI(handle, iesObj);
      end
    end
  end
  -- show pick item info.
  members.ShowUI = function(self, handle, iesObj)
    local itemframe = ui.GetFrame("monb_"..handle);
    if (itemframe == nil) then
      return;
    end

    local frameName = "pickiteminfo_" .. handle;
    local frame = ui.GetFrame(frameName);
    if (frame == nil) then
      frame = ui.CreateNewFrame("pickiteminfo", frameName, 0);
    end
    frame:SetLayerLevel(1);
    
    local itemNameText = frame:CreateOrGetControl(
      'richtext', "itemNameText", 0, 0, frame:GetWidth(), frame:GetHeight());
    itemNameText:SetText(string.format("{ol}{s14}{#%s}%s", self:GetItemRarityColor(iesObj), iesObj.Name));
    itemNameText:ShowWindow(1);

    frame:SetUserValue("_AT_OFFSET_HANDLE", handle);
    frame:SetUserValue("_AT_OFFSET_X", -frame:GetWidth() / 2);
    frame:SetUserValue("_AT_OFFSET_Y", 30);
    frame:SetUserValue("_AT_OFFSET_TYPE", 1);
    frame:SetUserValue("_AT_AUTODESTROY", 1);
  
    _FRAME_AUTOPOS(frame);
    frame:RunUpdateScript("_FRAME_AUTOPOS");

    frame:ShowWindow(1);
  end
  -- get item name color. by coloreditemnames.
  members.GetItemRarityColor = function(self, iesObj)
    if (iesObj.ItemClassName == "Vis") then
      return "FFFFFF";
    end
    local itemObj = GetClass("Item", iesObj.ClassName);
    local grade = itemObj.ItemGrade;
    if (itemObj.ItemType == "Recipe") then
      local recipeGrade = string.match(itemObj.Icon, "misc(%d)");
      if recipeGrade ~= nil then
        grade = tonumber(recipeGrade) - 1;
      end
    end
    local color = "FFFFFF";
    if (grade == 0) then
      color = "FFBF33";
    elseif (grade == 1) then
      color = "FFFFFF";
    elseif (grade == 2) then
      color = "108CFF";
    elseif (grade == 3) then
      color = "9F30FF";
    elseif (grade == 4) then
      color = "FF4F00";
    end
    return color;
  end
  -- destroy.
  members.Destroy = function(self)
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(PickItemInfo, {__call = PickItemInfo.new});

-- frame initialize.
function PICKITEMINFO_ON_INIT(addon, frame)
  -- regist check object handler.
  addon:RegisterMsg('MAP_CHARACTER_UPDATE', 'PICKITEMINFO_UPDATE');
  addon:RegisterMsg('FPS_UPDATE', 'PICKITEMINFO_UPDATE');
end

function PICKITEMINFO_UPDATE(frame, msg, str, handle)
  piin:Update(frame, msg, str, handle);
end

-- create instance.
if (piin ~= nil) then
  piin:Destroy();
end
piin = PickItemInfo();
