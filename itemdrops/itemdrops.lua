-- todo:
-- timer until someone else' (grayed out) item becomes available to everyone
-- find out why drops are sometimes not detected
-- custom sounds by rarity upon drop
-- separate settings for other people's drops
-- custom frame to customize settings

-- use with https://github.com/TehSeph/tos-addons "Colored Item Names" for colored drop nametags

local addonName = "ITEMDROPS";

_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['MIEI'] = _G['ADDONS']['MIEI'] or {}
_G['ADDONS']['MIEI'][addonName] = _G['ADDONS']['MIEI'][addonName] or {};
local g = _G['ADDONS']['MIEI'][addonName];
--local acutil = require('acutil');

if not g.loaded then
	g.settings = {
		showGrade = false;				-- show item grade as text in the drop msg?
		showGroupName = false;			-- show item group name (e.g. "Recipe") in the drop msg?
		msgFilterGrade = "rare";		-- only show messages for items of this grade and above, "common" applies msgs to all objects, "off" means msgs will be off
		effectFilterGrade = "common";	-- only draw effects for items of this grade and above, , "common" applies effects to all objects, "off" means effects will be off
		nameTagFilterGrade = "common";	-- only display name tag (as if you were pressing alt) for items of this grade and above, "common" applies to all objects, "off" means name tags will be off
		alwaysShowXPCards = false;			-- always show effects and msgs for exp cards
		alwaysShowMonGems = true;			-- always show effects and msgs for monster gems
		alwaysShowCubes = true;
		showSilverNameTag = false;		-- item name tags for silver drops
		onlyMeOrParty = true;
		showPartyDrops = true;
	}

	g.itemGrades = {
		"common",	 	-- white item
		"rare", 		-- blue item
		"epic", 		-- purple item
		"legendary", 	-- orange item
		"set",			-- set piece
	};

	--F_light080_blue_loop
	--F_cleric_MagnusExorcismus_shot_burstup
	--F_magic_prison_line

	g.settings.effects ={
		["common"] = {
			name = "F_magic_prison_line_white";
			scale = 6;
		};

		["rare"] = {
			name = "F_magic_prison_line_blue";
			scale = 6;
		};

		["epic"] = {
			name = "F_magic_prison_line_dark";
			scale = 6;
		};

		["legendary"] = {
			name = "F_magic_prison_line_red";
			scale = 6;
		};
		["set"] = {
			name = "F_magic_prison_line_green";
			scale = 6;
		};
	}
end

g.settingsComment = [[%s
 Item Drops by Miei, settings file
 http://github.com/Miei/TOS-lua

showGrade			- show item grade as text in the drop msg?
showGroupName		- show item group name (e.g. "Recipe") in the drop msg?

msgFilterGrade		- only show messages for items of this grade and above, "common" applies msgs to all objects, "off" means msgs will be off
effectFilterGrade	- accepts "common", "rare", "epic", "legendary", "set", "off"
nameTagFilterGrade	- same as above two options but for name tags under items

alwaysShowXPCards		- always show effects and msgs for exp cards
alwaysShowMonGems		- always show effects and msgs for monster gems

showSilverNameTag	- item name tags for silver drops

onlyMeOrParty 		- false will display drops from other people
showPartyDrops		- true will display drops from your party members, showPartyDrops is not required

%s

]];

g.settingsComment = string.format(g.settingsComment, "--[[", "]]");
g.settingsFileLoc = "../addons/itemdrops/settings.txt";
g.UI_CHAT = nil;

function ITEMDROPS_3SEC()
	local g = _G["ADDONS"]["MIEI"]["ITEMDROPS"];
	--local acutil = require('acutil');

	-- register chat commands.
	--acutil.slashCommand('/drops', g.processCommand)
	if (g.UI_CHAT == nil) then
    g.UI_CHAT = UI_CHAT;
  end
  UI_CHAT = function(msg)
		if (string.find(msg, "/drops ", 1, true) == 1) then
			local words = {};
			msg = string.gsub(msg, "/drops", "");
			for m in string.gmatch(msg, "%a+") do
				table.insert(words, m);
			end
			g.processCommand(words);
			return;
		end
    g.UI_CHAT(msg);
  end
	g.addon:RegisterMsg("MON_ENTER_SCENE", "ITEMDROPS_ON_MON_ENTER_SCENE")

	if not g.loaded then
	  --[[
		local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
		if err then
			acutil.saveJSON(g.settingsFileLoc, g.settings);
		else
			g.settings = t;
		end
		]]
		dofile(g.settingsFileLoc);
		CHAT_SYSTEM('[itemDrops:help] /drops');
		g.loaded = true;
	end
	g.myAID = session.loginInfo.GetAID();
