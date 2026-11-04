-- Window manager backend for the workspace dots (items/spaces.lua). Both
-- aerospace and rift are supported; only the one picked here is used.
--
-- Switching: change ACTIVE, make sure only that WM runs at login (aerospace:
-- start-at-login in aerospace.toml; rift: `brew services start|stop rift`),
-- then `brew services restart sketchybar`.

local ui = require("ui")

local ACTIVE = "aerospace" -- "aerospace" or "rift"

local backends = {}

-- Each backend has:
--   events       custom events the WM triggers (registered in sketchybarrc)
--   update_freq  polling interval for whatever the WM has no event for
--   switch(sid)  shell command that focuses workspace `sid`
--   query(env, done)  calls done(focused_sid, { [sid] = true, ... non-empty })

backends.aerospace = {
  -- Triggered by exec-on-workspace-change in ~/.aerospace.toml
  events = { "aerospace_workspace_change" },
  -- aerospace has no event for windows opening or closing; the query takes
  -- ~30ms, so polling is cheap.
  update_freq = 3,
  switch = function(sid) return "aerospace workspace " .. sid end,
  -- The trigger hands us the focused workspace; routine updates and
  -- front_app_switched have to ask for it.
  query = function(env, done)
    local focused = env and env.AEROSPACE_FOCUSED_WORKSPACE
    local cmd = "aerospace list-workspaces --monitor all --empty no"
    if not focused or focused == "" then
      cmd = "aerospace list-workspaces --focused; echo ---; " .. cmd
    else
      cmd = string.format("echo %q; echo ---; ", focused) .. cmd
    end
    ui.exec(cmd, function(result)
      if type(result) ~= "string" then return end
      local head, tail = result:match("^(.-)\n?%-%-%-\n?(.*)$")
      if not head then return end
      local non_empty = {}
      for sid in tail:gmatch("%S+") do non_empty[sid] = true end
      done(head:match("%S+"), non_empty)
    end)
  end,
}

-- rift-cli switches by zero-based index, the bar shows workspace names. Filled
-- from every query; until the first one, assume names in order from "1".
local rift_index_of = {}

backends.rift = {
  -- Triggered by run_on_start in ~/.config/rift/config.toml
  events = { "rift_workspace_changed", "rift_windows_changed" },
  -- rift has events for both; the slow routine paints the first state at
  -- startup and covers a missed event.
  update_freq = 30,
  switch = function(sid)
    local index = rift_index_of[sid] or (tonumber(sid) and tonumber(sid) - 1)
    return index and ("rift-cli execute workspace switch " .. index)
  end,
  -- One query answers both questions. sbar.exec hands back rift's JSON already
  -- decoded: a list of { index, name, is_focused, window_count, ... }.
  query = function(_, done)
    ui.exec("rift-cli query workspaces", function(workspaces)
      if type(workspaces) ~= "table" then return end
      local focused, non_empty = nil, {}
      for _, ws in ipairs(workspaces) do
        rift_index_of[ws.name] = ws.index
        if ws.is_focused then focused = ws.name end
        if (ws.window_count or 0) > 0 then non_empty[ws.name] = true end
      end
      done(focused, non_empty)
    end)
  end,
}

local wm = assert(backends[ACTIVE], "unknown window manager: " .. ACTIVE)
wm.name = ACTIVE
return wm
