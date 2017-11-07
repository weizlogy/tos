PreviewGuildEmblem = {};

-- constructor.
function PreviewGuildEmblem.new(self)
  -- initialize members.
  local members = {};

  -- destroy.
  members.Destroy = function(self)
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(PreviewGuildEmblem, {__call = PreviewGuildEmblem.new});

-- frame initialize.
function PREVIEWGUILDEMBLEM_ON_INIT(addon, frame)
  if (pgem.GUILDINFO_OPTION_INIT_EMBLEM == nil) then
    pgem.GUILDINFO_OPTION_INIT_EMBLEM = GUILDINFO_OPTION_INIT_EMBLEM;
  end
  if (pgem.AM_I_LEADER == nil) then
    pgem.AM_I_LEADER = AM_I_LEADER;
  end
  GUILDINFO_OPTION_INIT_EMBLEM = function(optionBox)
    AM_I_LEADER = function(mode)
      return 1;
    end
    pgem.GUILDINFO_OPTION_INIT_EMBLEM(optionBox);
    AM_I_LEADER = pgem.AM_I_LEADER;
  end
  
  if (pgem.GUILDEMBLEM_CHANGE_INIT == nil) then
    pgem.GUILDEMBLEM_CHANGE_INIT = GUILDEMBLEM_CHANGE_INIT;
  end
  GUILDEMBLEM_CHANGE_INIT = function(frame)
    pgem.GUILDEMBLEM_CHANGE_INIT(frame);
    local frame = ui.GetFrame('guildemblem_change')
    if frame ~= nil then
      local acceptBtn = GET_CHILD_RECURSIVELY(frame, 'acceptBtn');
      acceptBtn:ShowWindow(0);
    end
  end
end

-- create instance.
if (pgem ~= nil) then
  pgem:Destroy();
end
pgem = PreviewGuildEmblem();