end

function ITEMDROPS_ON_MON_ENTER_SCENE(frame, msg, str, handle)
	local g = _G['ADDONS']['MIEI']['ITEMDROPS'];

	local actor = world.GetActor(handle);
	if actor:GetObjType() == GT_ITEM then

		local selectedObjects, selectedObjectsCount = SelectObject(GetMyPCObject(), 100000, 'ALL');
		for i = 1, selectedObjectsCount do
			if GetHandle(selectedObjects[i]) == handle then
				local dropOwner = actor:GetUniqueName();
				local drawStuff = false;
				local ownerName = 'Someone';

				if g.settings.onlyMeOrParty ~= true then 
					drawStuff = true; 
				end

				if g.settings.showPartyDrops == true then
					local memberInfo = session.party.GetPartyMemberInfoByAID(PARTY_NORMAL, dropOwner);
					if nil ~= memberInfo then
						drawStuff = true;

						ownerName = memberInfo:GetName();
					end
				end

				if dropOwner == g.myAID then 
					drawStuff = true; 
					ownerName = 'You'; 
				end

				if drawStuff == true then
					local itemObj = GetClass("Item", selectedObjects[i].ClassName);
					local itemName = actor:GetName();
					local itemGrade = nil;
					local groupName = nil;
					local alwaysShow = false;

					if itemObj ~= nil then
						groupName = itemObj.GroupName;
						itemGrade = itemObj.ItemGrade;
						itemName = GET_FULL_NAME(itemObj);
						itemIcon = tostring(itemObj.Icon);

						local itemProp = geItemTable.GetProp(itemObj.ClassID);
						if groupName == "Recipe" then
							itemGrade = itemObj.Icon:match("misc(%d)")-1;
						elseif itemIcon:match("gem_mon") and g.settings.alwaysShowMonGems == true then
							alwaysShow = true;
						elseif itemIcon:match("item_expcard") and g.settings.alwaysShowXPCards == true then
							alwaysShow = true;
						elseif itemIcon:match("item_cube") and g.settings.alwaysShowCubes == true then
							alwaysShow = true;
						end

						if itemProp.setInfo ~= nil then 
							itemGrade = 5;
						elseif tostring(itemGrade) == "None" then
							itemGrade = 1;
						end
					end

					if itemObj == nil or alwaysShow == true or g.showOrNot(g.settings.nameTagFilterGrade, itemGrade) == true then
						if itemObj == nil and g.settings.showSilverNameTag ~= true then return end
						g.drawItemFrame(handle, itemName);
					end

					if itemObj ~= nil then

						local itemGradeMsg = g.itemGrades[itemGrade];

						if alwaysShow == true or g.showOrNot(g.settings.effectFilterGrade, itemGrade) == true then
							local effect = g.settings.effects[itemGradeMsg];
							-- delay to allow the actor to finish it's falling animation..
							ReserveScript(string.format('pcall(effect.AddActorEffectByOffset(world.GetActor(%d) or 0, "%s", %d, 0))', handle, effect.name, effect.scale), 0.7);
						end

						if alwaysShow == true or g.showOrNot(g.settings.msgFilterGrade, itemGrade) == true then
							groupNameMsg = " " .. groupName:lower();
							if g.settings.showGroupName ~= true then
								groupNameMsg = '';
							end
							
							local itemGradeMsg = " " .. itemGradeMsg;
							if g.settings.showGrade ~= true then
								itemGradeMsg = '';
							end

							CHAT_SYSTEM(string.format("%s dropped%s%s %s", ownerName, itemGradeMsg, groupNameMsg, g.linkitem(itemObj)));
						end
					end
				end
			end
		end	
	end
end

function g.showOrNot(setting, itemGrade)
	local filterGradeIndex = g.indexOf(g.itemGrades, setting);
	if filterGradeIndex == nil then
		if setting ~= "off" then
			CHAT_SYSTEM("[itemDrops] invalid filter grade: " .. setting);
		end
		return false;
	elseif filterGradeIndex <= itemGrade then
		return true;
	end
