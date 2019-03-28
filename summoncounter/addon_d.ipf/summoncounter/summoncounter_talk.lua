-- トークモード
-- 召喚物を喋らせる

ModeTalk = {}

-- コンストラクター
function ModeTalk.new(self)
  local contents = {}

  local members = {}

  members.Handles = {}

  -- モード処理を実行する
  members.Execute = function(self, addonDir, config)
    -- 生死判定
    if (#self.Handles == 0) then
      return
    end
    -- シード再設定（意味があるのか？）
    math.randomseed(os.time())
    -- 実行確率判定
    if (IMCRandom(1, 100) >= tonumber(config.freq)) then
      return
    end
    -- データロード
    if (#contents == 0) then
      local f, e = io.open(string.format('%s/%s', addonDir, config.data), 'r')
      if (e) then
        CHAT_SYSTEM(tostring(e))
        return
      end
      for line in f:lines() do
        contents[#contents + 1] = line
      end
      f:close()
    end
    -- 選択
    local talktext = ''
    math.randomseed(os.time() + 1)
    if (config.format == 'dicid') then
      talktext = self:CreateTalkWithDICID()
    elseif (config.format == 'custom') then
      -- なぜか乱数生成するとものすごいループ回数になるのでもう一回制限をかける。なぜ...
      math.randomseed(os.time() + 2)
      if (IMCRandom(1, 100) >= tonumber(config.freq)) then
        return
      end
      talktext = self:CreateTalkWithCustom()
    end

    if (talktext == '') then
      return
    end
    math.randomseed(os.time() + 3)
    world.GetActor(self.Handles[IMCRandom(1, #self.Handles)]):GetTitle():Say(talktext, 3.0)
  end

  members.CreateTalkWithDICID = function(self)
    local dicidprefix = contents[IMCRandom(1, #contents)]
    local dictype = string.gsub(dicidprefix, '%_%d+', '')
    local sequence = 0
    if (dictype == 'QUEST') then
      sequence = IMCRandom(1, 10541)
    elseif (dictype == 'QUEST_JOBSTEP') then
      sequence = IMCRandom(1, 3140)
    elseif (dictype == 'QUEST_LV_0100') then
      sequence = IMCRandom(1, 17236)
    elseif (dictype == 'QUEST_LV_0200') then
      sequence = IMCRandom(1, 11370)
    elseif (dictype == 'QUEST_LV_0300') then
      sequence = IMCRandom(1, 8482)
    elseif (dictype == 'QUEST_LV_0400') then
      sequence = IMCRandom(1, 4687)
    elseif (dictype == 'QUEST_UNUSED') then
      sequence = IMCRandom(1, 3216)
    end
    if (sequence == 0) then
      return ''
    end
    local dicid = string.format('@dicID_^*$%s_%06d$*^', dicidprefix, sequence)
    if (string.find(dictionary.ReplaceDicIDInCompStr(dicid), '%$NoData%$') ~= nil) then
      return ''
    end
    return dicid
  end

  members.CreateTalkWithCustom = function(self)
    return contents[IMCRandom(1, #contents)]
  end

  -- おまじない
  return setmetatable(members, {__index = self})
end
setmetatable(ModeTalk, {__call = ModeTalk.new})

function SUMMONCOUNTER_TALK_ON_INIT(addon, frame) end
