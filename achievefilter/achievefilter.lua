-- 領域定義
local author = 'weizlogy'
local addonName = 'achievefilter'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  local members = {}

  -- state：チェック状態、count：業績数
  local __checkedStates = {
    complete = {
      state = 1,
      count = 0
    },
    unknown = {
      state = 0,
      count = 0
    },
    incomplete = {
      state = 1,
      count = 0
    }
  }

  -- チェックボックス生成/更新
  members.CreateOrUpdateFilterControls = function(self, frame, curtabIndex)
    g.instance:Dbg('CreateOrUpdateFilterControls called.')
    if (curtabIndex ~= 1) then
      DESTROY_CHILD_BYNAME(frame, addonName..'_')
      return
    end
    local fontType = 'brown_16_b'
    local script = 'ACHIVEFILTER_REFRESH_LIST'
    local complete = frame:CreateOrGetControl('checkbox', addonName..'_optionComplete', 10, 128, 90, 30)
    tolua.cast(complete, "ui::CCheckBox")
    complete:SetCheck(__checkedStates.complete.state)
    complete:SetFontName(fontType)
    complete:SetEventScript(ui.LBUTTONUP, script)
    complete:SetText('完成('..__checkedStates.complete.count..')')
    local unknown = frame:CreateOrGetControl('checkbox', addonName..'_optionUnknown', 170, 128, 90, 30)
    tolua.cast(unknown, "ui::CCheckBox")
    unknown:SetCheck(__checkedStates.unknown.state)
    unknown:SetFontName(fontType)
    unknown:SetEventScript(ui.LBUTTONUP, script)
    unknown:SetText('未確認('..__checkedStates.unknown.count..')')
    local incomplete = frame:CreateOrGetControl('checkbox', addonName..'_optionInComplete', 370, 128, 90, 30)
    tolua.cast(incomplete, "ui::CCheckBox")
    incomplete:SetCheck(__checkedStates.incomplete.state)
    incomplete:SetFontName(fontType)
    incomplete:SetEventScript(ui.LBUTTONUP, script)
    incomplete:SetText('未完成('..__checkedStates.incomplete.count..')')
  end

  -- チェックボックスの操作状態を記憶
  members.SaveCheckedState = function(self, ctrl)
    local targetStateName = string.gsub(ctrl:GetName():lower(), addonName..'_option', '')
    __checkedStates[targetStateName].state = ctrl:IsChecked()
    self:Dbg('complete'..' - '..__checkedStates['complete'].state)
    self:Dbg('unknown'..' - '..__checkedStates['unknown'].state)
    self:Dbg('incomplete'..' - '..__checkedStates['incomplete'].state)
  end

  -- 見たまんま
  members.ClearStateCount = function(self, frame)
    __checkedStates.complete.count = 0
    __checkedStates.unknown.count = 0
    __checkedStates.incomplete.count = 0
  end

  -- 業績フィルター処理（ついでにカウントもする）
  members.Filter = function(self, classType, have)
    local achive = GetClassByType('Achieve', classType)
    if (achive == nil) then
      return 0
    end
    local isComplete = GetAchievePoint(GetMyPCObject(), achive.NeedPoint) >= achive.NeedCount

    local filterResult = 0

    -- カウントしつつフィルター分かりにくいけどまあ...
    -- 完成 = 完成している
    if (isComplete) then
      __checkedStates.complete.count = __checkedStates.complete.count + 1
      if (__checkedStates.complete.state == 1) then
        filterResult = 1
      end
    end
    -- 未確認 = 隠れている and 完成してない
    -- どうやら過去イベの称号なんかは隠してしまうらしいので完成してると拾っちゃう
    if (achive.Hidden == 'YES' and not isComplete) then
      __checkedStates.unknown.count = __checkedStates.unknown.count + 1
      if (__checkedStates.unknown.state == 1) then
        filterResult = 2
      end
    end
    -- 未完成 = 隠れてない and 完成してない
    if (achive.Hidden == 'NO' and not isComplete) then
      __checkedStates.incomplete.count = __checkedStates.incomplete.count + 1
      if (__checkedStates.incomplete.state == 1) then
        filterResult = 3
      end
    end

    -- self:Dbg(achive.Name..' - '..achive.Hidden..' - '..tostring(isComplete)..' - '..have..' - '..filterResult)
    return filterResult
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

  -- デストラクター
  members.Destroy = function(self)
    if (self.STATUS_VIEW ~= nil) then
      STATUS_VIEW = self.STATUS_VIEW
    end
    if (self.ACHIEVE_RESET ~= nil) then
      ACHIEVE_RESET = self.ACHIEVE_RESET
    end
  end
  -- おまじない
  return setmetatable(members, {__index = self})
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new})