end

function g.drawItemFrame(handle, itemName)
	local itemFrame = ui.CreateNewFrame("itembaseinfo", "itembaseinfo_" .. handle);
	--
	local nameRichText = GET_CHILD(itemFrame, "name", "ui::CRichText");
	nameRichText:SetText(itemName);

	itemFrame:SetUserValue("_AT_OFFSET_HANDLE", handle);
	itemFrame:SetUserValue("_AT_OFFSET_X", -itemFrame:GetWidth() / 2);
	itemFrame:SetUserValue("_AT_OFFSET_Y", 3);
	itemFrame:SetUserValue("_AT_OFFSET_TYPE", 1);
	itemFrame:SetUserValue("_AT_AUTODESTROY", 1);

	-- makes frame blurry, see FRAME_AUTO_POS_TO_OBJ function
	--AUTO_CAST(itemFrame);
	--itemFrame:SetFloatPosFrame(true);

	_FRAME_AUTOPOS(itemFrame);
	itemFrame:RunUpdateScript("_FRAME_AUTOPOS");

	itemFrame:ShowWindow(1);
end

function g.linkitem(itemObj)
	local imgheight = 30;
	local imgtag =  "";
	local imageName = GET_ITEM_ICON_IMAGE(itemObj);
	local imgtag = string.format("{img %s %d %d}", imageName, imgheight, imgheight);
	local properties = "";
	local itemName = GET_FULL_NAME(itemObj);

	if tostring(itemObj.RefreshScp) ~= "None" then
		_G[itemObj.RefreshScp](itemObj);
	end

	if itemObj.ClassName == 'Scroll_SkillItem' then		
		local sklCls = GetClassByType("Skill", itemObj.SkillType)
		itemName = itemName .. "(" .. sklCls.Name ..")";
		properties = GetSkillItemProperiesString(itemObj);
	else
		properties = GetModifiedProperiesString(itemObj);
	end

	if properties == "" then
		properties = 'nullval'
	end

	local itemrank_num = itemObj.ItemStar

	return string.format("{a SLI %s %d}{#0000FF}%s%s{/}{/}{/}", properties, itemObj.ClassID, imgtag, itemName);
end


