Console = {};

-- constructor.
function Console.new(self)
  -- initialize members.
  local members = {};
  members.path = "../addons/console/cfunc.txt";
  members.cfunc = {};
  -- execute search.
  members.Execute = function(self)
    CHAT_SYSTEM("Console search start.");

    io.output("console.txt");
    self:Out("[_G]", -1);

    -- ordered by key
    local tkeys = {}
    for k in pairs(_G) do table.insert(tkeys, k) end
    table.sort(tkeys)
    
    for _, k in ipairs(tkeys) do
      local v = _G[k]
      if (k ~= "_G") and (k ~= "io") and (k ~= "file") and (k ~= "DEVLOADER") then
        self:Search(nil, k, v, 0);
        io.flush();
      end
    end
    io.output();
    io.flush();

    CHAT_SYSTEM("Console search end.");
  end

  -- search.
  members.Search = function(self, parent, key, value, depth, f)
    if type(value) == "function" then
      if (string.find(key, "__", 1, true) == 1) then
        return;
      end
      local di = debug.getinfo(value);
      local fi = "cfunc(?)";
      if (di.what ~= "C") then
        --fi = di.short_src;
        fi = string.format("function(%s)", table.concat(debug.getparams(value), ", "));
      else
        local fi2t = cons.cfunc[parent];
        if (fi2t ~= nil) then
          fi = "function("..fi2t[key]..")";
        end
      end
      self:Out("["..key.."]".." = "..fi, depth);
      return;
    end
    if type(value) == "table" then
      if (key == "tolua_ubox") or (key == "jit.opt_inline") or (key == "package") or (key == "jit") then
        self:Out("["..key.."]".." = "..type(value).." is skipped.", depth);
        return;
      end
      self:Out("["..key.."]".." = "..type(value).."("..#value..")".." {", depth);

      -- remove duplication
      if #value > 1 then
        value = { value[1] }
      end

      depth = depth + 1;

      -- ordered by key
      local tkeys = {}
      for k in pairs(value) do table.insert(tkeys, k) end
      table.sort(tkeys)

      for _, k in ipairs(tkeys) do
        self:Search(key, k, value[k], depth);
      end
      depth = depth - 1;
      self:Out("} //".."["..key.."]", depth);
      return;
    end
    if type(value) == "userdata" then
      self:Out("["..key.."]".." = "..type(value).." {", depth);
      depth = depth + 1;
      for k, v in pairs(getmetatable(value)) do
        self:Search(key, k, v, depth);
      end
      depth = depth - 1;
      self:Out("} //".."["..key.."]", depth);
      return;
    end
    self:Out("["..key.."]".." = "..tostring(value), depth);
  end

  -- output.
  members.Out = function(self, text, depth)
    local bk = "";
    for i = 0, depth do
      bk = bk.."..";
    end
    --CHAT_SYSTEM(bk..text);
    io.write(bk..text.."\n");
  end

  -- destroy.
  members.Destroy = function(self)
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(Console, {__call = Console.new});

function CONSOLE_ON_INIT(addon, frame)
  if (cons.UI_CHAT == nil) then
    cons.UI_CHAT = UI_CHAT;
  end
  UI_CHAT = function(msg)
    if (msg == "/console") then
      cons:Execute();
      return;
    end
    cons.UI_CHAT(msg);
  end
  -- load config.
  dofile(cons.path);
end

-- powered by https://facepunch.com/showthread.php?t=884409
function debug.getparams(f)
	local co = coroutine.create(f)
	local params = {}
	debug.sethook(co, function()
		local i, k = 1, debug.getlocal(co, 2, 1)
		while k do
			if k ~= "(*temporary)" then
				table.insert(params, k)
			end
			i = i+1
			k = debug.getlocal(co, 2, i)
		end
		error("~~end~~")
	end, "c")
	local res, err = coroutine.resume(co)
	if res then
		error("The function provided defies the laws of the universe.", 2)
	elseif string.sub(tostring(err), -7) ~= "~~end~~" then
		error("The function failed with the error: "..tostring(err), 2)
	end
	return params
end
-- end

-- create instance.
if (cons ~= nil) then
  cons:Destroy();
end
cons = Console();
