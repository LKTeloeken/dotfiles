-- Brightness: icon + level of the main screen in the bar, popup with one
-- slider per display. Scrolling on the icon changes the main screen.
--
-- helpers/brightness talks DisplayServices for the built-in panel and DDC/CI
-- for an external monitor; displays it cannot reach are simply left out.

local S = require("styles")
local ui = require("ui")

local HELPER = os.getenv("CONFIG_DIR") .. "/helpers/bin/brightness"
local STEP = 5
-- Same reason as in volume.lua: ignore refreshes right after a local change,
-- they may still read the previous value.
local ECHO_WINDOW = 1.0

local DISPLAYS = {
  { key = "external", label = "Monitor" },
  { key = "builtin", label = "MacBook" },
}

local brightness = ui.add("item", "brightness", {
  position = "right",
  drawing = false,
  update_freq = 30,
  icon = { string = "􀆭", font = S.FONT_SF, color = S.DEFAULT_ICON_COLOR },
  label = { color = S.CONTENT_LABEL_COLOR },
  popup = ui.popup("center"),
})

local POPUP = "popup." .. brightness.name

-- One row per display: name, then the slider next to it.
local rows = {}
for _, display in ipairs(DISPLAYS) do
  local row = "brightness." .. display.key
  local name_props = ui.popup_row("", display.label)
  name_props.position = POPUP
  name_props.row = row
  name_props.drawing = false
  name_props.icon.drawing = false
  name_props.label.width = 72

  local slider = ui.add("slider", row .. ".slider", 120, {
    position = POPUP,
    row = row,
    drawing = false,
    icon = { drawing = false },
    label = { drawing = false },
    background = { drawing = false },
    padding_left = 0,
    padding_right = 12,
    slider = {
      knob = "􀀁",
      highlight_color = S.COLOR_PRIMARY,
      background = { height = 6, corner_radius = 3, color = S.COLOR_SURFACE },
    },
  })

  rows[display.key] = {
    name = ui.add("item", row .. ".name", name_props),
    slider = slider,
  }
end

-- --- state ---

local levels = {} -- display key -> 0..100
local echo_gen, ignoring_echo = 0, false
local open = false

local function main_display()
  if levels.external then return "external" end
  if levels.builtin then return "builtin" end
  return nil
end

local function render()
  local main = main_display()
  brightness:set({ drawing = main ~= nil })
  if not main then return end
  brightness:set({ label = { string = levels[main] .. "%" } })
  for key, row in pairs(rows) do
    local present = levels[key] ~= nil
    row.name:set({ drawing = present })
    row.slider:set({ drawing = present })
    if present then row.slider:set({ slider = { percentage = levels[key] } }) end
  end
end

local function refresh()
  if ignoring_echo then return end
  sbar.exec(string.format("%q get", HELPER), function(result)
    if type(result) ~= "table" or ignoring_echo then return end
    levels = { external = tonumber(result.external), builtin = tonumber(result.builtin) }
    render()
  end)
end

-- One helper call in flight per display; newer targets replace pending ones,
-- so dragging or a fast scroll ends up as a couple of writes.
local applying, wanted = {}, {}

local function push(key)
  if applying[key] or not wanted[key] then return end
  local target = wanted[key]
  wanted[key] = nil
  applying[key] = true
  sbar.exec(string.format("%q set %s %d", HELPER, key, target), function()
    applying[key] = false
    push(key)
  end)
end

local function set_level(key, value)
  if not levels[key] then return end
  levels[key] = math.max(0, math.min(100, math.floor(value + 0.5)))
  echo_gen = echo_gen + 1
  ignoring_echo = true
  local gen = echo_gen
  sbar.delay(ECHO_WINDOW, function()
    if gen == echo_gen then ignoring_echo = false end
  end)
  render()
  wanted[key] = levels[key]
  push(key)
end

-- --- events ---

ui.on(brightness, { "routine", "forced", "brightness_change", "system_woke" }, refresh)

ui.on(brightness, "mouse.scrolled", function(env)
  local delta = tonumber(env.SCROLL_DELTA) or 0
  local main = main_display()
  if delta == 0 or not main then return end
  set_level(main, levels[main] + (delta < 0 and -STEP or STEP))
end)

ui.on(brightness, "mouse.clicked", function()
  open = not open
  if open then refresh() end
  brightness:set({ popup = { drawing = open } })
end)

ui.on(brightness, "mouse.exited.global", function()
  open = false
  brightness:set({ popup = { drawing = false } })
end)

ui.press_feedback({ brightness }, brightness, S.DEFAULT_BACKGROUND_COLOR)

for key, row in pairs(rows) do
  ui.on(row.slider, "mouse.clicked", function(env)
    local value = tonumber(env.PERCENTAGE)
    if value then set_level(key, value) end
  end)
end
