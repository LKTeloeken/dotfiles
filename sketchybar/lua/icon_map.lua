-- App name -> sketchybar-app-font ligature (":safari:" and so on).
--
-- plugins/icon_map.sh is the upstream-generated map and stays the source of
-- truth, so updating it is still a copy-paste. Its case arms are parsed once
-- here instead of running bash for every lookup.

local path = os.getenv("CONFIG_DIR") .. "/plugins/icon_map.sh"

local exact = {}    -- name -> icon
local prefixes = {} -- { prefix, icon }, in file order like the case statement

local pending = nil -- patterns of the arm whose icon_result comes next

for line in io.lines(path) do
  local arm = line:match('^%s*(".*)%)%s*$')
  if arm then
    pending = {}
    for name, star in arm:gmatch('"([^"]*)"(%*?)') do
      pending[#pending + 1] = { name = name, prefix = star == "*" }
    end
  else
    local icon = line:match('^%s*icon_result="(.*)"%s*$')
    if icon and pending then
      for _, pattern in ipairs(pending) do
        if pattern.prefix then
          prefixes[#prefixes + 1] = { pattern.name, icon }
        elseif not exact[pattern.name] then
          exact[pattern.name] = icon
        end
      end
      pending = nil
    end
  end
end

local cache = {}

return function(app)
  if not app or app == "" then return ":default:" end
  if cache[app] then return cache[app] end
  local icon = exact[app]
  if not icon then
    for _, entry in ipairs(prefixes) do
      if app:sub(1, #entry[1]) == entry[1] then
        icon = entry[2]
        break
      end
    end
  end
  icon = icon or ":default:"
  cache[app] = icon
  return icon
end
