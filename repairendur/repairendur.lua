RepairEndur = {};
-- constructor.
function RepairEndur.new(self)
  -- initialize members.
  local members = {};
  -- L:Low, M:Middle, H:High.
  members.Weapon = {
    Lp = 30,
    Mp = 5,
    Hp = 1
  };
  members.Armor = {
    Lp = 35,
    Mp = 10,
    Hp = 5
  };
  members.SubWeapon = members.Weapon;
  members.EndurColor = {
    Lc = "FFFF00",
    Mc = "FF0000",
    Hc = "000000"
  };
  -- main logic.
  members.InsertEndur = function(self, frame)
    -- get slotset recursively.
  	local slotSet = GET_CHILD_RECURSIVELY_AT_TOP(frame, "slotlist", "ui::CSlotSet");
    -- loop number of slot.
    local slotCount = slotSet:GetSlotCount();
    for i = 0, slotCount - 1 do
      local slot = slotSet:GetSlotByIndex(i);
      local icon = slot:GetIcon();
      if (icon ~= nil) then
        local iconInfo = icon:GetInfo();
        local invitem = GET_ITEM_BY_GUID(iconInfo:GetIESID());
        local itemobj = GetIES(invitem:GetObject());
        -- get item endurance parcentage.
        local durPc = itemobj.Dur * 100 / itemobj.MaxDur;
        -- create text.
        local durText = "{s14}{ol}"..string.format("%2.2f", durPc).."%";
        local durByColor = self:getDurColorByItemGroup(durPc, itemobj);
        -- display text.
        local durObj = slot:CreateOrGetControl("richtext", "dur_"..i, 0, 0, 10, 10);
        durObj:EnableHitTest(0);
        durObj:SetText("{#"..durByColor.."}"..durText);
        durObj:Resize(47, 14);
        durObj:Move(slot:GetWidth() - durObj:GetWidth(), slot:GetHeight() - durObj:GetHeight());
      else
        slot:RemoveChild("dur_"..i);
      end
    end
  end
  members.getDurColorByItemGroup = function(self, durPc, itemobj)
    -- default value.
    local durByColor = "FFFFFF";
    local threshold = self.Weapon;
    -- check item group.
    local group = itemobj.GroupName;
    local equipGroup = itemobj.EquipGroup;
    if (group == "Armor") then
      threshold = self.Armor;
    end
    if (equipGroup == "SubWeapon") then
      -- exists combination in item.ies =>
      --  (GroupName x EquipGroup) Armor x SW, SW x SW, Weapon x SW
      threshold = self.SubWeapon;
    end
    -- select color.
    if (durPc <= threshold.Hp) then
      durByColor = self.EndurColor.Hc;
    elseif (durPc <= threshold.Mp) then
      durByColor = self.EndurColor.Mc;
    elseif (durPc <= threshold.Lp) then
      durByColor = self.EndurColor.Lc;
    end
    return durByColor;
  end
  members.Destroy = function(self)
    UPDATE_REPAIR140731_LIST = self.UPDATE_REPAIR140731_LIST;
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(RepairEndur, {__call = RepairEndur.new});
-- frame initialize.
function REPAIRENDUR_ON_INIT(addon, frame)
  -- load settings.
  dofile("../addons/repairendur/settings.txt");
  -- override system function.
  if (reen.UPDATE_REPAIR140731_LIST == nil) then
    reen.UPDATE_REPAIR140731_LIST = UPDATE_REPAIR140731_LIST;
  end
  UPDATE_REPAIR140731_LIST = function(frame)
    reen.UPDATE_REPAIR140731_LIST(frame);
    reen:InsertEndur(frame);
  end
end
-- create instance.
if (reen ~= nil) then
  reen:Destroy();
end
reen = RepairEndur();
