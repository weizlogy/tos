local _config = {};

function STAMINIGAUGE_UPDATE(frame, msg, argStr, argNum)
  -- get stamina info.
  session.UpdateMaxStamina();
  local stat = info.GetStat(session.GetMyHandle());
  -- update.
  local baseFrame = ui.GetFrame("charbaseinfo1_my");
  local staGauge = GET_CHILD(baseFrame, "pcStaGauge", "ui::CGauge");
  -- msg == nil => for test call.
  if (staGauge == nil or msg == nil) then
    -- create stamina gauge.
    local staGaugeObject = baseFrame:CreateOrGetControl("gauge", "pcStaGauge", 0, 0, 104, 15);
    staGauge = tolua.cast(staGaugeObject, "ui::CGauge");
    staGauge:SetGravity(ui.CENTER_HORZ, ui.TOP);
    staGauge:SetMargin(0, 28, 0, 0);
    staGauge:SetSkinName("pcinfo_gauge_sta2");
    staGauge:ShowWindow(1);
    -- adjust hp/sp gauge.
    local hp = baseFrame:GetChild("pcHpGauge");
    local hpm = hp:GetMargin();
    hp:SetMargin(hpm.left, 8, hpm.right, hpm.bottom);
    local sp = baseFrame:GetChild("pcSpGauge");
    local spm = sp:GetMargin();
    sp:SetMargin(spm.left, 22, spm.right, spm.bottom);
    -- adjust left side image.
    local bgL = GET_CHILD(baseFrame, "pcinfo_bg_L", "ui::CPicture");
    bgL:SetEnableStretch(1);
    bgL:Resize(20, 36);
    local bgLm = bgL:GetMargin();
    bgL:SetMargin(-62, -44, bgLm.right, bgLm.bottom);
    -- adjust right side image.
    local bgR = GET_CHILD(baseFrame, "pcinfo_bg_R", "ui::CPicture");
    bgR:SetEnableStretch(1);
    bgR:Resize(20, 36);
    local bgRm = bgR:GetMargin();
    bgR:SetMargin(62, -44, bgRm.right, bgRm.bottom);
    -- adjust shield gauge.
    local shieldGauge = GET_CHILD(baseFrame, "pcShieldGauge", "ui::CGauge");
    shieldGauge:SetOffset(0, 0);
  end
  staGauge:SetPoint(stat.Stamina, stat.MaxStamina);
end

function STAMINIGAUGE_ON_INIT(addon, frame)
  -- regist stamina update event handler.
  addon:RegisterMsg('STA_UPDATE', 'STAMINIGAUGE_UPDATE');
  --STAMINIGAUGE_UPDATE(frame, "None", nil, nil);
end