function g.processCommand(words)
	local g = _G["ADDONS"]["MIEI"]["ITEMDROPS"];
	local cmd = table.remove(words,1);
	local validFilterGrades = 'common, rare, epic, legendary, off';
	if not cmd then
		local msg = '/drops party on/off{nl}';
		msg = msg .. 'Display drops owned by party members.{nl}';
		msg = msg .. '-----------{nl}';
		msg = msg .. '/drops silver on/off{nl}';
		msg = msg .. 'Show name tags for silver on/off{nl}';
		msg = msg .. '-----------{nl}';
		msg = msg .. '/drops msg [grade]{nl}';
		msg = msg .. 'Set the filter grade for chat messages{nl}';
		msg = msg .. 'Currently: '..g.settings.msgFilterGrade..'{nl}';
		msg = msg .. '-----------{nl}';
		msg = msg .. '/drops fx [grade]{nl}';
		msg = msg .. 'Set the filter grade for effects{nl}';
		msg = msg .. 'Currently: '..g.settings.effectFilterGrade..'{nl}';
		msg = msg .. '-----------{nl}';
		msg = msg .. '/drops name [grade]{nl}';
		msg = msg .. 'Set the filter grade for name tags{nl}';
		msg = msg .. 'Currently: '..g.settings.nameTagFilterGrade..'{nl}';
		msg = msg .. '-----------{nl}';
		msg = msg .. '/drops filter [grade]{nl}'
		msg = msg .. 'Set ALL filters to the specified item grade.{nl}';
		msg = msg .. '-----------{nl}';
		msg = msg .. 'Filter [grade] can be any of the following:{nl}';
		msg = msg .. "| " .. validFilterGrades .. ' |{nl}';
		msg = msg .. '"off" meaning that the feature will be disabled.'
		
		return ui.MsgBox(msg,"","Nope");

	elseif cmd == 'party' then
		cmd = table.remove(words,1);
		if cmd == 'on' then
			g.settings.showPartyDrops = true;
			CHAT_SYSTEM("[itemDrops] Showing drops owned by party members.")
		elseif cmd == 'off' then
			g.settings.showPartyDrops = false;
			CHAT_SYSTEM("[itemDrops] Hiding drops owned by party members.")
		end

	elseif cmd == 'cards' then
		cmd = table.remove(words,1);
		if cmd == 'on' then
			g.settings.alwaysShowXPCards = true;
			CHAT_SYSTEM("[itemDrops] Always show card drops enabled.")
		elseif cmd == 'off' then
			g.settings.alwaysShowXPCards = false;
			CHAT_SYSTEM("[itemDrops] Always show card drops disabled.")
		end

	elseif cmd == 'gems' then
		cmd = table.remove(words,1);
		if cmd == 'on' then
			g.settings.alwaysShowMonGems = true;
			CHAT_SYSTEM("[itemDrops] Always show monster gem drops enabled.")
		elseif cmd == 'off' then
			g.settings.alwaysShowMonGems = false;
			CHAT_SYSTEM("[itemDrops] Always show monster gem drops disabled.")
		end

	elseif cmd == 'silver' then
		cmd = table.remove(words,1);
		if cmd == 'on' then
			g.settings.showSilverNameTag = true;
			CHAT_SYSTEM("[itemDrops] Showing silver name tags.")
		elseif cmd == 'off' then
			g.settings.showSilverNameTag = false;
			CHAT_SYSTEM("[itemDrops] Hiding silver name tags.")
		end

	elseif cmd == 'filter' then
		cmd = table.remove(words,1);
		if g.checkFilterGrade(cmd) == true then -- check if valid filter grade
			g.settings.msgFilterGrade = cmd;
			g.settings.effectFilterGrade = cmd;
			g.settings.nameTagFilterGradee = cmd;
			CHAT_SYSTEM("[itemDrops] Setting all filters to: " .. cmd)
		else
			CHAT_SYSTEM("[itemDrops] Invalid filter grade. Valid filter grades are:");
			CHAT_SYSTEM(validFilterGrades);
		end

	elseif cmd == 'msg' then
		cmd = table.remove(words,1);
		if g.checkFilterGrade(cmd) == true then -- check if valid filter grade
			g.settings.msgFilterGrade = cmd;
			CHAT_SYSTEM("[itemDrops] Message filter set to: " .. cmd)
		else
			CHAT_SYSTEM("[itemDrops] Invalid filter grade. Valid filter grades are:");
			CHAT_SYSTEM(validFilterGrades);
		end

	elseif cmd == 'fx' then
		cmd = table.remove(words,1);
		if g.checkFilterGrade(cmd) == true then -- check if valid filter grade
			g.settings.effectFilterGrade = cmd;
			CHAT_SYSTEM("[itemDrops] Effect filter set to: " .. cmd)
		else
			CHAT_SYSTEM("[itemDrops] Invalid filter grade. Valid filter grades are:");
			CHAT_SYSTEM(validFilterGrades);
		end

	elseif cmd == 'name' then
		cmd = table.remove(words,1);
		if g.checkFilterGrade(cmd) == true then -- check if valid filter grade
			g.settings.nameTagFilterGrade = cmd;
			CHAT_SYSTEM("[itemDrops] Name tag filter set to: " .. cmd)
		else
			CHAT_SYSTEM("[itemDrops] Invalid filter grade. Valid filter grades are:");
			CHAT_SYSTEM(validFilterGrades);
		end


	else
		CHAT_SYSTEM('[itemDrops] Invalid input. Type "/drops" for help.');
	end
	--acutil.saveJSON(g.settingsFileLoc, g.settings);
end


function g.checkFilterGrade(text)
	if g.indexOf(g.itemGrades, text) ~= nil then
		return true;
	elseif text == "off" then
		return true;
	else 
		return false;
	end
end

function g.indexOf( t, object )
	local result = nil;

	if "table" == type( t ) then
		for i=1,#t do
			if object == t[i] then
				result = i;
				break;
			end
		end
	end

	return result;
end

function ITEMDROPS_ON_INIT(addon, frame)
	local g = _G['ADDONS']['MIEI']['ITEMDROPS'];
	--local acutil = require('acutil');
	g.addon = addon;
	g.frame = frame;
	
	g.addon:RegisterMsg("GAME_START_3SEC", "ITEMDROPS_3SEC");
end