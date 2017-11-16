PreviewGuildEmblem = {};

-- constructor.
function PreviewGuildEmblem.new(self)
  -- initialize members.
  local members = {};

  -- destroy.
  members.Destroy = function(self)
    GUILDINFO_OPTION_INIT_EMBLEM = self.GUILDINFO_OPTION_INIT_EMBLEM;
    self.GUILDINFO_OPTION_INIT_EMBLEM = nil;
    GUILDEMBLEM_CHANGE_INIT = self.GUILDEMBLEM_CHANGE_INIT;
    self.GUILDEMBLEM_CHANGE_INIT = nil;
    SET_PRIVIEW_ITEM = self.SET_PRIVIEW_ITEM;
    self.SET_PRIVIEW_ITEM = nil;
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
    if frame ~= nil and AM_I_LEADER(PARTY_GUILD) == 0 then
      local acceptBtn = GET_CHILD_RECURSIVELY(frame, 'acceptBtn');
      acceptBtn:ShowWindow(0);
    end
  end

  if (pgem.SET_PRIVIEW_ITEM == nil) then
    pgem.SET_PRIVIEW_ITEM = SET_PRIVIEW_ITEM;
  end
  SET_PRIVIEW_ITEM = function(frame, ctrlSet, fileName, posY)
    local gb_items = GET_CHILD(ctrlSet, "gb_items", "ui::CGroupBox");
    local pic_icon = GET_CHILD(gb_items, "preview_icon", "ui::CPicture");
    local pic_icon_edge = GET_CHILD(gb_items, "preview_icon_edge", "ui::CPicture");

    local my = ui.GetFrame("charbaseinfo1_my");
    local my_pic_icon = GET_CHILD(my, "guildEmblem", "ui::CPicture");
    local my_pic_icon_edge = GET_CHILD(my, "guildEmblem_edge", "ui::CPicture");
    
    pic_icon:Resize(my_pic_icon:GetWidth(), my_pic_icon:GetHeight());
    pic_icon_edge:Resize(my_pic_icon_edge:GetWidth(), my_pic_icon_edge:GetHeight());

    return pgem.SET_PRIVIEW_ITEM(frame, ctrlSet, fileName, posY);
  end

end

-- create instance.
if (pgem ~= nil) then
  pgem:Destroy();
end
pgem = PreviewGuildEmblem();
