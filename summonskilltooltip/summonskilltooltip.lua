SummonSkillTooltip = {};

-- constructor.
function SummonSkillTooltip.new(self)
  -- initialize members.
  local members = {};

  members.SetTooltip = function(self, monName)
    local frame = ui.GetFrame("monsterquickslot");
    --CHAT_SYSTEM(monName);
		local monCls = GetClass("Monster", monName);
		local list = GetMonsterSkillList(monCls.ClassID);
		for i = 0, list:Count() - 1 do
			local sklName = list:Get(i);
      local sklCls = GetClass("Skill", sklName);
      if (sklCls == nil or sklCls.EngName ~= "plzInputEngName") then
        -- skip.
      else
        sklCls.Name = sklCls.ClassType.."-"..sklCls.AttackType;
        sklCls.EngName = sklCls.ClassName;
        sklCls.Caption = ClMsg("SkillPower").."="..sklCls.SklFactor.."%";
        sklCls.Caption2 = " ";
        local slot = GET_CHILD_RECURSIVELY(frame, "slot"..i+1, "ui::CSlot");
        tolua.cast(slot, "ui::CSlot");
        local icon = slot:GetIcon();
        icon:SetTooltipType('skill');
        icon:SetTooltipStrArg(sklCls.ClassName);
        icon:SetTooltipNumArg(sklCls.ClassID);
        --CHAT_SYSTEM(sklName.." - "..sklCls.ClassID)
      end
    end
  end

  -- destroy.
  members.Destroy = function(self)
    MONSTER_QUICKSLOT = sstp.MONSTER_QUICKSLOT;
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(SummonSkillTooltip, {__call = SummonSkillTooltip.new});

-- frame initialize.
function SUMMONSKILLTOOLTIP_ON_INIT(addon, frame)
  if (sstp.MONSTER_QUICKSLOT == nil) then
    sstp.MONSTER_QUICKSLOT = MONSTER_QUICKSLOT;
  end
  MONSTER_QUICKSLOT = function(isOn, monName, buffType, ableToUseSkill)
    sstp.MONSTER_QUICKSLOT(isOn, monName, buffType, ableToUseSkill);
    if (isOn ~= 1) then
      return;
    end
    sstp:SetTooltip(monName);
  end
end

-- create instance.
if (sstp ~= nil) then
  sstp:Destroy();
end
sstp = SummonSkillTooltip();
