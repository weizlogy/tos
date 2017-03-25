local _config = {};

function CLEAR_MONSTER_STATUS_FRAME()
  ui.GetFrame("monsterstatus"):ShowWindow(0);
end

function UPDATE_MONSTER_STATUS_FRAME(frame, msg, argStr, argNum)
  -- maybe it's a not monster.
  if argStr == "None" or argNum == nil then
		return;
	end
  local targetHandle = session.GetTargetHandle();
  local monster = GetClass("Monster", info.GetMonsterClassName(targetHandle));
  -- customize moster class.
  monster.Lv = monster.Level;
  monster.STR = monster.STR_Rate;
  monster.CON = monster.CON_Rate;
  monster.INT = monster.INT_Rate;
  monster.MNA = monster.MNA_Rate;
  monster.DEX = monster.DEX_Rate;
  -- 
  local statFrame = ui.GetFrame("monsterstatus");
  -- set frame position right to TargetWindow.
  local tFrame = ui.GetFrame("targetinfo");
  statFrame:SetPos(tFrame:GetX() + tFrame:GetWidth() + 5, tFrame:GetY());
  -- set monster status.
  GET_CHILD(statFrame, "atk", "ui::CRichText"):SetText(
      "{s16}{ol} ATK "..string.format("%3d", SCR_Get_MON_MAXPATK(monster)).." "
    .."{s16}{ol}MATK "..string.format("%3d", SCR_Get_MON_MAXMATK(monster))
  );
  GET_CHILD(statFrame, "def", "ui::CRichText"):SetText(
      "{s16}{ol} DEF "..string.format("%3d", SCR_Get_MON_DEF(monster)).." "
    .."{s16}{ol}MDEF "..string.format("%3d", SCR_Get_MON_MDEF(monster))
  );
  GET_CHILD(statFrame, "dogde", "ui::CRichText"):SetText(
      "{s16}{ol}  DR "..string.format("%3d", SCR_Get_MON_DR(monster)).." "
    .."{s16}{ol} CDR "..string.format("%3d", SCR_Get_MON_CRTDR(monster))
  );
  GET_CHILD(statFrame, "crit", "ui::CRichText"):SetText(
      "{s16}{ol}CATK "..string.format("%3d", SCR_Get_MON_CRTATK(monster)).." "
    .."{s16}{ol}CDEF "..string.format("%3d", SCR_Get_MON_CRTDEF(monster))
  );
  -- show frame.
  statFrame:ShowWindow(1);
end

function MONSTERSTATUS_ON_INIT(addon, frame)
  -- for normal monsters.
	addon:RegisterMsg('TARGET_SET', 'UPDATE_MONSTER_STATUS_FRAME');
	addon:RegisterMsg('TARGET_CLEAR', 'CLEAR_MONSTER_STATUS_FRAME');
	addon:RegisterMsg('TARGET_UPDATE', 'UPDATE_MONSTER_STATUS_FRAME');
  -- for bosses.
	addon:RegisterMsg('TARGET_SET_BOSS', 'UPDATE_MONSTER_STATUS_FRAME');
	addon:RegisterMsg('TARGET_CLEAR_BOSS', 'CLEAR_MONSTER_STATUS_FRAME');
end
