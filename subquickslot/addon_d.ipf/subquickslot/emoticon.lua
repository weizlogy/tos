--* chat_emoticon.luaからコピペ -> tooltipにimageNameの表示
function CHAT_EMOTICON_MAKELIST(frame)

	local emoticons = GET_CHILD_RECURSIVELY(frame, "emoticons", "ui::CSlotSet");
	local cnt = emoticons:GetSlotCount();
	local etc = GetMyEtcObject();
	local index = 0;
	local list, listCnt = GetClassList("chat_emoticons");

	-- 아이콘 타입 확인 : 일반, 모션
	local iconGroup = frame:GetUserValue("EMOTICON_GROUP");
	local curCnt = frame:GetUserIValue("CURCNT");
	if iconGroup == "None" then
		iconGroup = "Normal";
	end

	for i = 0 , listCnt - 1 do
		local slot = emoticons:GetSlotByIndex(index);
		slot:SetEventScript(ui.MOUSEMOVE, "CHAT_EMOTICON_ADDDURATION");	
		slot:SetOverSound("button_over")
		slot:SetClickSound("button_click_chat")
		if index < cnt then
			local cls = GetClassByIndexFromList(list, i);

			if cls.IconGroup == iconGroup then
				if cls.CheckServer == 'YES' then
					-- check session emoticons
					local haveEmoticon = TryGetProp(etc, 'HaveEmoticon_' .. cls.ClassID);
					if haveEmoticon > 0 then
						local icon = CreateIcon(slot);
						local namelist = StringSplit(cls.ClassName, "motion_");
						local imageName = namelist[1];
						if 1 < #namelist then
							imageName = namelist[2];
						end
						
						icon:SetImage(imageName);
						local tooltipText = string.format( "%s%s(%s)" , "/" ,cls.IconTokken, imageName);
						icon:SetTextTooltip(tooltipText);

						index = index + 1;				
						slot:ShowWindow(1);
					end
				else
					local icon = CreateIcon(slot);
					local namelist = StringSplit(cls.ClassName, "motion_");
					local imageName = namelist[1];
					if 1 < #namelist then
						imageName = namelist[2];
					end
						
					icon:SetImage(imageName);
					local tooltipText = string.format( "%s%s(%s)" , "/" ,cls.IconTokken, imageName);
					icon:SetTextTooltip(tooltipText);
					index = index + 1;				
					slot:ShowWindow(1);
				end				
			end
		end
	end

	if curCnt ~= 0 then
		for i = index , curCnt - 1 do
			local slot = emoticons:GetSlotByIndex(i);
			slot:ClearIcon();
		end
	end

	frame:SetUserValue("CURCNT", index);
end