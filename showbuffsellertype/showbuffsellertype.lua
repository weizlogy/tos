-- 領域定義
local author = 'weizlogy'
local addonName = 'showbuffsellertype'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  local members = {};

  -- バフ屋の名前を決める
  members.ToSellTypeName = function(self, sellType, skillID)
    local sellerTypeName = 'None'
    if AUTO_SELL_BUFF == sellType then
      sellerTypeName = 'バフ'
    elseif sellType == AUTO_SELL_GEM_ROASTING then
      sellerTypeName = 'ジェムロースト'
    elseif sellType == AUTO_SELL_SQUIRE_BUFF then
      if skillID == 10701 then
        sellerTypeName = '武器メンテ'
      elseif skillID == 10702 then
        sellerTypeName = '防具メンテ'
      elseif skillID == 10703 then
        sellerTypeName = '修理'
      end
    elseif sellType == AUTO_SELL_OBLATION then
      sellerTypeName = '寄付'
    elseif sellType == AUTO_SELL_ORACLE_SWITCHGENDER then
      sellerTypeName = '性転換'
    elseif sellType == AUTO_SELL_ENCHANTERARMOR then
      sellerTypeName = 'エンチャント'
    elseif sellType == AUTO_SELL_APPRAISE then
      sellerTypeName = '鑑定'
    elseif sellType == AUTO_SELL_PORTAL then
      sellerTypeName = 'ポータル'
    end
    return sellerTypeName
  end

  -- バフ屋バルーンフレームに名前を挿入する
  members.Inject = function(self, sellerTypeName, handle)
    -- フレーム取得
    local frame = ui.GetFrame('SELL_BALLOON_'..handle)
    if (frame == nil) then
      return
    end
    local typeName = frame:CreateOrGetControl('richtext', 'typeName', 0, 0, frame:GetWidth(), 50)
    tolua.cast(typeName, "ui::CRichText")
    typeName:SetText('{ol}{s16}'..sellerTypeName)
  end

  -- デストラクター
  members.Destroy = function(self)
    AUTOSELLER_BALLOON = g.instance.AUTOSELLER_BALLOON
  end
  -- おまじない
  return setmetatable(members, {__index = self});
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new});

-- 自フレーム初期化処理
function SHOWBUFFSELLERTYPE_ON_INIT(addon, frame)
  -- バフ屋バルーンフレーム処理をフックする from buffseller_balloon.lua
  if (g.instance.AUTOSELLER_BALLOON == nil) then
    g.instance.AUTOSELLER_BALLOON = AUTOSELLER_BALLOON
  end
  AUTOSELLER_BALLOON = function(title, sellType, handle, skillID, skillLv)
    g.instance.AUTOSELLER_BALLOON(title, sellType, handle, skillID, skillLv)
    -- 名称に変換してー
    local sellerTypeName = g.instance:ToSellTypeName(sellType, skillID)
    -- インジェクト！
    g.instance:Inject(sellerTypeName, handle)
  end
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy();
end
g.instance = g();
