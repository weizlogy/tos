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
    self:Dbg('CreateOrUpdateFilterControls called. ')
    self:Dbg('frame = '..frame:GetName())
    self:Dbg('curtabIndex = '..tostring(curtabIndex))

    if (curtabIndex ~= 1) then
      DESTROY_CHILD_BYNAME(frame, addonName..'_')
      return
    end

    -- achievementtracker連携
    local margin = 0
    if (ACHIEVEMENTTRACKER_ON_INIT) then
      margin = 30
    end

    local fontType = 'brown_16_b'
    local script = 'ACHIEVEFILTER_REFRESH_LIST'
    local complete = frame:CreateOrGetControl('checkbox', addonName..'_optionComplete', 10, 128 + margin, 90, 30)
    tolua.cast(complete, "ui::CCheckBox")
    complete:SetCheck(__checkedStates.complete.state)
    complete:SetFontName(fontType)
    complete:SetEventScript(ui.LBUTTONUP, script)
    complete:SetText('完成('..__checkedStates.complete.count..')')
    local unknown = frame:CreateOrGetControl('checkbox', addonName..'_optionUnknown', 170, 128 + margin, 90, 30)
    tolua.cast(unknown, "ui::CCheckBox")
    unknown:SetCheck(__checkedStates.unknown.state)
    unknown:SetFontName(fontType)
    unknown:SetEventScript(ui.LBUTTONUP, script)
    unknown:SetText('未確認('..__checkedStates.unknown.count..')')
    local incomplete = frame:CreateOrGetControl('checkbox', addonName..'_optionInComplete', 370, 128 + margin, 90, 30)
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
    self:Dbg('ClearStateCount called. ')
    __checkedStates.complete.count = 0
    __checkedStates.unknown.count = 0
    __checkedStates.incomplete.count = 0
  end

  -- 業績フィルター処理（ついでにカウントもする）
  members.Filter = function(self, classType, have)
    -- g.instance:Dbg('Filter called. ')
    -- g.instance:Dbg('classType = '..tostring(classType))
    -- g.instance:Dbg('have = '..tostring(have))

    local achieve = GetClassByType('Achieve', classType)
    if (achieve == nil) then
      return 0
    end
    local isComplete = GetAchievePoint(GetMyPCObject(), achieve.NeedPoint) >= achieve.NeedCount

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
    if (achieve.Hidden == 'YES' and not isComplete) then
      __checkedStates.unknown.count = __checkedStates.unknown.count + 1
      if (__checkedStates.unknown.state == 1) then
        filterResult = 2
      end
    end
    -- 未完成 = 隠れてない and 完成してない
    if (achieve.Hidden == 'NO' and not isComplete) then
      __checkedStates.incomplete.count = __checkedStates.incomplete.count + 1
      if (__checkedStates.incomplete.state == 1) then
        filterResult = 3
      end
    end

    -- self:Dbg(achieve.Name..' - '..achieve.Hidden..' - '..tostring(isComplete)..' - '..have..' - '..filterResult)
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
    g.instance:Dbg('ACHIEVE_RESET called.')
    g.instance:ClearStateCount(frame)
    g.instance.ACHIEVE_RESET(frame)
  end
end

function ACHIEVEFILTER_REFRESH_LIST(parent, ctrl)
  g.instance:Dbg('ACHIEVEFILTER_REFRESH_LIST called.')
  g.instance:Dbg('parent = '..parent:GetName())
  g.instance:Dbg('ctrl = '..ctrl:GetName())

  g.instance:SaveCheckedState(ctrl)
  ACHIEVE_RESET(parent)
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy()
end
g.instance = g()


