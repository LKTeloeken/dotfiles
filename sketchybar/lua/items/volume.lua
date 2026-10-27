-- Volume widget: icon + percentage, popup with a slider and a mute row.
--
-- The bash version paid ~110ms per osascript call, two or three of them per
-- scroll step. Here the state lives in this process: input repaints at once,
-- and osascript only runs in the background to apply the change.

local S = require("styles")
local ui = require("ui")

local STEP = 5
-- How long to ignore volume_change after a local change. Our own writes echo
-- back as events, and during a fast scroll a stale echo would make the
-- percentage jump backwards.
local ECHO_WINDOW = 0.4

local volume = ui.add("item", "volume", {
  position = "right",
  icon = { font = S.FONT_SF, color = S.DEFAULT_ICON_COLOR },
  label = { color = S.CONTENT_LABEL_COLOR },
  popup = ui.popup("center"),
})

local mute_props = ui.icon_button("􀊣", "volume.controls")
mute_props.position = "popup." .. volume.name
local mute_button = ui.add("item", "volume.mute", mute_props)

local slider = ui.add("slider", "volume.slider", 120, {
  position = "popup." .. volume.name,
  row = "volume.controls",
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = false },
  padding_left = 10,
  padding_right = 10,
  slider = {
    knob = "􀀁",
    highlight_color = S.COLOR_PRIMARY,
    background = {
      height = 6,
      corner_radius = 3,
      color = S.COLOR_SURFACE,
    },
  },
})


-- --- state ---

local level = nil -- 0..100, nil until the first read
local muted = false
local echo_gen = 0
local ignoring_echo = false

local function icon_for()
  if muted or level == 0 then return "􀊣" end
  if level >= 60 then return "􀊩" end
  if level >= 30 then return "􀊧" end
  return "􀊥"
end

local function render(animate)
  if not level then return end
  local apply = function()
    volume:set({ icon = { string = icon_for() }, label = { string = level .. "%" } })
    slider:set({ slider = { percentage = level } })
  end
  if animate then sbar.animate("tanh", 10, apply) else apply() end
  mute_button:set({ icon = { string = muted and "􀊣" or "􀊥" } })
end

local function hold_echo()
  echo_gen = echo_gen + 1
  ignoring_echo = true
  local gen = echo_gen
  sbar.delay(ECHO_WINDOW, function()
    if gen == echo_gen then ignoring_echo = false end
  end)
end

-- Reads volume and mute in one call. Used at startup and whenever sketchybar
-- reports 0, which is ambiguous: it sends 0 both for "muted" and "set to 0".
local function sync()
  ui.exec("osascript -e 'get volume settings'", function(result)
    if type(result) ~= "string" then return end
    local out = tonumber(result:match("output volume:(%d+)"))
    if not out then return end -- device without volume control (e.g. HDMI)
    level = out
    muted = result:match("output muted:(%a+)") == "true"
    render(false)
  end)
end

-- Only one osascript in flight. While it runs, newer targets overwrite each
-- other and only the last one is sent, so a fast scroll is one or two writes.
local applying = false
local wanted = nil

local function push_volume()
  if applying or not wanted then return end
  local target = wanted
  wanted = nil
  applying = true
  ui.exec("osascript -e 'set volume output volume " .. target .. "'", function()
    applying = false
    push_volume()
  end)
end

local function set_level(value)
  if not level then return end
  level = math.max(0, math.min(100, math.floor(value + 0.5)))
  hold_echo()
  render(false)
  wanted = level
  push_volume()
end

local function toggle_mute()
  muted = not muted
  hold_echo()
  render(false)
  ui.exec("osascript -e 'set volume output muted " .. tostring(muted) .. "'")
end

-- --- events ---

ui.on(volume, "volume_change", function(env)
  if ignoring_echo then return end
  local value = tonumber(env.INFO)
  if not value then return end
  if value == 0 then
    sync()
    return
  end
  level = value
  muted = false
  render(true)
end)

ui.on(volume, "mouse.clicked", function(env)
  if env.BUTTON == "right" then
    toggle_mute()
  else
    volume:set({ popup = { drawing = "toggle" } })
  end
end)

ui.on(volume, "mouse.scrolled", function(env)
  local delta = tonumber(env.SCROLL_DELTA) or 0
  if delta == 0 or not level then return end
  set_level(level + (delta < 0 and -STEP or STEP))
end)

ui.on(volume, "mouse.exited.global", function()
  volume:set({ popup = { drawing = false } })
end)

-- The slider reports where it was released in $PERCENTAGE.
ui.on(slider, "mouse.clicked", function(env)
  local value = tonumber(env.PERCENTAGE)
  if value then set_level(value) end
end)

ui.button(mute_button, toggle_mute)
ui.press_feedback({ volume }, volume, S.DEFAULT_BACKGROUND_COLOR)

sync()
