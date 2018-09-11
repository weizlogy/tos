-- 領域定義
local author = 'weizlogy'
local addonName = 'warehousesorter'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- コンストラクター
function g.new(self)
  local members = {};

  -- ソートボタン挿入
  members.InjectSortButton = function(self, frame)
    DESTROY_CHILD_BYNAME(frame, 'WAREHOUSESORTER_')
    local sortButton = frame:CreateOrGetControl('button', 'WAREHOUSESORTER_SORT', 0, 0, 45, 45)
    tolua.cast(sortButton, "ui::CButton")
    sortButton:SetImage('inven_piece_btn')
    sortButton:SetTextTooltip('{@st59}インベントリを整理する{/}')
    sortButton:SetClickSound('button_click_big')
    sortButton:SetAnimation("MouseOnAnim", "btn_mouseover")
    sortButton:SetAnimation("MouseOffAnim", "btn_mouseoff")
    sortButton:SetEventScript(ui.LBUTTONUP, "WAREHOUSESORTER_SELECT_SORT_TYPE")
    sortButton:SetGravity(ui.RIGHT, ui.TOP)
    sortButton:SetMargin(0, 110, 160, 0)
  end

  -- デストラクター
  members.Destroy = function(self)
    if (self.WAREHOUSE_OPEN ~= nil) then
      WAREHOUSE_OPEN = self.WAREHOUSE_OPEN
    end
  end
  -- おまじない
  return setmetatable(members, {__index = self});
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new});

-- 自フレーム初期化処理
function WAREHOUSESORTER_ON_INIT(addon, frame)
  -- 個人倉庫を開いたときにソートボタンを挿入する
  if (g.instance.WAREHOUSE_OPEN == nil) then
    g.instance.WAREHOUSE_OPEN = WAREHOUSE_OPEN
  end
  WAREHOUSE_OPEN = function(frame)
    g.instance:InjectSortButton(frame)
    g.instance.WAREHOUSE_OPEN(frame)
  end
end

-- ソートメニュー生成
-- inventory.lua SORT_ITEM_INVENTORY() をベースに REQ_INV_SORT() に渡すパラメータを変更
function WAREHOUSESORTER_SELECT_SORT_TYPE()
	local context = ui.CreateContextMenu("WAREHOUSESORTER_CONTEXT_INV_SORT", "", 0, 0, 170, 100);
	local scpScp = "";
	scpScp = string.format("REQ_INV_SORT(%d, %d)",IT_WAREHOUSE, BY_LEVEL);
	ui.AddContextMenuItem(context, ScpArgMsg("SortByLevel"), scpScp);	
	scpScp = string.format("REQ_INV_SORT(%d, %d)",IT_WAREHOUSE, BY_WEIGHT);
	ui.AddContextMenuItem(context, ScpArgMsg("SortByWeight"), scpScp);	
	scpScp = string.format("REQ_INV_SORT(%d, %d)",IT_WAREHOUSE, BY_NAME);
	ui.AddContextMenuItem(context, ScpArgMsg("SortByName"), scpScp);	
	ui.OpenContextMenu(context);
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy();
end
g.instance = g();
