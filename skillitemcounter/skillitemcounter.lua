SkillItemCounter = {};

-- constructor.
function SkillItemCounter.new(self)
  -- initialize members.
  local members = {};
  members.Refresh = function(self, frame, index, skill, invItem)
		local slot = GET_CHILD_RECURSIVELY(frame, "slot"..(index + 1), "ui::CSlot");
    local skillUseCount = slot:CreateOrGetControl('richtext', "skillUseCount", 0, 0, 20, 10);
    tolua.cast(skillUseCount, "ui::CRichText");
    local itemCount = invItem.count;
    local skillCost = skill.SpendItemBaseCount + skill.SpendItemCount;
    skillUseCount:SetText("{ol}{s12}"..math.floor(itemCount / skillCost));
    skillUseCount:SetOffset(slot:GetWidth() - skillUseCount:GetWidth(), 0);
  end
  members.Destroy = function(self)
    QUICKSLOTNEXPBAR_ON_DROP = skic.QUICKSLOTNEXPBAR_ON_DROP;
    skic.QUICKSLOTNEXPBAR_ON_DROP = nil;
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(SkillItemCounter, {__call = SkillItemCounter.new});
-- frame initialize.
function SKILLITEMCOUNTER_ON_INIT(addon, frame)
  if (skic.QUICKSLOTNEXPBAR_ON_DROP == nil) then
    skic.QUICKSLOTNEXPBAR_ON_DROP = QUICKSLOTNEXPBAR_ON_DROP;
  end
  QUICKSLOTNEXPBAR_ON_DROP = function(frame, control, argStr, argNum)
    skic.QUICKSLOTNEXPBAR_ON_DROP(frame, control, argStr, argNum);
    SKILLITEMCOUNTER_REFRESH_COUNTER();
  end
  SKILLITEMCOUNTER_REFRESH_COUNTER();
	addon:RegisterMsg('INV_ITEM_CHANGE_COUNT', 'SKILLITEMCOUNTER_REFRESH');
end
-- refresh.
function SKILLITEMCOUNTER_REFRESH(frame, msg, argStr, argNum)
  DebounceScript("SKILLITEMCOUNTER_REFRESH_COUNTER", 0.1);
end
--
function SKILLITEMCOUNTER_REFRESH_COUNTER()
  local frame = ui.GetFrame('quickslotnexpbar');
  local quickSlotList = session.GetQuickSlotList();
  for i = 0, MAX_QUICKSLOT_CNT - 1 do
    local quickSlotInfo = quickSlotList:Element(i);		
    if (quickSlotInfo.category == 'Skill') then
      local skl = GetClassByType("Skill", quickSlotInfo.type);
      local skillitem = skl.SpendItem;
      if (skillitem ~= "None") then
        local invenItemInfo = session.GetInvItemByName(skillitem);
        skic:Refresh(frame, i, skl, invenItemInfo);
      end
    else
      local slot = GET_CHILD_RECURSIVELY(frame, "slot"..(i + 1), "ui::CSlot");
      DESTROY_CHILD_BYNAME(slot, "skillUseCount");
    end
  end
end

--
if (skic ~= nil) then
  skic:Destroy();
end
-- create instance.
skic = SkillItemCounter();
