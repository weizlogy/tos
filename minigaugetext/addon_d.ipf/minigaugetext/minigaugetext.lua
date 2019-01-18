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

  local __ADDON_DIR = '../addons/'..addonName
  local DEFAULT_SIZE = 11
  local DEFAULT_COLOR = '#FFFFFF'

  members.__config = {}

  -- HP/SP情報を更新する
  -- 本当はCGauge:AddStatでやりたいが、フォントサイズが12以下だと反映されない
  -- かつ、%vが100にしかならない？よくわからないξ･~ ･๑Ҙ
  members.Update = function(self, handle)
    -- CHAT_SYSTEM('hadle = '..handle)
    local frame = ui.GetFrame("charbaseinfo1_"..handle)
    if (not frame) then
      return
    end
    local hp = frame:GetChild("pcHpGauge")
    tolua.cast(hp, "ui::CGauge")
    local sp = frame:GetChild("pcSpGauge")
    tolua.cast(sp, "ui::CGauge")

    local size = DEFAULT_SIZE
    local color = DEFAULT_COLOR
    local spcolor = DEFAULT_COLOR

    if (handle == 'my') then
      handle = session.GetMyHandle()
      size = self.__config['size'] or DEFAULT_SIZE
      color = self.__config['color'] or DEFAULT_COLOR
      spcolor = self.__config['spcolor'] or DEFAULT_COLOR
    else
      size = self.__config['ptsize'] or DEFAULT_SIZE
      color = self.__config['ptcolor'] or DEFAULT_COLOR
      spcolor = self.__config['ptspcolor'] or DEFAULT_COLOR
    end
    local stat = info.GetStat(handle)

    local hptext = frame:CreateOrGetControl("richtext", "hptext", 0, 0, hp:GetWidth(), hp:GetHeight())
    hptext:SetText(string.format('{s%d}{ol}{%s}%d/%d', size, color, stat.HP, stat.maxHP))
    hptext:SetGravity(ui.RIGHT, ui.TOP);
    hptext:SetOffset(hp:GetX(), hp:GetY() - 8 - (size - DEFAULT_SIZE))

    local sptext = frame:CreateOrGetControl("richtext", "sptext", 0, 0, sp:GetWidth(), sp:GetHeight())
    sptext:SetText(string.format('{s%d}{ol}{%s}%d/%d', size, spcolor, stat.SP, stat.maxSP))
    sptext:SetGravity(ui.RIGHT, ui.TOP);
    sptext:SetOffset(sp:GetX(), sp:GetY() + 10)

    -- 面倒なのでこれでいいやξ･~ ･๑Ҙ
    local checkStaGauge = frame:GetChild('pcStaGauge')
    if (checkStaGauge ~= nil) then
      sptext:SetOffset(sp:GetX(), sp:GetY() + 19)
    end
    -- ギルド名とちょっとかぶるので...
    local guildinfo = frame:GetChild('guildName')
    if (guildinfo ~= nil) then
      MINIGAUGETEXT_ON_UPDATE_GUILDINFO = function(ctrl)
        local parent = ctrl:GetTopParentFrame()
        local emblem = parent:GetChild('guildEmblem')
        emblem:SetOffset(parent:GetChild("pcSpGauge"):GetX() - 30, emblem:GetY())
        local edge = parent:GetChild('guildEmblem_edge')
        edge:SetOffset(emblem:GetX() - 1, emblem:GetY() - 1)
        ctrl:SetOffset(0, emblem:GetY() + emblem:GetHeight() - 20)
        return 1
      end
      guildinfo:RunUpdateScript('MINIGAUGETEXT_ON_UPDATE_GUILDINFO')
    end 
  end

  members.LoadConfig = function(self)
    self.__config = self:Deserialize('settings.txt') or {}
  end

  -- デシリアライズ
  members.Deserialize = function(self, fileName)
    local filePath = string.format('%s/%s', __ADDON_DIR, fileName)
    local f, e = io.open(filePath, 'r')
    if (e) then
      return nil
    end
    f:close()
    local s, e = pcall(dofile, filePath)
    if (not s) then
      CHAT_SYSTEM(e)
    end
    return e
  end

  -- デストラクター
  members.Destroy = function(self)
    if (self.UPDATE_PARTYINFO_HP ~= nil) then
      UPDATE_PARTYINFO_HP = self.UPDATE_PARTYINFO_HP
    end
  end
  -- おまじない
  return setmetatable(members, {__index = self})
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new});

-- 自フレーム初期化処理
function MINIGAUGETEXT_ON_INIT(addon, frame)
  g.instance:LoadConfig()

  addon:RegisterMsg('STAT_UPDATE', 'MINIGAUGETEXT_STAT_UPDATE');
  addon:RegisterMsg('TAKE_DAMAGE', 'MINIGAUGETEXT_STAT_UPDATE');
  addon:RegisterMsg('TAKE_HEAL', 'MINIGAUGETEXT_STAT_UPDATE');
  --addon:RegisterMsg('FPS_UPDATE', 'MINIGAUGETEXT_STAT_UPDATE_OTHERS');

  -- PTメンバー表示用
  if (g.instance.UPDATE_PARTYINFO_HP == nil) then
    g.instance.UPDATE_PARTYINFO_HP = UPDATE_PARTYINFO_HP
  end
  UPDATE_PARTYINFO_HP = function(partyInfoCtrlSet, partyMemberInfo)
    g.instance.UPDATE_PARTYINFO_HP(partyInfoCtrlSet, partyMemberInfo)
    g.instance:Update(partyMemberInfo:GetHandle())
  end

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
