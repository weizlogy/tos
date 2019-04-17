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

  local __ADDON_DIR = '../addons/'..addonName
	local __CONFIG_FILENAME = 'chatConfig'

	local __config = {}

	members.AddMainFramePopupConfig = function(self, key, width, height, x, y, value)
	  self:Dbg('Adding chat window key='..key)
  	__config[key] = {
			width = width, height = height, x = x, y = y, value = value
		}

		DebounceScript('FIXLOSTCHATWINDOW_SAVECONFIG', 1.0)
	end

	members.UpdateMainFramePopupConfig = function(self, key, width, height, x, y, value)
	  self:Dbg('Updating chat window key='..key)
		if (__config[key] == nil) then
		  return
		end
  	__config[key]['width'] = width
  	__config[key]['height'] = height
  	__config[key]['x'] = x
  	__config[key]['y'] = y
  	__config[key]['value'] = value

		DebounceScript('FIXLOSTCHATWINDOW_SAVECONFIG', 1.0)
	end

	members.RemoveMainFramePopupConfig = function(self, key)
	  self:Dbg('Removing chat window key='..key)
  	__config[key] = nil

		DebounceScript('FIXLOSTCHATWINDOW_SAVECONFIG', 1.0)
	end

	members.Serialize = function(self)
	  local f, e = io.open(string.format(
			'%s/%s%d.txt', __ADDON_DIR, __CONFIG_FILENAME, GetServerGroupID()), 'w')
    if (e) then
      self:Err(tostring(e))
      return
    end
    f:write('local s = {}\n')
    for key, values in pairs(__config) do
      f:write(string.format('s[\'%s\'] = {', key))
  		f:write(string.format(' %s = %s, ', 'width', values['width']))
  		f:write(string.format(' %s = %s, ', 'height', values['height']))
  		f:write(string.format(' %s = %s, ', 'x', values['x']))
  		f:write(string.format(' %s = %s, ', 'y', values['y']))
  		f:write(string.format(' %s = %s, ', 'value', values['value']))
      f:write('}\n')
    end
    f:write('return s')
    f:flush()
    f:close()
	end

	members.Deserialize = function(self)
    local filePath = string.format(
			'%s/%s%d.txt', __ADDON_DIR, __CONFIG_FILENAME, GetServerGroupID())
    local f, e = io.open(filePath, 'r')
    if (e) then
      self:Dbg(tostring(e))
      self:Dbg(e)
      return
    end
    f:close()
    local s, e = pcall(dofile, filePath)
    if (not s) then
      self:Err(e)
    end
    __config = e
  end

	members.ChechWindowCount = function(self)
	  -- 設定上の個数
	  local configCount = 0
		for _ in pairs(__config) do configCount = configCount + 1 end
    -- サーバー？上の個数
    local serverCount = session.chat.GetMainFramePopupConfigsSize()

		return serverCount == configCount
	end

	members.RecoverWindow = function(self)
	  for key, values in pairs(__config) do
		  self:Log('Recovering chat window key='..key)
			session.chat.AddMainFramePopupConfig(
				key, values['width'], values['height'], values['x'], values['y'], values['value'])
			CHAT_ADD_MAINCHAT_POPUP_BY_XML(
				key, values['width'], values['height'], values['x'], values['y'], values['value'])
		end
		ui.SaveChatConfig()
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
		if (g.instance.session_chat_AddMainFramePopupConfig ~= nil) then
			session.chat.AddMainFramePopupConfig = g.instance.session_chat_AddMainFramePopupConfig
		end
		if (g.instance.session_chat_RemoveMainFramePopupConfig ~= nil) then
			session.chat.RemoveMainFramePopupConfig = g.instance.session_chat_RemoveMainFramePopupConfig
		end
		if (g.instance.session_chat_UpdateMainFramePopupConfig ~= nil) then
			session.chat.UpdateMainFramePopupConfig = g.instance.session_chat_UpdateMainFramePopupConfig
		end
  end
  -- おまじない
  return setmetatable(members, {__index = self});
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new});

-- 自フレーム初期化処理
function FIXLOSTCHATWINDOW_ON_INIT(addon, frame)
  addon:RegisterMsg('GAME_START_3SEC', 'FIXLOSTCHATWINDOW_GAME_START_3SEC')

  -- 追加
  if (g.instance.session_chat_AddMainFramePopupConfig == nil) then
    g.instance.session_chat_AddMainFramePopupConfig = session.chat.AddMainFramePopupConfig
  end
  session.chat.AddMainFramePopupConfig = function(key, width, height, x, y, value)
    g.instance.session_chat_AddMainFramePopupConfig(key, width, height, x, y, value)
		g.instance:AddMainFramePopupConfig(key, width, height, x, y, value)
  end
  -- 削除
	if (g.instance.session_chat_RemoveMainFramePopupConfig == nil) then
    g.instance.session_chat_RemoveMainFramePopupConfig = session.chat.RemoveMainFramePopupConfig
  end
  session.chat.RemoveMainFramePopupConfig = function(key)
    g.instance.session_chat_RemoveMainFramePopupConfig(key)
		g.instance:RemoveMainFramePopupConfig(key)
  end
  -- 更新
	if (g.instance.session_chat_UpdateMainFramePopupConfig == nil) then
    g.instance.session_chat_UpdateMainFramePopupConfig = session.chat.UpdateMainFramePopupConfig
  end
  session.chat.UpdateMainFramePopupConfig = function(key, width, height, x, y, value)
    g.instance.session_chat_UpdateMainFramePopupConfig(key, width, height, x, y, value)
		g.instance:UpdateMainFramePopupConfig(key, width, height, x, y, value)
  end
end

function FIXLOSTCHATWINDOW_GAME_START_3SEC()
  g.instance:Deserialize()
	local checked = g.instance:ChechWindowCount()
	if (checked) then
	  return
	end
	g.instance:RecoverWindow()
end

function FIXLOSTCHATWINDOW_SAVECONFIG()
  g.instance:Serialize()
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy();
end
g.instance = g();
