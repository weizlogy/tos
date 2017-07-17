MonsterStatus = {}

-- constructor.
function MonsterStatus.new(self)
  -- initialize members.
  local members = {};
  members.X = -1;
  members.Y = -1;
  members.ArmorCompatibleMap = {
    None_Cloth = 1.00,
    None_Leather = 1.00,
    None_Iron = 1.00,
    None_Ghost = -0.5,
    Slash_Cloth = 1.25,
    Slash_Leather = 1.00,
    Slash_Iron = 1.00,
    Slash_Ghost = 1.00,
    Piece_Cloth = 1.00,
    Piece_Leather = 1.25,
    Piece_Iron = 1.00,
    Piece_Ghost = 1.00,
    Strike_Cloth = 1.00,
    Strike_Leather = 1.00,
    Strike_Iron = 1.25,
    Strike_Ghost = 1.00,
    Arrow_Cloth = 1.125,
    Arrow_Leather = 1.125,
    Arrow_Iron = 1.00,
    Arrow_Ghost = 1.00,
    Gun_Cloth = 1.125,
    Gun_Leather = 1.125,
    Gun_Iron = 1.00,
    Gun_Ghost = 1.00,
    Cannon_Cloth = 1.00,
    Cannon_Leather = 1.00,
    Cannon_Iron = 1.25,
    Cannon_Ghost = 1.00,
    Magic_Cloth = 1.00,
    Magic_Leather = 1.00,
    Magic_Iron = 1.00,
    Magic_Ghost = 1.25,
  }
  -- 
  members.LoadSettings = function(self)
    if (self.X ~= -1 and self.Y ~= -1) then
      return;
    end
    -- set frame position right to TargetWindow.
    local msframe = ui.GetFrame("monsterstatus");
    local frame = ui.GetFrame("channel");
    self.X = frame:GetX() - msframe:GetWidth() - 5;
    self.Y = frame:GetY();
  end
  -- 
  members.SaveSettings = function(self)
    local frame = ui.GetFrame("monsterstatus");
    self.X = frame:GetX();
    self.Y = frame:GetY();
  end
  -- 
  members.Clear = function(self)
    ui.GetFrame("monsterstatus"):ShowWindow(0);
  end
  --
  members.CalculateDamage = function(self, min, max, def, weapon, armor, crit)
    local calclator = function(atk, sm, am, ac, ec, def)
      return atk * sm * am * ac * ec * 
        math.min(1, math.log10((atk / (def + 1)) ^ 0.9 + 1));
    end
    local skillmag = 1.00;
    local atriimag = 1.00;
    local armcompati = self.ArmorCompatibleMap[weapon.."_"..armor];
    local elecompati = 1;
    local mindmg = calclator(min, skillmag, atriimag, armcompati, elecompati, def);
    local maxdmg = calclator(max, skillmag, atriimag, armcompati, elecompati, def);
    local mincrdmg = 0;
    local maxcrdmg = 0;
    if (crit ~= nil) then
      local critmag = 1.50;
      mincrdmg = calclator(min * critmag + crit, skillmag, atriimag, armcompati, elecompati, def);
      maxcrdmg = calclator(max * critmag + crit, skillmag, atriimag, armcompati, elecompati, def);
    end
    return mindmg, maxdmg, mincrdmg, maxcrdmg;
  end
  --
  members.CalculateCritProb = function(self, crit, critdef)
    return math.max(0, crit - critdef) * 0.6;
  end
  -- 
  members.Update = function(self, handle)
    local monster = GetClass("Monster", info.GetMonsterClassName(handle));
    -- customize moster class.
    monster.Lv = monster.Level;
    monster.STR = GET_MON_STAT(monster, monster.Lv, "STR");
    monster.CON = GET_MON_STAT(monster, monster.Lv, "CON");
    monster.INT = GET_MON_STAT(monster, monster.Lv, "INT");
    monster.MNA = GET_MON_STAT(monster, monster.Lv, "MNA");
    monster.DEX = GET_MON_STAT(monster, monster.Lv, "DEX");
    -- open my frame.
    local frame = ui.GetFrame("monsterstatus");
    frame:SetSkinName("downbox");
    frame:SetEventScript(ui.LBUTTONUP, "MONSTERSTATUS_END_DRAG");
    frame:ShowWindow(1);
    frame:SetAlpha(50);
    -- get monster status.
    local minatk = SCR_Get_MON_MAXPATK(monster);
    local maxatk = SCR_Get_MON_MAXMATK(monster);

    local minpatk = SCR_Get_MON_MINPATK(monster);
    local maxpatk = SCR_Get_MON_MAXMATK(monster);
    local minmatk = SCR_Get_MON_MINMATK(monster);
    local maxmatk = SCR_Get_MON_MAXMATK(monster);
    local def = SCR_Get_MON_DEF(monster);
    local mdef = SCR_Get_MON_MDEF(monster);
    local dr = SCR_Get_MON_DR(monster);
    local chr = SCR_Get_MON_CRTHR(monster);
    local cdr = SCR_Get_MON_CRTDR(monster);
    local catk = SCR_Get_MON_CRTATK(monster);
    local cdef = SCR_Get_MON_CRTDEF(monster);
    local exp = SCR_GET_MON_EXP(monster);
    local jobexp = SCR_GET_MON_JOBEXP(monster);

    -- Attack, Attack1, Skill, Skill1 ?
    -- that's too bad.
    local skill = GetClass("Skill", "Mon_"..monster.ClassName.."_Attack");
    if (skill == nil) then
      skill = GetClass("Skill", "Mon_"..monster.ClassName.."_Attack_1");
    end
    if (skill == nil) then
      skill = GetClass("Skill", "Mon_"..monster.ClassName.."_Skill");
    end
    if (skill == nil) then
      skill = GetClass("Skill", "Mon_"..monster.ClassName.."_Skill_1");
    end
    if (skill == nil) then
      skill = {AttackType = "None"};
    end

    local weapon = skill.AttackType;
    if (weapon == "Aries") then
      if (skill.ClassType == "Missile") then
        weapon = "Arrow";
      elseif (skill.ClassType == "Melle") then
        weapon = "None";
      elseif (skill.ClassType == "Magic") then
        weapon = "Magic";
      end
    end
    local armor = monster.ArmorMaterial;
    local element = monster.Attribute;

    -- get charactor status.
    local pc = GetMyPCObject();
    local myminpatk = SCR_Get_MINPATK(pc);
    local mymaxpatk = SCR_Get_MAXPATK(pc);
    local myminmatk = SCR_Get_MINMATK(pc);
    local mymaxmatk = SCR_Get_MAXMATK(pc);
    local mydef = SCR_Get_DEF(pc);
    local mymdef = SCR_Get_MDEF(pc);
    local mycatk = SCR_Get_CRTATK(pc);
    local mychr = SCR_Get_CRTHR(pc);
    local mycdr = SCR_Get_CRTDR(pc);
    local myweapon = GetEquipItemForPropCalc(pc, 'RH').AttackType;
    local myarmor = GetEquipItemForPropCalc(pc, 'SHIRT').Material;
    local myelement = "None";

    -- calc real value.
    local tkminpdmg, tkmaxpdmg, tkmincpdmg, tkmaxcpdmg =
     self:CalculateDamage(myminpatk, mymaxpatk, def, myweapon, armor, mycatk);
    local tkminmdmg, tkmaxmdmg =
     self:CalculateDamage(myminmatk, mymaxmatk, mdef, "Magic", armor);
    local tkcritprob = self:CalculateCritProb(mychr, cdr);

