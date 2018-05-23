-- 領域定義
local author = 'weizlogy'
local addonName = 'guildnotifyinchat'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  local members = {}

  -- ギルド名
  members.GetGuildName = function(self, guild)
    return guild.info.name
  end

  -- 例のテキスト
  members.GetNotifyText = function(self, guild)
    return guild.info:GetNotice()
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
function GUILDNOTIFYINCHAT_ON_INIT(addon, frame)
  addon:RegisterMsg("GAME_START_3SEC", "GUILDNOTIFYINCHAT_GAME_START_3SEC");
end

-- ３秒後の処理（ギルド情報初期化待ち的な）
function GUILDNOTIFYINCHAT_GAME_START_3SEC()
  -- ギルドに加入しているか？
  local guild = session.party.GetPartyInfo(PARTY_GUILD)
  if (guild == nil) then
    return
  end
  local text = g.instance:GetNotifyText(guild)
  if (text == nil or text == '') then
    return
  end
  CHAT_SYSTEM('['..g.instance:GetGuildName(guild)..']'..text)
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy()
end
g.instance = g()
