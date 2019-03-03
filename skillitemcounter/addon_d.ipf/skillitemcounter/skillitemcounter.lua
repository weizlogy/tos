-- 領域定義
local author = 'weizlogy'
local addonName = 'skillitemcounter'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)

  -- initialize members.
  local members = {};

  members.Refresh = function(self, frame, index, skill, invItem)
		local slot = GET_CHILD_RECURSIVELY(frame, "slot"..(index + 1), "ui::CSlot");
    local skillUseCount = slot:CreateOrGetControl('richtext', "skillUseCount", 0, 0, 20, 10);
    tolua.cast(skillUseCount, "ui::CRichText");
    local itemCount = invItem.count;

    local skillCost = SCR_GET_SPENDITEM_COUNT(skill);
    local skillName = string.match(skill.ClassName, '^.-%_(.+)')
    local skillNameEsp = _G['SCR_GET_SPENDITEM_COUNT_'..skillName]
    if (type(skillNameEsp) ~= 'nil') then
      skillCost = skillNameEsp(skill)
    end

    self:Dbg(skillName..' '..itemCount..' '..skill.SpendItemBaseCount..' '..skill.SpendItemCount)

    skillUseCount:SetText("{ol}{s12}"..math.floor(itemCount / skillCost));
    skillUseCount:SetOffset(slot:GetWidth() - skillUseCount:GetWidth(), 0);
  end

  members.RefreshPoison = function(self, frame, index, skillCost, itemCount)
		local slot = GET_CHILD_RECURSIVELY(frame, "slot"..(index + 1), "ui::CSlot");
    local skillUseCount = slot:CreateOrGetControl('richtext', "skillUseCount", 0, 0, 20, 10);
    tolua.cast(skillUseCount, "ui::CRichText");
    skillUseCount:SetText("{ol}{s12}"..math.floor(itemCount / skillCost));
    skillUseCount:SetOffset(slot:GetWidth() - skillUseCount:GetWidth(), 0);
  end

  -- ログ出力
  members.Dbg = function(self, msg)
    -- CHAT_SYSTEM(string.format('[%s] <Dbg> %s', addonName, msg))
  end
  members.Log = function(self, msg)
    CHAT_SYSTEM(string.format('[%s] <Log> %s', addonName, msg))
  end
  members.Err = function(self, msg)
    CHAT_SYSTEM(string.format('[%s] <Err> %s', addonName, msg))
  end

  members.Destroy = function(self)
    QUICKSLOTNEXPBAR_ON_DROP = g.instance.QUICKSLOTNEXPBAR_ON_DROP;
    g.instance.QUICKSLOTNEXPBAR_ON_DROP = nil;
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(g, {__call = g.new})

-- frame initialize.
function SKILLITEMCOUNTER_ON_INIT(addon, frame)
  if (g.instance.QUICKSLOTNEXPBAR_ON_DROP == nil) then
    g.instance.QUICKSLOTNEXPBAR_ON_DROP = QUICKSLOTNEXPBAR_ON_DROP;
  end
  QUICKSLOTNEXPBAR_ON_DROP = function(frame, control, argStr, argNum)
    g.instance.QUICKSLOTNEXPBAR_ON_DROP(frame, control, argStr, argNum);
    SKILLITEMCOUNTER_REFRESH_KICKER();
  end
  addon:RegisterMsg('GAME_START_3SEC', 'SKILLITEMCOUNTER_REFRESH');
	addon:RegisterMsg('INV_ITEM_CHANGE_COUNT', 'SKILLITEMCOUNTER_REFRESH');
end

-- refresh.
function SKILLITEMCOUNTER_REFRESH(frame, msg, argStr, argNum)
  DebounceScript("SKILLITEMCOUNTER_REFRESH_KICKER", 0.1);
end

function SKILLITEMCOUNTER_REFRESH_KICKER()
  SKILLITEMCOUNTER_REFRESH_COUNTER(ui.GetFrame('quickslotnexpbar'))
  SKILLITEMCOUNTER_REFRESH_COUNTER(ui.GetFrame('joystickquickslot'))
end

--
function SKILLITEMCOUNTER_REFRESH_COUNTER(frame)
  for i = 0, MAX_QUICKSLOT_CNT - 1 do
    local quickSlotInfo = quickslot.GetInfoByIndex(i)
    if (quickSlotInfo.category == 'Skill') then
      local skl = GetClassByType("Skill", quickSlotInfo.type);
      local skillitem = skl.SpendItem;
      if (skillitem ~= "None") then
        local invenItemInfo = session.GetInvItemByName(skillitem);
        g.instance:Refresh(frame, i, skl, invenItemInfo);
      end
      local skillPoison = SCR_Get_SpendPoison(skl);
      if (skillPoison ~= 0) then
        local etc = GetMyEtcObject();
        g.instance:RefreshPoison(frame, i, skillPoison, etc.Wugushi_PoisonAmount);
      end
    else
      local slot = GET_CHILD_RECURSIVELY(frame, "slot"..(i + 1), "ui::CSlot");
      DESTROY_CHILD_BYNAME(slot, "skillUseCount");
    end
  end
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy()
end
g.instance = g()
