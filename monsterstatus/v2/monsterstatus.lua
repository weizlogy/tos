MonsterStatus = {}

-- constructor.
function MonsterStatus.new(self)
  -- initialize members.
  local members = {};
  members.X = -1;
  members.Y = -1;

  
  members.pathLoc = "../addons/monsterstatus/location.txt";

  members.server = GetServerNation();

  members.IsJpServer = function(self)
    return self.server == "JP";
  end

  members.LoadSettings = function(self)
    dofile(self.pathLoc)
    if (self.X ~= -1 and self.Y ~= -1) then
      return;
    end
    -- set frame position right to TargetWindow.
    local msframe = ui.GetFrame("monsterstatus");
    local frame = ui.GetFrame("channel");
    self.X = frame:GetX() - msframe:GetWidth() - 5;
    self.Y = frame:GetY();
  end

  members.SaveSettings = function(self)
    local frame = ui.GetFrame("monsterstatus");
    self.X = frame:GetX();
    self.Y = frame:GetY();
    
    local f, e = io.open(self.pathLoc, "w");
    if (f == nil) then
      return;
    end
    f:write(string.format("most.X = %d; most.Y = %d;", self.X, self.Y));
    f:flush();
    f:close();
  end

  members.Clear = function(self)
    ui.GetFrame("monsterstatus"):ShowWindow(0);
  end

  members.Update = function(self, handle)
    local monster = GetClass("Monster", info.GetMonsterClassName(handle));
    -- customize moster class.
    monster.Lv = info.GetLevel(handle);
    monster.STR = monster.STR_Rate;
    monster.CON = monster.CON_Rate;
    monster.INT = monster.INT_Rate;
    monster.MNA = monster.MNA_Rate;
    monster.DEX = monster.DEX_Rate;
    -- open my frame.
    local frame = ui.GetFrame("monsterstatus");
    frame:SetSkinName("downbox");
    frame:SetAlpha(50);
    frame:SetEventScript(ui.LBUTTONUP, "MONSTERSTATUS_END_DRAG");
    -- get monster status.
    local minatk = SCR_Get_MON_MAXPATK(monster);
    local maxatk = SCR_Get_MON_MAXMATK(monster);
    local def = SCR_Get_MON_DEF(monster);
    local mdef = SCR_Get_MON_MDEF(monster);
    local dr = SCR_Get_MON_DR(monster);
    local cdr = SCR_Get_MON_CRTDR(monster);
    local catk = SCR_Get_MON_CRTATK(monster);
    local cdef = SCR_Get_MON_CRTDEF(monster);
    -- set monster status.
    local format = "{s14}{ol}%s - %s / %s - %s";
    local atkCtrl = frame:CreateOrGetControl("richtext", "atk", 0, 5, frame:GetWidth(), 20);
    atkCtrl:SetText(string.format(format, 
      " ATK", self:LimitStatusValue(minatk), "MATK", self:LimitStatusValue(maxatk))
    );
    local defCtrl = frame:CreateOrGetControl("richtext", "def", 0, 25, frame:GetWidth(), 20);
    defCtrl:SetText(string.format(format, 
      " DEF", self:LimitStatusValue(def), "MDEF", self:LimitStatusValue(mdef))
    );
    local journals = self:GetJournals(monster);
    local kills = frame:CreateOrGetControl("richtext", "kills", 0, 50, frame:GetWidth(), 20);
    kills:SetText(string.format(
      "{s14}{ol} KILL %4d / %4d", journals.kills.count, journals.kills.max));
    local droptitle = frame:CreateOrGetControl("richtext", "droptitle", 0, 70, frame:GetWidth(), 20);
    droptitle:SetText("{s14}{ol} DROP -> ");
    DESTROY_CHILD_BYNAME(frame, "drop_");
    frame:Resize(frame:GetWidth(), droptitle:GetY() + droptitle:GetHeight() + 5);
    if (next(journals.drops)) then
      for i, item in ipairs(journals.drops) do
        -- 未鑑定品を除く！
        local needAppraisal = TryGetProp(item[1], "NeedAppraisal")
        if (needAppraisal ~= 0) then
          local drop = frame:CreateOrGetControl(
            "richtext", "drop_"..i, 10, curHeight + (ctrlHeight * i), frame:GetWidth(), ctrlHeight);
          drop:SetText(string.format("{s14}{ol}%s - %.2f %%", item[1].Name, item[2]));
          drop:SetTooltipType('wholeitem');
          drop:SetTooltipArg('', item[1].ClassID, 0);
          frame:Resize(frame:GetWidth(), drop:GetY() + drop:GetHeight() + 5);
        end
      end
    end

    frame:SetOffset(self.X, self.Y);
    frame:ShowWindow(1);
  end

  members.GetJournals = function(self, monster)
    local value = {
      kills = {
        count = 0,
        max = 0
      },
      drops = {}
    };
    -- get journal.
    local journal = GetClass('Journal_monkill_reward', monster.ClassName)
    if journal == nil then
      return value;
    end
    value.kills.max = journal.Count1;
    --[[
    if (self:IsJpServer()) then
      value = self:GetJournalsAtJpServer(monster, value);
    else
      value = self:GetJournalsAtNonJpServer(monster, value);
    end
    ]]
    value = self:GetJournalsAtNonJpServer(monster, value);
    return value;
  end

  members.GetJournalsAtJpServer = function(self, monster, value)
    -- get wiki.
    local wiki = GetWikiByName(monster.ClassName)
    if wiki == nil then
      return value;
    end
    value.kills.count = GetWikiIntProp(wiki, "KillCount");
    for i = 1, MAX_WIKI_ITEM_MON do
      local dropWikiPropValue, count = GetWikiProp(wiki, "DropItem_" .. i);
      if dropWikiPropValue == 0 then
        break;
      end
      local item = GetClassByType("Item", dropWikiPropValue);
      if item ~= nil then
        local pts = GET_ITEM_WIKI_PTS(item, wiki);
        local maxPts = GET_ITEM_MAX_WIKI_PTS(item, wiki);
        local ratio = math.floor(pts * 100 / maxPts);
        if maxPts <= 0 then
          ratio = 0;
        end
        table.insert(value.drops, {item, ratio});
      end
    end
    return value;
  end

  members.GetJournalsAtNonJpServer = function(self, monster, value)
    -- get kill count.
    value.kills.count = ADVENTURE_BOOK_MONSTER_CONTENT.MONSTER_KILL_COUNT(monster.ClassID);
    -- get drop item.
    local items = ADVENTURE_BOOK_MONSTER_CONTENT.MONSTER_DROP_ITEM(monster.ClassID);
    for i = 1, #items do
      local item = GetClassByType("Item", items[i]["item_id"])
      if item ~= nil then
        local itemObtainCount = GetItemObtainCount(pc, item.ClassID);
        local curPoint = _GET_ADVENTURE_BOOK_POINT_ITEM(item.ItemType == 'Equip', itemObtainCount);
        local pts = itemObtainCount;
        local maxPts = curPoint;
        local ratio = math.floor(pts * 100 / maxPts);
        if maxPts <= 0 then
          ratio = 0;
        end
        table.insert(value.drops, {item, ratio});
      end
    end
    return value;
  end

  members.LimitStatusValue = function(self, value)
    if (value > 9999) then
      return "----"
    end
    return string.format("%4d", value);
  end

  members.Destroy = function(self)
    self.X = -1;
    self.Y = -1;
  end
  return setmetatable(members, {__index = self});
