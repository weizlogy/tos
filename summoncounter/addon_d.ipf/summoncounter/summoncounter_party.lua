-- パーティ表示モード
-- 召喚物をパーティ風に表示する

ModeParty = {}

-- コンストラクター
function ModeParty.new(self)

  local members = {}

  members.Key = ''
  members.Handles = {}

  -- モード処理を実行する
  -- frame  UI生成先フレーム
  -- config モード用設定
  members.Execute = function(self, __frame, config, skillConfig)
    local frameName = 'summoncounter_party_'..self.Key
    local frame = ui.GetFrame(frameName) or ui.CreateNewFrame('summoncounter', frameName)
    frame:EnableMove(tonumber(config['move'] or '1'))
    frame:EnableHitTest(1)
    frame:EnableHittestFrame(1)
    frame:SetLayerLevel(32) -- クエスト一覧より高く

    if (#self.Handles == 0) then
      frame:ShowWindow(0)
      return
    end

    if (skillConfig and skillConfig['loc_frame']) then
      frame:SetOffset(skillConfig['loc_frame'].x, skillConfig['loc_frame'].y)
    else
      frame:SetOffset(450, 300)
    end

    DESTROY_CHILD_BYNAME(frame, 'PTINFO_')
    for i, handle in ipairs(self.Handles) do
      local ctrlName = 'PTINFO_'.. handle
      local partyInfoCtrlSet = frame:CreateOrGetControlSet('partyinfo', ctrlName, -40, (i - 1) * 50)
      tolua.cast(partyInfoCtrlSet, "ui::CControlSet")
      partyInfoCtrlSet:EnableHitTestSet(0)
      -- リーダーマーク消し
      local leaderMark = GET_CHILD(partyInfoCtrlSet, "leader_img", "ui::CPicture")
      leaderMark:SetImage('None_Mark')
      leaderMark:ShowWindow(0)
      -- 名前
      local nameRichText = tolua.cast(partyInfoCtrlSet:GetChild('name_text'), "ui::CRichText")
      nameRichText:SetTextByKey("name", config.title or targetName)
      -- レベル
      local lvbox = partyInfoCtrlSet:GetChild('lvbox')
      local levelRichText = tolua.cast(lvbox, "ui::CRichText")
      levelRichText:SetTextByKey("lv", info.GetLevel(handle))
      lvbox:Resize(levelRichText:GetWidth(), lvbox:GetHeight())
      -- HP
      local stat = info.GetStat(handle)
      local hpGauge = GET_CHILD(partyInfoCtrlSet, "hp", "ui::CGauge")
      hpGauge:SetPoint(stat.HP, stat.maxHP)
      -- バフ/デバフ
      local buffListSlotSet = GET_CHILD(partyInfoCtrlSet, "buffList", "ui::CSlotSet")
      local debuffListSlotSet = GET_CHILD(partyInfoCtrlSet, "debuffList", "ui::CSlotSet")
      local buffCount = info.GetBuffCount(handle)
      local buffIndex = 0;
      local debuffIndex = 0;
			for i = 0, buffCount - 1 do
				local buff = info.GetBuffIndexed(handle, i)
        local cls = GetClassByType("Buff", buff.buffID)
        local slot = nil;
        if cls.Group1 == 'Buff' then
          slot = buffListSlotSet:GetSlotByIndex(buffIndex);
          buffIndex = buffIndex + 1;
        elseif cls.Group1 == 'Debuff' then
          slot = debuffListSlotSet:GetSlotByIndex(debuffIndex);
          debuffIndex = debuffIndex + 1;
        end
        if slot ~= nil then
          local icon = slot:GetIcon()
          if icon == nil then
            icon = CreateIcon(slot)
          end
          icon:SetDrawCoolTimeText(math.floor(buff.time/1000))
          slot:SetText("")
          if buff.over > 1 then
            slot:SetText('{s13}{ol}{b}'..buff.over, 'count', ui.RIGHT, ui.BOTTOM, 1, 2)
          end
          icon:SetTooltipType('buff')
          icon:SetTooltipArg(handle, cls.ClassID, "")
          local imageName = 'icon_' .. cls.Icon
          icon:Set(imageName, 'BUFF', cls.ClassID, 0)
          slot:ShowWindow(1)
        end
      end
    end
    frame:Resize(frame:GetOriginalWidth(), (#self.Handles) * 50 + 10)
    frame:ShowWindow(1)
    frame:SetEventScript(ui.LBUTTONUP, 'SUMMONCOUNTER_ON_END_DRAG')
    frame:SetEventScriptArgString(ui.LBUTTONUP, self.Key)
    frame:SetEventScript(ui.RBUTTONUP, 'SUMMONCOUNTER_ON_RBUTTONUP')
  end

  -- おまじない
  return setmetatable(members, {__index = self})
end
setmetatable(ModeParty, {__call = ModeParty.new})

function SUMMONCOUNTER_PARTY_ON_INIT(addon, frame) end
