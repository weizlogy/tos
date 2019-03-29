-- HPバー表示モード
-- 召喚物のHP合計をMAXとしたHPバーを生成する
ModeHPBar = {}

-- コンストラクター
function ModeHPBar.new(self)

  local members = {}

  members.Key = ''
  members.Handles = {}

  -- モード処理を実行する
  -- frame  UI生成先フレーム
  -- config モード用設定
  members.Execute = function(self, __frame, config, skillConfig)
    local frameName = 'summoncounter_hpbar_'..self.Key
    local frame = ui.GetFrame(frameName) or ui.CreateNewFrame('summoncounter', frameName)
    frame:EnableMove(tonumber(config['move'] or '1'))
    frame:EnableHitTest(1)
    frame:EnableHittestFrame(1)
    frame:SetLayerLevel(32) -- クエスト一覧より高く

    if (#self.Handles == 0) then
      frame:ShowWindow(0)
      return
    end

    local locframe = config['loc_frame']
    if (locframe) then
      frame:SetOffset(locframe.x, locframe.y)
    end

    if (skillConfig and skillConfig['loc_frame']) then
      frame:SetOffset(skillConfig['loc_frame'].x, skillConfig['loc_frame'].y)
    else
      frame:SetOffset(450, 300)
    end

    local totalHP, totalMHP = self:CalculateHP()
    if (totalHP <= 0) then
      DESTROY_CHILD_BYNAME(frame, 'summonsHPGauge_'..self.Key)
      DESTROY_CHILD_BYNAME(frame, 'summonsHPGaugeName_'..self.Key)
      return
    end

    -- local locbar = config['loc_bar']
    local title = config['title'] or self.Key

    local summonsHPGauge = frame:CreateOrGetControl(
      'gauge', 'summonsHPGauge_'..self.Key, 0, 0, 188 - 10, 0)
    tolua.cast(summonsHPGauge, 'ui::CGauge')
    -- summonsHPGauge:SetMargin(20, 20, 20, 20)
    summonsHPGauge:Resize(summonsHPGauge:GetWidth(), 30)
    -- summonsHPGauge:SetOffset(locbar.x, locbar.y)
    summonsHPGauge:SetPoint(totalHP, totalMHP)

    summonsHPGauge:SetSkinName('necronomicon_amount')
    summonsHPGauge:SetColorTone('FFCCCCCC')

    if summonsHPGauge:GetStat() == 0 then
      summonsHPGauge:AddStat('%v/%m - '..string.gsub(title, '.-%_', ''))
      summonsHPGauge:SetStatFont(0, 'white_14_ol')
      summonsHPGauge:SetStatOffset(0, 3, 0)
      summonsHPGauge:SetStatAlign(0, 'center', 'center')
    end

    summonsHPGauge:EnableHitTest(0)
    summonsHPGauge:ShowWindow(1)

    frame:ShowWindow(1)
    frame:SetEventScript(ui.LBUTTONUP, 'SUMMONCOUNTER_ON_END_DRAG')
    frame:SetEventScriptArgString(ui.LBUTTONUP, self.Key)
    frame:SetEventScript(ui.RBUTTONUP, 'SUMMONCOUNTER_ON_RBUTTONUP')
  end

  -- 召喚物のHP、MAXHPの合計を取得する
  members.CalculateHP = function(self)
    local totalHP = 0
    local totalMHP = 0
    for i, handle in ipairs(self.Handles) do
      local stat = info.GetStat(handle)
      totalHP = totalHP + stat.HP
      totalMHP = totalMHP + stat.maxHP
    end
    -- for create empty gauge.
    if (totalMHP == 0) then
      totalHP = -1
      totalMHP = 1
    end
    return totalHP, totalMHP
  end

  -- おまじない
  return setmetatable(members, {__index = self})
end
setmetatable(ModeHPBar, {__call = ModeHPBar.new})

function SUMMONCOUNTER_HPBAR_ON_INIT(addon, frame) end