-- 自フレーム初期化処理
function ACHIEVEFILTER_ON_INIT(addon, frame)
  g.instance:Dbg('ACHIEVEFILTER_ON_INIT called.')
  -- 業績フィルター用のチェックボックスをインジェクションする
  if (g.instance.STATUS_VIEW == nil) then
    g.instance.STATUS_VIEW = STATUS_VIEW
  end
  STATUS_VIEW = function(frame, curtabIndex)
    g.instance.STATUS_VIEW(frame, curtabIndex)
    g.instance:CreateOrUpdateFilterControls(frame, curtabIndex)
  end
  -- 業績の集計結果をセットするために...
  -- ていうかON_HAIR_COLOR_CHANGEでSTATUS_ACHIEVE_INIT直コールしてるのなんなの？げきおこ
  if (g.instance.ACHIEVE_RESET == nil) then
    g.instance.ACHIEVE_RESET = ACHIEVE_RESET
  end
  ACHIEVE_RESET = function(frame)
    g.instance:ClearStateCount(frame)
    g.instance.ACHIEVE_RESET(frame)
    -- 矯正1でもいいけど念の為
    local curtabIndex = tolua.cast(frame:GetChild('statusTab'), "ui::CTabControl"):GetSelectItemIndex()
    g.instance:CreateOrUpdateFilterControls(frame, curtabIndex)
  end
end

function ACHIVEFILTER_REFRESH_LIST(parent, ctrl)
  g.instance:Dbg('ACHIVEFILTER_REFRESH_LIST called.')
  g.instance:SaveCheckedState(ctrl)
  ACHIEVE_RESET(parent)
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy()
end
g.instance = g()


