-- One dot per aerospace workspace, wrapped in a pill. Workspaces with windows
-- get a stronger dot, the focused one is wider. Clicking a dot switches to it.

local S = require("styles")
local ui = require("ui")

local DOT = S.num("SPACE_DOT_SIZE")
local GAP = S.num("SPACE_DOT_GAP")

local sids = {}
for sid in S.SPACE_SIDS:gmatch("%S+") do sids[#sids + 1] = sid end

local dots = {}
local names = {}

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
    ui.exec("aerospace workspace " .. sid)
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

-- The aerospace trigger hands us the focused workspace; routine updates and
-- front_app_switched have to ask for it.
local function refresh(env)
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
    paint(head:match("%S+"), non_empty)
  end)
end

-- Invisible driver. update_freq covers windows opening and closing, which
-- aerospace has no event for; the query takes ~30ms, so polling is cheap.
local observer = ui.add("item", "spaces_observer", {
  position = "left",
  drawing = false,
  updates = true,
  update_freq = 3,
})

ui.on(observer,
  { "routine", "forced", "aerospace_workspace_change", "front_app_switched" },
  refresh
)
