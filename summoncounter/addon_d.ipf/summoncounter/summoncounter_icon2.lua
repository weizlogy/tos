-- アイコン表示モード２
-- 召喚物をアイコンで、キャラクターの上下に表示する
ModeIcon2 = {}

function ModeIcon2.new(self)
  local members = {}

  members.Key = ''
  members.Handles = {}

  -- モード処理を実行する
  -- frame  UI生成先フレーム
  -- config モード用設定
  members.Execute = function(self, frame, config)
    for i, handle in ipairs(self.Handles) do
      self:CreateSummonIcon(frame, handle, config, i)
    end
  end

  -- 召喚物アイコンを作成する
  -- frame  UI生成先フレーム
  -- handle 召喚物のハンドル
  -- config モード用設定
  -- index  表示位置
  members.CreateSummonIcon = function(self, frame, handle, config, index)
    local iconName = 'vw_'..self.Key..'_'..handle

    local iconSize = 60
    local iconPos = config.loc
    local iconYBase = 0
    local iconCenterMarginX = -27

    if (iconPos == 'up') then
      iconYBase = 0.4
    elseif (iconPos == 'down') then
      iconYBase = 3.6
    end

    local pic = frame:CreateOrGetControl('picture', iconName, 0, 0, iconSize, iconSize)
    tolua.cast(pic, 'ui::CPicture')

    local loc = config['loc'..index]
    local x = (frame:GetWidth() / 2) + loc.x + iconCenterMarginX
    local y = (90 + loc.y) * iconYBase

    pic:SetImage('summoncounter_necro_circle')
    pic:SetEnableStretch(1)
    pic:SetOffset(x, y)
    pic:EnableHitTest(0)
  end

  return setmetatable(members, {__index = self})
end
setmetatable(ModeIcon2, {__call = ModeIcon2.new})
