-- One dot per rift workspace, wrapped in a pill. Workspaces with windows
-- get a stronger dot, the focused one is wider. Clicking a dot switches to it.

local S = require("styles")
local ui = require("ui")

local DOT = S.num("SPACE_DOT_SIZE")
local GAP = S.num("SPACE_DOT_GAP")

local sids = {}
for sid in S.SPACE_SIDS:gmatch("%S+") do sids[#sids + 1] = sid end

local dots = {}
local names = {}

-- rift-cli switches by zero-based index, the bar shows workspace names. Filled
-- from every query; until the first one, assume names in order from "1".
local index_of = {}

for i, sid in ipairs(sids) do
  local dot = ui.add("item", "space." .. sid, {
    position = "left",
    width = DOT,
    padding_left = GAP,
    padding_right = GAP,
    icon = { drawing = false },
    label = { drawing = false },
    background = {
      drawing = true,
      color = S.SPACE_DOT_COLOR_EMPTY,
      border_width = 0,
      height = DOT,
      corner_radius = S.num("SPACE_DOT_RADIUS"),
    },
  })
  ui.on(dot, "mouse.clicked", function()
    local index = index_of[sid] or (tonumber(sid) and tonumber(sid) - 1)
    if index then ui.exec("rift-cli execute workspace switch " .. index) end
  end)
  dots[sid] = dot
  names[#names + 1] = dot.name

  if i < #sids then
    ui.add("item", "space_gap." .. sid, {
      position = "left",
      width = GAP,
      padding_left = 0,
      padding_right = 0,
      icon = { drawing = false },
      label = { drawing = false },
      background = { drawing = false },
    })
  end
end

-- Zero padding so it hugs the dot row: the outermost dots already bring
-- SPACE_DOT_GAP of breathing room.
ui.add("bracket", "spaces", names, {
  background = {
    drawing = true,
    color = S.DEFAULT_BACKGROUND_COLOR,
    border_width = S.num("ITEM_BG_BORDER_WIDTH"),
    corner_radius = S.num("ITEM_BG_CORNER_RADIUS"),
    height = S.num("ITEM_BG_HEIGHT"),
    padding_left = 0,
    padding_right = 0,
  },
})

-- What each dot shows right now, so a refresh only animates dots that actually
-- changed instead of re-sending every property every few seconds.
local shown = {}

local function paint(focused, non_empty)
  sbar.animate("tanh", 12, function()
    for _, sid in ipairs(sids) do
      local width, color = DOT, S.SPACE_DOT_COLOR_EMPTY
      if sid == focused then
        width, color = S.num("SPACE_DOT_FOCUSED_WIDTH"), S.SPACE_DOT_COLOR_FOCUSED
      elseif non_empty[sid] then
        color = S.SPACE_DOT_COLOR_ACTIVE
      end
      local signature = width .. color
      if shown[sid] ~= signature then
        shown[sid] = signature
        dots[sid]:set({ width = width, background = { color = color } })
      end
    end
  end)
end

-- One query answers both questions. sbar.exec hands back rift's JSON already
-- decoded: a list of { index, name, is_focused, window_count, ... }.
local function refresh()
  ui.exec("rift-cli query workspaces", function(workspaces)
    if type(workspaces) ~= "table" then return end
    local focused, non_empty = nil, {}
    for _, ws in ipairs(workspaces) do
      index_of[ws.name] = ws.index
      if ws.is_focused then focused = ws.name end
      if (ws.window_count or 0) > 0 then non_empty[ws.name] = true end
    end
    paint(focused, non_empty)
  end)
end

-- Invisible driver. rift emits events for workspace switches and for windows
-- opening or closing (run_on_start in rift/config.toml). The slow routine
-- paints the first state at startup and covers a missed event.
local observer = ui.add("item", "spaces_observer", {
  position = "left",
  drawing = false,
  updates = true,
  update_freq = 30,
})

ui.on(observer,
  { "routine", "forced", "rift_workspace_changed", "rift_windows_changed", "front_app_switched" },
  refresh
)