--[[
    local gvminpdmg, gvmaxpdmg, gvmincpdmg, gvmaxcpdmg =
     self:CalculateDamage(minpatk, maxpatk, mydef, weapon, myarmor, catk);
    local gvminmdmg, gvmaxmdmg =
     self:CalculateDamage(minmatk, maxmatk, mymdef, "Magic", myarmor);
    local gvcritprob = self:CalculateCritProb(chr, mycdr);
]]

    -- set monster status.
    local ctrlHeight = 20;
    local bufHeight = 5;
    local curHeight = bufHeight;
    local font = "{s14}{ol}";
    local format = font.."%s - %s / %s - %s";
    local atkCtrl = frame:CreateOrGetControl("richtext", "atk", 0, curHeight, frame:GetWidth(), ctrlHeight);
    atkCtrl:SetText(string.format(
      font.." PC => MOM Damage{nl}   Phis %d - %d{nl}   (Cr) %d - %d -> %.2f %%{nl}   Magi %d - %d",
       tkminpdmg, tkmaxpdmg, tkmincpdmg, tkmaxcpdmg, tkcritprob, tkminmdmg, tkmaxmdmg));
    curHeight = curHeight + atkCtrl:GetHeight();

-- do not work in ID.
--[[
    local defCtrl = frame:CreateOrGetControl("richtext", "def", 0, curHeight, frame:GetWidth(), ctrlHeight);
    defCtrl:SetText(string.format(
      font.." MOM => PC{nl}   P %d - %d{nl}     %d - %d -> %.2f %%{nl}   M %d - %d",
     gvminpdmg, gvmaxpdmg, gvmincpdmg, gvmaxcpdmg, gvcritprob, gvminmdmg, gvmaxmdmg));
    curHeight = curHeight + defCtrl:GetHeight();
]]
    curHeight = curHeight + bufHeight;
    local etcCtrl = frame:CreateOrGetControl("richtext", "etc", 0, curHeight, frame:GetWidth(), ctrlHeight);
    etcCtrl:SetText(string.format(font.." EXPs{nl}   Char %d / Class %d", exp, jobexp));
    curHeight = curHeight + etcCtrl:GetHeight();

    -- set type.
    curHeight = curHeight + bufHeight;
    local typeCtrl = frame:CreateOrGetControl("richtext", "type", 0, curHeight, frame:GetWidth(), ctrlHeight);
    typeCtrl:SetText(string.format(
      font.."%s{nl}   %s - %s - %s", " TYPE", ClMsg(monster.RaceType), monster.Attribute, monster.MoveType));
    curHeight = curHeight + typeCtrl:GetHeight();

    -- set numerology.
    --[[
    curHeight = curHeight + bufHeight;
    local numero = self:GetNumerology(monster.SET);
    local numeroCtrl = frame:CreateOrGetControl(
      "richtext", "numero", 0, curHeight, frame:GetWidth(), ctrlHeight);
    numeroCtrl:SetText(string.format(
      "{s14}{ol} NUMEROLOGY{nl}   GEMA - %d / NOTA - %d", numero.gema, numero.nota));
    curHeight = curHeight + numeroCtrl:GetHeight();
    ]]

    -- set journals.
    curHeight = curHeight + bufHeight;
    local journals = self:GetJournals(monster);
    local kills = frame:CreateOrGetControl("richtext", "kills", 0, curHeight, frame:GetWidth(), ctrlHeight);
    if (journals.kills.max == 0) then
      kills:SetText("");
    elseif (journals.kills.count >= journals.kills.max) then
      kills:SetText(string.format(
        "{s14}{ol} KILL{nl}   %d", journals.kills.count));
    else
      kills:SetText(string.format(
        "{s14}{ol} KILL{nl}   %d / %d", journals.kills.count, journals.kills.max));
    end
    curHeight = curHeight + kills:GetHeight();

    local droptitle = frame:CreateOrGetControl("richtext", "droptitle", 0, curHeight, frame:GetWidth(), ctrlHeight);
    droptitle:SetText("{s14}{ol} DROP ");
    DESTROY_CHILD_BYNAME(frame, "drop_");
    frame:Resize(frame:GetWidth(), droptitle:GetY() + droptitle:GetHeight() + 5);
    for i, item in ipairs(journals.drops) do
      local drop = frame:CreateOrGetControl(
        "richtext", "drop_"..i, 10, curHeight + (ctrlHeight * i), frame:GetWidth(), ctrlHeight);
      drop:SetText(string.format("{s14}{ol}%s - %.2f %%", item[1].Name, item[2]));
			drop:SetTooltipType('wholeitem');
			drop:SetTooltipArg('', item[1].ClassID, 0);
      frame:Resize(frame:GetWidth(), drop:GetY() + drop:GetHeight() + 5);
    end

    frame:SetOffset(self.X, self.Y);
  end
  -- 
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
  -- 
  members.LimitStatusValue = function(self, value)
    if (value > 9999) then
      return "----"
    end
    return string.format("%4d", value);
  end
  --
  members.GetNumerology = function(self, name)
    local result = {
      gema = 0, nota = 0
    };
    for i, v in pairs({name:byte(1, name:len())}) do
      result.gema = result.gema + v;
      if (i == 1 or i == name:len()) then
        result.nota = result.nota + v;
      end
    end
    result.gema = string.sub(tostring(result.gema), -1);
    result.nota = string.sub(tostring(result.nota), -1);
    return result;
  end
  -- 
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