--- status.luaのSTATUS_ACHIEVE_INITを書き換え
function STATUS_ACHIEVE_INIT(frame)

    local achieveGbox = frame:GetChild('achieveGbox');
    local internalBox = achieveGbox:GetChild("internalBox");

    -- 追加 start
    DESTROY_CHILD_BYNAME(internalBox, 'ACHIEVE_RICHTEXT_')
    -- 追加 end

    local clslist, clscnt = GetClassList("Achieve");
    local etcObj = GetMyEtcObject();
    local x = 10;
    local y = 10;

    local equipAchieveName = pc.GetEquipAchieveName();

    for i = 0, clscnt - 1 do

        local cls = GetClassByIndexFromList(clslist, i);
        if cls == nil then
            break;
        end

        -- 変更 start
        -- if HAVE_ACHIEVE_FIND(cls.ClassID) == 1 or cls.Hidden == "NO" then
        local filterResult = g.instance:Filter(cls.ClassID, HAVE_ACHIEVE_FIND(cls.ClassID))
        if filterResult > 0 then
        -- 変更 end

            local nowpoint = GetAchievePoint(GetMyPCObject(), cls.NeedPoint)

            local eachAchiveCSet = internalBox:CreateOrGetControlSet('each_achieve', 'ACHIEVE_RICHTEXT_' .. i, x, y);
            tolua.cast(eachAchiveCSet, "ui::CControlSet");

            eachAchiveCSet:SetUserValue('ACHIEVE_ID', cls.ClassID);

            local NORMAL_SKIN = eachAchiveCSet:GetUserConfig("NORMAL_SKIN")
            local HAVE_SKIN = eachAchiveCSet:GetUserConfig("HAVE_SKIN")

            local eachAchiveGBox = GET_CHILD_RECURSIVELY(eachAchiveCSet, 'each_achieve_gbox')
            local eachAchiveDescTitle = GET_CHILD_RECURSIVELY(eachAchiveCSet, 'achieve_desctitle')
            local eachAchiveReward = GET_CHILD_RECURSIVELY(eachAchiveCSet, 'achieve_reward')
            local eachAchiveGauge = GET_CHILD_RECURSIVELY(eachAchiveCSet, 'achieve_gauge')
            local eachAchiveStaticDesc = GET_CHILD_RECURSIVELY(eachAchiveCSet, 'achieve_static_desc')
            local eachAchiveDesc = GET_CHILD_RECURSIVELY(eachAchiveCSet, 'achieve_desc')
            local eachAchiveName = GET_CHILD_RECURSIVELY(eachAchiveCSet, 'achieve_name')
            local eachAchiveReqBtn = GET_CHILD_RECURSIVELY(eachAchiveCSet, 'req_reward_btn')
            eachAchiveReqBtn:ShowWindow(0);
            eachAchiveDesc:SetOffset(eachAchiveStaticDesc:GetX() + eachAchiveStaticDesc:GetWidth() + 10, eachAchiveDesc:GetY())
            eachAchiveGauge:SetOffset(eachAchiveStaticDesc:GetX() + eachAchiveStaticDesc:GetWidth() + 10, eachAchiveGauge:GetY())
            eachAchiveGauge:Resize(eachAchiveGBox:GetWidth() - eachAchiveStaticDesc:GetWidth() -50, eachAchiveGauge:GetHeight())
            eachAchiveGauge:SetTextTooltip("(" .. nowpoint .. "/" .. cls.NeedCount .. ")")

            local isHasAchieve = 0;
            if HAVE_ACHIEVE_FIND(cls.ClassID) == 1 and nowpoint >= cls.NeedCount then
                isHasAchieve = 1;
            end

            if isHasAchieve == 1 then
                if equipAchieveName ~= 'None' and equipAchieveName == cls.Name then
                    eachAchiveDescTitle:SetText('{@stx2}' .. cls.DescTitle .. ScpArgMsg('Auto__(SayongJung)'));
                else
                    eachAchiveDescTitle:SetText('{@stx2}' .. cls.DescTitle);
                end
                eachAchiveGBox:SetSkinName(HAVE_SKIN)
            -- 追加 start
            elseif filterResult == 2 then  -- 未確認はDISABLE_SKINを適用させたい
              eachAchiveDescTitle:SetText(cls.DescTitle);
              eachAchiveGBox:SetSkinName('test_skin_gary_01')
            -- 追加 end
            else
                eachAchiveDescTitle:SetText(cls.DescTitle);
                eachAchiveGBox:SetSkinName(NORMAL_SKIN)
            end

            eachAchiveDesc:SetText(cls.Desc);
            eachAchiveGauge:SetPoint(nowpoint, cls.NeedCount);
            eachAchiveName:SetTextByKey('name', cls.Name);
            eachAchiveReward:SetTextByKey('reward', cls.Reward);

            if isHasAchieve == 1 then
                eachAchiveGauge:ShowWindow(0)
                -- eachAchiveCSet:SetEventScript(ui.LBUTTONDOWN, "ACHIEVE_EQUIP");
                -- eachAchiveCSet:SetEventScriptArgNumber(ui.LBUTTONDOWN, cls.ClassID);
                -- eachAchiveCSet:SetTextTooltip(ScpArgMsg('YouCanEquipAchieve'));
                local etcObjValue = TryGetProp(etcObj, 'AchieveReward_' .. cls.ClassName);
                -- if etcObj['AchieveReward_' .. cls.ClassName] == 0 then
                if etcObjValue ~= nil and etcObjValue == 0 then
                    eachAchiveReqBtn:ShowWindow(1);
                end
            else
                eachAchiveGauge:ShowWindow(1)
                -- eachAchiveDesc:SetText(' ' .. cls.Desc);
                -- eachAchiveCSet:SetEventScript(ui.LBUTTONDOWN, "None");
                -- eachAchiveCSet:SetTextTooltip('');
            end

            local suby = eachAchiveDesc:GetY() + eachAchiveDesc:GetHeight() + 10;


            if cls.Name ~= 'None' then
                eachAchiveName:ShowWindow(1)
                eachAchiveName:SetOffset(eachAchiveName:GetX(), suby)
                suby = eachAchiveName:GetY() + eachAchiveName:GetHeight() + 10
            else
                eachAchiveName:ShowWindow(0)
            end

            if cls.Reward ~= 'None' then
                eachAchiveReward:ShowWindow(1)
                eachAchiveReward:SetOffset(eachAchiveReward:GetX(), suby)
                suby = eachAchiveReward:GetY() + eachAchiveReward:GetHeight() + 10
            else
                eachAchiveReward:ShowWindow(0)
            end

            eachAchiveGBox:Resize(eachAchiveGBox:GetWidth(), suby)

            eachAchiveCSet:Resize(eachAchiveCSet:GetWidth(), eachAchiveGBox:GetHeight())

            y = y + eachAchiveCSet:GetHeight() + 10;

        end
    end

    local customizingGBox = GET_CHILD_RECURSIVELY(frame, 'customizingGBox')
    DESTROY_CHILD_BYNAME(customizingGBox, "hairColor_");

    local pc = GetMyPCObject()
    local etc = GetMyEtcObject();
    local nowAllowedColor = etc['AllowedHairColor']

    local nowheadindex = item.GetHeadIndex()

    local Rootclasslist = imcIES.GetClassList('HairType');
    local Selectclass = Rootclasslist:GetClass(pc.Gender);
    local Selectclasslist = Selectclass:GetSubClassList();

    local nowhaircls = Selectclasslist:GetByIndex(nowheadindex - 1);
    if nil == nowhaircls then
        return;
    end
    local nowengname = imcIES.GetString(nowhaircls, 'EngName')
    local nowcolor = imcIES.GetString(nowhaircls, 'ColorE')
    nowcolor = string.lower(nowcolor)

    -- 헤어 컬러가 많아질 경우 UI 벽을 뚫게 된다. row, col로 나눔.
    local max_width = customizingGBox:GetWidth()
    local row = 1
    local col = 0
    -- 아래 하드코딩 되어 있던 것들 이쪽으로 이동.
    local row_top_margin = 20
    local col_left_margin = 30
    local height = 35
    local width = 35
    local select_margin = row_top_margin - 10

    for i = 0, Selectclasslist:Count() do
        local eachcls = Selectclasslist:GetByIndex(i);
        if eachcls ~= nil then
            local eachengname = imcIES.GetString(eachcls, 'EngName')
            if eachengname == nowengname then

                local eachColorE = imcIES.GetString(eachcls, 'ColorE')
                local eachColor = imcIES.GetString(eachcls, 'Color')
                eachColorE = string.lower(eachColorE)

                -- 업적 받으면 헤어 컬러 사라지는 현상이 있다고 해서 HairColor 프로퍼티 값으로도 확인
                if TryGetProp(etc, "HairColor_" .. eachColorE) == 1 then
                    -- row 변경 조건 검사
                    local temp_offset_x = col_left_margin + width * col;
                    local temp_max_width = temp_offset_x + width;
                    if temp_max_width >= max_width then
                        row = row +1
                        col = 0
                    end

                    local eachhairimg = customizingGBox:CreateOrGetControl('picture', 'hairColor_' .. eachColorE, col_left_margin + (width * col), row_top_margin +  (height * row), width, height);
                    tolua.cast(eachhairimg, "ui::CPicture");

                    local colorimgname = GET_HAIRCOLOR_IMGNAME_BY_ENGNAME(eachColorE)
                    eachhairimg:SetImage(colorimgname);
                    eachhairimg:SetTextTooltip(eachColor)
                    eachhairimg:SetEventScript(ui.LBUTTONDOWN, "REQ_CHANGE_HAIR_COLOR");
                    eachhairimg:SetEventScriptArgString(ui.LBUTTONDOWN, eachColorE);

                    if nowcolor == eachColorE then
                        local selectedimg = customizingGBox:CreateOrGetControl('picture', 'hairColor_Selected', col_left_margin + width * col, select_margin +  (height * row), width, height);
                        tolua.cast(selectedimg, "ui::CPicture");
                        selectedimg:SetImage('color_check');
                    end
                    col = col +1
                end
            end
        end
    end
   
    DESTROY_CHILD_BYNAME(customizingGBox, "ACHIEVE_RICHTEXT_");
    local index = 0;
    local x = 40;
    local y = 145;
    

	local useableTitleList = GET_CHILD_RECURSIVELY(frame, "useableTitleList", "ui::CDropList");
	useableTitleList:SelectItemByKey(config.GetXMLConfig("SelectAchieveKey"))
	if equipAchieveName == nil or equipAchieveName == 'None' then
		useableTitleList:ClearItems()
	end
	local myAchieveCount = 0;
	local myAchieveCount_ExceptPeriod = 0
	local currentAchieveCls = nil
	local nextAchieveCls = nil
	frame:SetUserValue("ShowNextStatReward", 0)
	local showNextStatRewardCheckBox = GET_CHILD_RECURSIVELY(frame, 'showNextStatReward')
	showNextStatRewardCheckBox:SetCheck(0)

	local defaultTitleText = frame:GetUserConfig("DEFAULT_TITLE_TEXT")

	useableTitleList:AddItem(0, defaultTitleText)

    for i = 0, clscnt - 1 do

        local cls = GetClassByIndexFromList(clslist, i);
        if cls == nil then
            break;
        end

        local nowpoint = GetAchievePoint(GetMyPCObject(), cls.NeedPoint)

        local isHasAchieve = 0;
        if HAVE_ACHIEVE_FIND(cls.ClassID) == 1 and nowpoint >= cls.NeedCount then
            isHasAchieve = 1;
        end

        if isHasAchieve == 1 and cls.Name ~= "None" then
			local itemString = string.format("{@st42b}%s{/}", cls.Name);
			useableTitleList:AddItem(i, itemString);
			myAchieveCount = myAchieveCount + 1			
			if cls.PeriodAchieve ~= "YES" then
				myAchieveCount_ExceptPeriod = myAchieveCount_ExceptPeriod + 1
			end
        end
    end
				
	local nextAchieveCount = 0
	local list, cnt = GetClassList("AchieveStatReward");

	for i = 0, cnt - 1 do
		local cls = GetClassByIndexFromList(list, i);

		if i + 1 <= cnt - 1 then
			local achieveCount = cls.AchieveCount
			local tempNextAchieveCls = GetClassByIndexFromList(list, i + 1);
			nextAchieveCount = tempNextAchieveCls.AchieveCount
			if achieveCount <= myAchieveCount_ExceptPeriod and myAchieveCount_ExceptPeriod < nextAchieveCount then
				currentAchieveCls = cls
				nextAchieveCls = tempNextAchieveCls
				break
			end
		else
			currentAchieveCls = cls
			nextAchieveCls = cls
		end		
	end

	local titleListStatic = GET_CHILD_RECURSIVELY(frame, "titleListStatic")
	titleListStatic:SetTextByKey("value1", myAchieveCount)

	local currentbuffText = GET_CHILD_RECURSIVELY(frame, "currentbuffText")
	local nextbuffText = GET_CHILD_RECURSIVELY(frame, "nextbuffText")
	if myAchieveCount_ExceptPeriod == 0 then
		currentbuffText:SetTextByKey("value", 0)
		nextbuffText:SetTextByKey("value", 1)
    elseif myAchieveCount_ExceptPeriod >= 60 then
        currentbuffText:SetTextByKey("value", currentAchieveCls.ClassID - 1)
        nextbuffText:SetTextByKey("value", 0)
	else
		currentbuffText:SetTextByKey("value", currentAchieveCls.ClassID - 1)
		nextbuffText:SetTextByKey("value", nextAchieveCount - myAchieveCount_ExceptPeriod)
	end
					
	frame : SetUserValue("currentAchieveClassID", currentAchieveCls.ClassID)
	frame : SetUserValue("nextAchieveClassID", nextAchieveCls.ClassID)

	CHANGE_STAT_FONT(frame, 'STR', currentAchieveCls.STR_BM, 1)
	CHANGE_STAT_FONT(frame, 'CON', currentAchieveCls.CON_BM, 1)
	CHANGE_STAT_FONT(frame, 'INT', currentAchieveCls.INT_BM, 1)
	CHANGE_STAT_FONT(frame, 'MNA', currentAchieveCls.MNA_BM, 1)
	CHANGE_STAT_FONT(frame, 'DEX', currentAchieveCls.DEX_BM, 1)
	CHANGE_STAT_FONT(frame, 'PATK', currentAchieveCls.PATK_BM, 1)
	CHANGE_STAT_FONT(frame, 'MATK', currentAchieveCls.MATK_BM, 1)
	CHANGE_STAT_FONT(frame, 'DEF', currentAchieveCls.DEF_BM, 1)
	CHANGE_STAT_FONT(frame, 'MDEF', currentAchieveCls.MDEF_BM, 1)
	CHANGE_STAT_FONT(frame, 'MSP', currentAchieveCls.MSP_BM, 1)
				
	frame:Invalidate();
end
---