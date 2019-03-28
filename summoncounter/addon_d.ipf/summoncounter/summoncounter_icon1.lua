-- アイコン表示モード１
-- 召喚物をアイコンで、キャラクターの左右に表示する
ModeIcon1 = {}

-- コンストラクター
function ModeIcon1.new(self)
  local members = {}

  members.Key = ''
  members.Handles = {}

  -- モード処理を実行する
  -- frame  UI生成先フレーム
  -- config モード用設定
  members.Execute = function(self ,frame, config)
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

    local iconSize = 35
    local iconPos = config.loc
    local iconXBase = 0

    if (iconPos == 'left') then
      iconXBase = 3
    elseif (iconPos == 'right') then
      iconXBase = 1.6
    end

    local pic = frame:CreateOrGetControl('picture', iconName, 0, 0, iconSize, iconSize)
    tolua.cast(pic, 'ui::CPicture')

    local loc = config['loc'..index]
    local x = frame:GetWidth() / iconXBase + loc.x
    local y = 90 + loc.y

    pic:SetImage('summoncounter_necro_skull')
    pic:SetEnableStretch(1)
    pic:SetOffset(x, y)
    pic:EnableHitTest(0)
  end

  return setmetatable(members, {__index = self})
end
setmetatable(ModeIcon1, {__call = ModeIcon1.new})
