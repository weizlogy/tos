-- 領域定義
local author = 'weizlogy'
local addonName = 'masterplace'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  local members = {};

  -- 収集したマスター情報
  members.__masterInfo = {}

  -- マスター情報を収集
  --   全マップの表示されている(Hide == 0)NPCのうち、特定のキーワードに一致するものを集める
  members.CollectMasterInfo = function(self)
    local clsList, cnt = GetClassList('Map')
    if cnt == 0 or clsList == nil then
      self:Err('Missing Map class list.')
      return
    end

    self.__masterInfo = {}

    local __insertMasterInfo = function(self, classAbbr, mapName, Name)
      -- self:Dbg(classAbbr..'-'..masterOrSub..' in '..map.Name)
      -- self:Dbg(genobj.Name)
      if (classAbbr == 'BKR') then
        classAbbr = 'BOK'
      end
      if (classAbbr == 'MIKO') then
        classAbbr = 'MKO'
      end
      if (self.__masterInfo[classAbbr] == nil) then
        self.__masterInfo[classAbbr] = {}
      end
      local info = {}
      info['map'] = mapName
      info['name'] = Name
      table.insert(self.__masterInfo[classAbbr], info)
    end

    for i = 0, cnt - 1 do
      local map = GetClassByIndexFromList(clsList, i)
      local genList = SCR_GET_XML_IES('GenType_'..map.ClassName, 'Hide', 0)
      for i = 1, #genList do
        local genobj = genList[i]
        -- 基本パターンは以下の二種類
        --  npc_***_master
        --  npc_***_sub_master
        local classAbbr, masterOrSub = string.match(genobj.ClassType, '^npc_(%u-)_([master|sub])')
        if (masterOrSub ~= nil) then
          __insertMasterInfo(self, classAbbr, map.Name, genobj.Name)
        end
        -- アーチャー以外の基礎クラスはちょっと特殊なんだけどしねばいいとおもうよ
        -- クレリック
        local classAbbr = string.match(genobj.ClassType, '^npc_(healer)$')
        if (classAbbr ~= nil) then
          __insertMasterInfo(self, 'CLR', map.Name, genobj.Name)
        end
        -- ソードマン
        local classAbbr = string.match(genobj.ClassType, '^swordmaster$')
        if (classAbbr ~= nil) then
          __insertMasterInfo(self, 'WAR', map.Name, genobj.Name)
        end
        -- ウィザード
        local classAbbr = string.match(genobj.ClassType, '^wizardmaster$')
        if (classAbbr ~= nil) then
          __insertMasterInfo(self, 'WIZ', map.Name, genobj.Name)
        end
      end
    end

    -- クラペダ隣接の下記マップはMap.iesから取れないみたい？？？
    -- なのでちょっと調べて直書きこれもしねばいいとおもうよ

    -- ボコルマスターの家
    local bokMap = GetClass('Map', 'c_voodoo')
    local genList = SCR_GET_XML_IES('GenType_'..bokMap.ClassName, 'Hide', 0)
    for i = 1, #genList do
      local genobj = genList[i]
      if (string.find(genobj.ClassType, 'npc_bocormaster') == 1) then
        __insertMasterInfo(self, 'BKR', bokMap.Name, genobj.Name)
      end
    end

    -- パイロマンサーの研究室
    local fimMap = GetClass('Map', 'c_firemage')
    local genList = SCR_GET_XML_IES('GenType_'..fimMap.ClassName, 'Hide', 0)
    for i = 1, #genList do
      local genobj = genList[i]
      if (string.find(genobj.ClassType, 'pyromancer') == 1) then
        __insertMasterInfo(self, 'FIM', fimMap.Name, genobj.Name)
      end
    end

    -- ハイランダーの道場
    local hldMap = GetClass('Map', 'c_highlander')
    local genList = SCR_GET_XML_IES('GenType_'..hldMap.ClassName, 'Hide', 0)
    for i = 1, #genList do
      local genobj = genList[i]
      if (string.find(genobj.ClassType, 'highlander') == 1) then
        __insertMasterInfo(self, 'HLD', hldMap.Name, genobj.Name)
      end
    end

    self:Dbg('Finish collect master info.')
  end

  -- 表示処理
  members.InfoView = function(self, treeIconName)
    local jobClassName = string.match(treeIconName, '^classCtrl_(.-)$')
    local job = GetClass('Job', jobClassName)
    self:Dbg(treeIconName..' -> '..jobClassName..' ('..job.Initial)

    for index, info in ipairs(self.__masterInfo[job.Initial]) do
      local prifix, name = string.match(dictionary.ReplaceDicIDInCompStr(info['name']), '^(.-){nl}(.-)$')
      self:Log(string.format('%s %s in %s', string.gsub(prifix, '%s', ''), string.gsub(name, '%s', ''), info['map']))
    end
  end

  members.InterruptMasterInfo = function(self, frame)
    local grid = GET_CHILD_RECURSIVELY(frame, "skill", "ui::CGrid")
    local childCount = grid:GetChildCount()

    self:Dbg('Interrupt class count = '..childCount)

    for i = 0, grid:GetChildCount() - 1 do
      local treeIcon = grid:GetChildByIndex(i)
      treeIcon = tolua.cast(treeIcon, 'ui::CControlSet')
      treeIcon:SetEventScript(ui.RBUTTONUP, 'MASTERPLACE_ON_INFOVIEW')
  		treeIcon:SetEventScriptArgString(ui.RBUTTONUP, treeIcon:GetName())
      local arrowPic = GET_CHILD(treeIcon, 'selectedarrow')
      if (arrowPic ~= nil) then
        arrowPic:SetEventScript(ui.RBUTTONUP, 'MASTERPLACE_ON_INFOVIEW')
    		arrowPic:SetEventScriptArgString(ui.RBUTTONUP, treeIcon:GetName())
      end
      self:Dbg(treeIcon:GetName())
    end
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
    if (self.MAKE_CLASS_INFO_LIST ~= nil) then
      MAKE_CLASS_INFO_LIST = self.MAKE_CLASS_INFO_LIST
      self.MAKE_CLASS_INFO_LIST = nil
    end
  end
  -- おまじない
  return setmetatable(members, {__index = self});
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new});

-- 自フレーム初期化処理
function MASTERPLACE_ON_INIT(addon, frame)
  if (g.instance.MAKE_CLASS_INFO_LIST == nil) then
    g.instance.MAKE_CLASS_INFO_LIST = MAKE_CLASS_INFO_LIST
  end
  MAKE_CLASS_INFO_LIST = function(frame, resetCommonType)
    g.instance.MAKE_CLASS_INFO_LIST(frame, resetCommonType)
    g.instance:InterruptMasterInfo(frame, resetCommonType)
  end
  g.instance:CollectMasterInfo()
end

function MASTERPLACE_ON_INFOVIEW(parent, ctrl, argStr, argNum)
  g.instance:InfoView(argStr)
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy();
end
g.instance = g();