end

-- set call.
setmetatable(MonsterStatus, {__call = MonsterStatus.new});

-- target off handler.
function CLEAR_MONSTER_STATUS_FRAME()
  most:Clear();
end

-- update monster status handler.
function UPDATE_MONSTER_STATUS_FRAME(frame, msg, argStr, argNum)
  -- maybe it's a not monster.
  if argStr == "None" or argNum == nil then
		return;
	end
  most:Update(session.GetTargetHandle());
end

--
function MONSTERSTATUS_END_DRAG()
  most:SaveSettings();
end

-- initialize frame.
function MONSTERSTATUS_ON_INIT(addon, frame)
  -- instance load settings.
  most:LoadSettings();
  -- for normal monsters.
	addon:RegisterMsg('TARGET_SET', 'UPDATE_MONSTER_STATUS_FRAME');
	addon:RegisterMsg('TARGET_CLEAR', 'CLEAR_MONSTER_STATUS_FRAME');
	addon:RegisterMsg('TARGET_UPDATE', 'UPDATE_MONSTER_STATUS_FRAME');
  -- for bosses.
	addon:RegisterMsg('TARGET_SET_BOSS', 'UPDATE_MONSTER_STATUS_FRAME');
	addon:RegisterMsg('TARGET_CLEAR_BOSS', 'CLEAR_MONSTER_STATUS_FRAME');
end

if (most ~= nil) then
  most:Destroy();
end
most = MonsterStatus();