--- status.luaの STATUS_ACHIEVE_INIT を書き換え
function STATUS_ACHIEVE_INIT()
    g.instance:Dbg('STATUS_ACHIEVE_INIT called.')
    local frame = ui.GetFrame("status");
    local achieveGbox = frame:GetChild('achieveGbox');
    local internalBox = achieveGbox:GetChild("internalBox");

    -- 追加 start
    DESTROY_CHILD_BYNAME(internalBox, 'ACHIEVE_RICHTEXT_')
    -- 追加 end

    local clslist, clscnt = GetClassList("Achieve");
    local accObj = GetMyAccountObj();
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

            local nowpoint = GetAchievePoint(GetMyPCObject(), cls.NeedPoint);
            local ctrlset = internalBox:CreateOrGetControlSet('each_achieve', 'ACHIEVE_RICHTEXT_' .. i, x, y);
            tolua.cast(ctrlset, "ui::CControlSet");
            ctrlset:SetUserValue('ACHIEVE_ID', cls.ClassID);

            local NORMAL_SKIN = ctrlset:GetUserConfig("NORMAL_SKIN");
            local HAVE_SKIN = ctrlset:GetUserConfig("HAVE_SKIN");

            local gbox = GET_CHILD_RECURSIVELY(ctrlset, 'each_achieve_gbox')
            local desc_title = GET_CHILD_RECURSIVELY(ctrlset, 'achieve_desctitle')
            local reward = GET_CHILD_RECURSIVELY(ctrlset, 'achieve_reward')
            local gauge = GET_CHILD_RECURSIVELY(ctrlset, 'achieve_gauge')
            local static_accomplishment = GET_CHILD_RECURSIVELY(ctrlset, 'achieve_static_accomplishment')
            local accomplishment = GET_CHILD_RECURSIVELY(ctrlset, 'achieve_accomplishment')
            local static_desc = GET_CHILD_RECURSIVELY(ctrlset, 'achieve_static_desc')
            local desc = GET_CHILD_RECURSIVELY(ctrlset, 'achieve_desc')
            local name = GET_CHILD_RECURSIVELY(ctrlset, 'achieve_name')
            local req_btn = GET_CHILD_RECURSIVELY(ctrlset, 'req_reward_btn')
            req_btn:ShowWindow(0);
            
            --조건과 칭호의 위치를 텍스트 길이가 가장 긴 "달성도" 기준으로 맞춘다
            desc:SetOffset(static_desc:GetX() + static_accomplishment:GetWidth() + 10, desc:GetY())
            accomplishment:SetOffset(static_accomplishment:GetX() + static_accomplishment:GetWidth() + 10, accomplishment:GetY());
            gauge:SetOffset(static_accomplishment:GetX() + static_accomplishment:GetWidth() + 10, gauge:GetY());
            gauge:Resize(gbox:GetWidth() - static_accomplishment:GetWidth() -50, gauge:GetHeight());
            accomplishment:SetText("("..nowpoint.."/"..cls.NeedCount..")");

            local isHasAchieve = 0;
            if HAVE_ACHIEVE_FIND(cls.ClassID) == 1 and nowpoint >= cls.NeedCount then
                isHasAchieve = 1;
            end

            if isHasAchieve == 1 then
                if equipAchieveName ~= 'None' and equipAchieveName == cls.Name then
                    desc_title:SetText(cls.DescTitle .. ScpArgMsg('Auto__(SayongJung)'));
                else
                    desc_title:SetText(cls.DescTitle);
                end
                gbox:SetSkinName(HAVE_SKIN);

            -- 追加 start
            elseif filterResult == 2 then  -- 未確認はDISABLE_SKINを適用させたい
              desc_title:SetText(cls.DescTitle);
              gbox:SetSkinName('test_skin_gary_01')
            -- 追加 end
            else
                desc_title:SetText(cls.DescTitle);
                gbox:SetSkinName(NORMAL_SKIN);
            end

            desc:SetText(cls.Desc);
            gauge:SetPoint(nowpoint, cls.NeedCount);
            name:SetTextByKey('name', cls.Name);
            reward:SetTextByKey('reward', cls.Reward);

            if isHasAchieve == 1 then
                gauge:ShowWindow(0);
                static_accomplishment:ShowWindow(0);
                accomplishment:ShowWindow(0);
                static_desc:SetOffset(static_desc:GetX(), static_accomplishment:GetY());
                desc:SetOffset(desc:GetX(), static_desc:GetY());
                local value = TryGetProp(accObj, "AchieveReward_"..cls.ClassName);
                if value ~= nil and value == 0 then
                    req_btn:ShowWindow(1);
                end
            else
                gauge:ShowWindow(1);
                static_accomplishment:ShowWindow(1);
                accomplishment:ShowWindow(1);
                -- -- 追加 start
                -- local value = TryGetProp(accObj, "AchieveReward_"..cls.ClassName);
                -- if value ~= nil and value == 0 then
                --     req_btn:ShowWindow(1);
                -- end
                -- -- 追加 end
            end

            local suby = desc:GetY() + desc:GetHeight() + 10;
            if cls.Name ~= 'None' then
                name:ShowWindow(1);
                name:SetOffset(name:GetX(), suby);
                suby = name:GetY() + name:GetHeight() + 10;
            else
                name:ShowWindow(0);
            end

            if cls.Reward ~= 'None' then
                reward:ShowWindow(1)
                reward:SetOffset(reward:GetX(), suby)
                suby = reward:GetY() + reward:GetHeight() + 10
            else
                reward:ShowWindow(0)
            end

            gbox:Resize(gbox:GetWidth(), suby);
            ctrlset:Resize(ctrlset:GetWidth(), gbox:GetHeight());
            y = y + ctrlset:GetHeight() + 10;
        end
    end
 
    local customizingGBox =  GET_CHILD_RECURSIVELY(frame, 'customizingGBox')
    STATUS_ACHIEVE_INIT_HAIR_COLOR(customizingGBox); -- 가발 염색 목록 보여주기
    DESTROY_CHILD_BYNAME(customizingGBox, "ACHIEVE_RICHTEXT_");
    
    local index = 0; local x = 40; local y = 145;
	local useableTitleList = GET_CHILD_RECURSIVELY(frame, "useableTitleList", "ui::CDropList");
	useableTitleList:SelectItemByKey(config.GetXMLConfig("SelectAchieveKey"));
	if equipAchieveName == nil or equipAchieveName == 'None' then
		useableTitleList:ClearItems();
    end
    
	local myAchieveCount = 0;
	local myAchieveCount_ExceptPeriod = 0;
	local currentAchieveCls = nil;
	local nextAchieveCls = nil;
    frame:SetUserValue("ShowNextStatReward", 0);
    
	local showNextStatRewardCheckBox = GET_CHILD_RECURSIVELY(frame, 'showNextStatReward');
	showNextStatRewardCheckBox:SetCheck(0);
	
	local defaultTitleText = frame:GetUserConfig("DEFAULT_TITLE_TEXT");
	useableTitleList:AddItem(0, defaultTitleText);

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
			myAchieveCount = myAchieveCount + 1;
			if cls.PeriodAchieve ~= "YES" then
				myAchieveCount_ExceptPeriod = myAchieveCount_ExceptPeriod + 1
			end
        end
    end
				
	local nextAchieveCount = 0;
	local list, cnt = GetClassList("AchieveStatReward");
	for i = 0, cnt - 1 do
		local cls = GetClassByIndexFromList(list, i);
		if i + 1 <= cnt - 1 then
			local achieveCount = cls.AchieveCount;
			local tempNextAchieveCls = GetClassByIndexFromList(list, i + 1);
			nextAchieveCount = tempNextAchieveCls.AchieveCount;
			if achieveCount <= myAchieveCount_ExceptPeriod and myAchieveCount_ExceptPeriod < nextAchieveCount then
				currentAchieveCls = cls;
				nextAchieveCls = tempNextAchieveCls;
				break;
			end
		else
			currentAchieveCls = cls;
			nextAchieveCls = cls;
		end		
	end

	local titleListStatic = GET_CHILD_RECURSIVELY(frame, "titleListStatic");
	titleListStatic:SetTextByKey("value1", myAchieveCount);

	local currentbuffText = GET_CHILD_RECURSIVELY(frame, "currentbuffText");
	local nextbuffText = GET_CHILD_RECURSIVELY(frame, "nextbuffText");
	if myAchieveCount_ExceptPeriod == 0 then
		currentbuffText:SetTextByKey("value", 0);
		nextbuffText:SetTextByKey("value", 1);
    elseif myAchieveCount_ExceptPeriod >= 60 then
        currentbuffText:SetTextByKey("value", currentAchieveCls.ClassID - 1);
        nextbuffText:SetTextByKey("value", 0);
	else
		currentbuffText:SetTextByKey("value", currentAchieveCls.ClassID - 1);
		nextbuffText:SetTextByKey("value", nextAchieveCount - myAchieveCount_ExceptPeriod);
	end
					
	frame:SetUserValue("currentAchieveClassID", currentAchieveCls.ClassID);
	frame:SetUserValue("nextAchieveClassID", nextAchieveCls.ClassID);
	CHANGE_STAT_FONT(frame, 'STR', currentAchieveCls.STR_BM, 1);
	CHANGE_STAT_FONT(frame, 'CON', currentAchieveCls.CON_BM, 1);
	CHANGE_STAT_FONT(frame, 'INT', currentAchieveCls.INT_BM, 1);
	CHANGE_STAT_FONT(frame, 'MNA', currentAchieveCls.MNA_BM, 1);
	CHANGE_STAT_FONT(frame, 'DEX', currentAchieveCls.DEX_BM, 1);
	CHANGE_STAT_FONT(frame, 'PATK', currentAchieveCls.PATK_BM, 1);
	CHANGE_STAT_FONT(frame, 'MATK', currentAchieveCls.MATK_BM, 1);
	CHANGE_STAT_FONT(frame, 'DEF', currentAchieveCls.DEF_BM, 1);
	CHANGE_STAT_FONT(frame, 'MDEF', currentAchieveCls.MDEF_BM, 1);
	CHANGE_STAT_FONT(frame, 'MSP', currentAchieveCls.MSP_BM, 1);
	frame:Invalidate();

  -- 追加 start
  -- 矯正1でもいいけど念の為
  local curtabIndex = tolua.cast(frame:GetChild('statusTab'), "ui::CTabControl"):GetSelectItemIndex()
  g.instance:CreateOrUpdateFilterControls(frame, curtabIndex)
  -- 追加 end

  -- achievementtracker連携
  if (ACHIEVEMENTTRACKER_ON_INIT) then
    AT_ACHIEVE()
  end
end
---