-- 領域定義
local author = 'weizlogy'
local addonName = 'minigaugetext'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  local members = {}

  -- HP/SP情報を更新する
  -- 本当はCGauge:AddStatでやりたいが、フォントサイズが12以下だと反映されない
  -- かつ、%vが100にしかならない？よくわからないξ･~ ･๑Ҙ
  members.Update = function(self, handle)
    local frame = ui.GetFrame("charbaseinfo1_"..handle)
    local hp = frame:GetChild("pcHpGauge")
    tolua.cast(hp, "ui::CGauge")
    local sp = frame:GetChild("pcSpGauge")
    tolua.cast(sp, "ui::CGauge")

    if (handle == 'my') then
      handle = session.GetMyHandle()
    end
    local stat = info.GetStat(handle)

    local hptext = frame:CreateOrGetControl("richtext", "hptext", 0, 0, hp:GetWidth(), hp:GetHeight())
    hptext:SetText(string.format('{s11}{ol}%d/%d', stat.HP, stat.maxHP))
    hptext:SetGravity(ui.RIGHT, ui.TOP);
    hptext:SetOffset(hp:GetX(), hp:GetY() - 8)

    local sptext = frame:CreateOrGetControl("richtext", "sptext", 0, 0, sp:GetWidth(), sp:GetHeight())
    sptext:SetText(string.format('{s11}{ol}%d/%d', stat.SP, stat.maxSP))
    sptext:SetGravity(ui.RIGHT, ui.TOP);
    sptext:SetOffset(sp:GetX(), sp:GetY() + 10)

    -- 面倒なのでこれでいいやξ･~ ･๑Ҙ
    local checkStaGauge = frame:GetChild('pcStaGauge')
    if (checkStaGauge ~= nil) then
      sptext:SetOffset(sp:GetX(), sp:GetY() + 19)
    end
  end

  -- デストラクター
  members.Destroy = function(self)
  end
  -- おまじない
  return setmetatable(members, {__index = self})
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new});

-- 自フレーム初期化処理
function MINIGAUGETEXT_ON_INIT(addon, frame)
  addon:RegisterMsg('STAT_UPDATE', 'MINIGAUGETEXT_STAT_UPDATE');
  addon:RegisterMsg('TAKE_DAMAGE', 'MINIGAUGETEXT_STAT_UPDATE');
  addon:RegisterMsg('TAKE_HEAL', 'MINIGAUGETEXT_STAT_UPDATE');
  --addon:RegisterMsg('FPS_UPDATE', 'MINIGAUGETEXT_STAT_UPDATE_OTHERS');
  MINIGAUGETEXT_STAT_UPDATE()
end

-- HP/SP変化のイベントハンドラー
function MINIGAUGETEXT_STAT_UPDATE()
  g.instance:Update('my')
end

-- HP/SP変化のイベントハンドラー（他人）
-- （あきらめたやつ
function MINIGAUGETEXT_STAT_UPDATE_OTHERS()
  local list, count = SelectBaseObject(GetMyPCObject(), 300, 'ALL')
  for i = 1 , count do
    local obj = list[i];
    local iesObj = GetBaseObjectIES(obj)
    if (iesObj.ClassName == 'PC') then
      local actor = tolua.cast(obj, "CFSMActor")
      local handle = actor:GetHandleVal()
      g.instance:Update(handle)
    end
  end
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy()
end
g.instance = g()
