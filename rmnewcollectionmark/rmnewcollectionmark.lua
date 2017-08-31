RmNewCollectionMark = {};

-- constructor.
function RmNewCollectionMark.new(self)
  -- initialize members.
  local members = {};

  members.RemoveNewMark = function(self, type)
    local cls = GetClassByType("Collection", type);
    local etcObj = GetMyEtcObject();
    etcObj["CollectionRead_"..cls.ClassID] = 1;
  end

  -- destroy.
  members.Destroy = function(self)
    SET_COLLECTION_SET = rncm.SET_COLLECTION_SET;
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(RmNewCollectionMark, {__call = RmNewCollectionMark.new});

-- frame initialize.
function RMNEWCOLLECTIONMARK_ON_INIT(addon, frame)
  if (rncm.SET_COLLECTION_SET == nil) then
    rncm.SET_COLLECTION_SET = SET_COLLECTION_SET;
  end
  SET_COLLECTION_SET = function(frame, ctrlSet, type, coll, posY)
    rncm:RemoveNewMark(type);
    return rncm.SET_COLLECTION_SET(frame, ctrlSet, type, coll, posY);
  end
end

-- create instance.
if (rncm ~= nil) then
  rncm:Destroy();
end
rncm = RmNewCollectionMark();
