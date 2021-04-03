-- 領域定義
local author = 'weizlogy'
local addonName = 'fixlostchatwindow'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  local members = {};

  -- hide name.
  members.Hide = function(self)
    self.Dbg('Hide called.');
    -- invisible name at head.
    local headsup = ui.GetFrame("headsupdisplay");
    local headsupName = GET_CHILD(headsup, "name_text", "ui::CRichText");
    headsupName:SetText("");
    headsupName:SetAlpha(1);
    -- invisible name below a character.
    local my = ui.GetFrame("charbaseinfo1_my");
    local givenName = GET_CHILD(my, "givenName", "ui::CRichText");
    givenName:SetAlpha(1);
    local familyName = GET_CHILD(my, "familyName", "ui::CRichText");
    familyName:SetAlpha(1);
    local name = GET_CHILD(my, "name", "ui::CRichText");
    name:SetAlpha(1);
    -- invisible guild name below a character.
    local guildName = GET_CHILD(my, "guildName", "ui::CRichText");
    guildName:SetAlpha(1);
    local guildEmblemEdge = GET_CHILD(my, "guildEmblem_edge", "ui::CPicture");
    guildEmblemEdge:SetAlpha(1)
    local guildEmblem = GET_CHILD(my, "guildEmblem", "ui::CPicture");
    guildEmblem:SetAlpha(1)
  end

  --* ログ出力
  members.Dbg = function(self, msg)
    -- CHAT_SYSTEM(string.format('{#666666}[%s] <Dbg> %s', addonName, msg))
  end
  members.Log = function(self, msg)
    CHAT_SYSTEM(string.format('[%s] <Log> %s', addonName, msg))
  end
  members.Err = function(self, msg)
    CHAT_SYSTEM(string.format('{#FF0000}[%s] <Err> %s', addonName, msg))
  end

  -- destroy.
  members.Destroy = function(self)
    HEADSUPDISPLAY_ON_MSG = g.instance.HEADSUPDISPLAY_ON_MSG;
    g.instance.HEADSUPDISPLAY_ON_MSG = nil;
  end
  return setmetatable(members, {__index = self});
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new});

-- frame initialize.
function HIDENAME_ON_INIT(addon, frame)
  if (g.instance.HEADSUPDISPLAY_ON_MSG == nil) then
    g.instance.HEADSUPDISPLAY_ON_MSG = HEADSUPDISPLAY_ON_MSG;
  end
  HEADSUPDISPLAY_ON_MSG = function(frame, msg, argStr, argNum)
    g.instance.HEADSUPDISPLAY_ON_MSG(frame, msg, argStr, argNum);
    g.instance:Hide();
  end
  -- addon:RegisterMsg("GAME_START_3SEC", "HIDENAME_GAME_START_3SEC");
end

function HIDENAME_GAME_START_3SEC(frame)
  local my = ui.GetFrame("charbaseinfo1_my");
  my:SetOpenScript("HIDENAME_CHARBASEINFO1_MY_OPEN");
  g.instance:Hide();
end

-- charbaseinfo1_my open script.
function HIDENAME_CHARBASEINFO1_MY_OPEN()
  g.instance:Hide();
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy();
end
g.instance = g();
