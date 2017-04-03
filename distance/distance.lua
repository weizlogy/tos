local _config = {};

function UPDATE_DISTANCE(frame)
  local handle = frame:GetUserIValue("_AT_OFFSET_HANDLE");    -- Setting by FRAME_AUTO_POS_TO_OBJ
  --local distFromActor = imcMath.Vec3Dist(world.GetActor(handle):GetPos(), _config.actor:GetPos());
  local distFromActor = info.GetTargetInfo(handle).distance;
  if (distFromActor > 300) then
    frame:ShowWindow(0);
    return 0;
  end
  local textObject = frame:GetChild('disttext');
  local distRichText = tolua.cast(textObject, "ui::CRichText");
  --local text = '{#ff9900}{s16}{ol}' .. distFromActor;
  local text = '{#ff9900}{s16}{ol}' .. string.format("%0.2f m", distFromActor / 25);
  distRichText:SetText(text);
  return 1;
end

function UPDATE_DISTANCE_FRAME()
  local list, cnt = SelectObjectByFaction(_config.self, 700, 'Monster');
  for i = 1, cnt do
    local target = list[i];
    local targetHandle = GetHandle(target);
    --CHAT_SYSTEM(enemy:GetName() .. "/" .. distFromActor);
    local dFrame = ui.GetFrame("distance" .. targetHandle);
    if (dFrame == nil) then
      dFrame = ui.CreateNewFrame("distance", "distance"..targetHandle, 0);
    end
    dFrame:ShowWindow(1);
    --FRAME_AUTO_POS_TO_OBJ(dFrame, targetHandle, -dFrame:GetWidth() / 2, 30, 3, 1);
    FRAME_AUTO_POS_TO_OBJ(dFrame, targetHandle, -dFrame:GetWidth() / 2 - 13, 40, 3, 1);
    dFrame:RunUpdateScript("UPDATE_DISTANCE", 0, 0, 0, 1);
  end
end

function DISTANCE_ON_INIT(addon, frame)
  _config.actor = world.GetActor(session.GetMyHandle());
  _config.self = GetMyPCObject();
  addon:RegisterMsg('FPS_UPDATE', 'UPDATE_DISTANCE_FRAME');
end
