-- Bridge to styles.sh, so bash and Lua items share one palette and one set of
-- sizes. The shell file stays the source of truth: it is the one that reads the
-- pywal colors, and sync_colors.sh reloads the bar after regenerating them.
--
-- This runs once, before the event loop starts, so the blocking io.popen is
-- fine here (and only here: inside callbacks use sbar.exec).

local config_dir = os.getenv("CONFIG_DIR")

-- set -a exports every variable styles.sh defines; env -0 then prints them
-- NUL-separated, which is safe for values with spaces or colons (font names).
local cmd = string.format(
  "/bin/bash -c 'set -a; . %q/styles.sh; env -0'",
  config_dir
)

local handle = assert(io.popen(cmd, "r"))
local raw = handle:read("a")
handle:close()

local styles = {}
for entry in raw:gmatch("([^%z]+)") do
  local key, value = entry:match("^([%w_]+)=(.*)$")
  if key then styles[key] = value end
end

-- Numeric settings come back as strings; most callers want numbers. Colors
-- (0x...) also convert cleanly, and sketchybar accepts them either way.
function styles.num(key)
  return tonumber(styles[key])
end

return styles
