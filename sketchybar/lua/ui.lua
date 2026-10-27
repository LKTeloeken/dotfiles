-- Shared building blocks for Lua items.

local S = require("styles")

local ui = {}

-- Popup container style. row_align (our fork) places items that share a `row`.
function ui.popup(align, row_align)
  return {
    align = align or "center",
    row_align = row_align or "left",
    horizontal = false,
    height = S.num("POPUP_HEIGHT"),
    blur_radius = S.num("POPUP_BLUR_RADIUS"),
    background = {
      color = S.POPUP_BG_COLOR,
      border_color = S.POPUP_BORDER_COLOR,
      border_width = S.num("POPUP_BORDER_WIDTH"),
      corner_radius = S.num("POPUP_CORNER_RADIUS"),
    },
  }
end

-- SbarLua keeps a single callback per (item, event): a second item:subscribe
-- for the same event silently replaces the first. ui.on keeps a list instead,
-- so helpers like ui.button can add handlers next to the item's own.
local handlers = {}

function ui.on(item, events, fn)
  if type(events) == "string" then events = { events } end
  for _, event in ipairs(events) do
    local key = item.name .. "\0" .. event
    local list = handlers[key]
    if not list then
      list = {}
      handlers[key] = list
      item:subscribe(event, function(env)
        for _, handler in ipairs(list) do handler(env) end
      end)
    end
    list[#list + 1] = fn
  end
end

-- Props for a clickable popup row: icon + label, no background until hovered.
function ui.popup_row(icon, label)
  local indent = S.num("POPUP_ROW_INDENT")
  return {
    icon = {
      string = icon,
      font = S.FONT_SF,
      color = S.POPUP_ICON_COLOR,
      padding_left = indent,
      padding_right = 6,
    },
    label = {
      string = label,
      font = S.FONT_LABEL_DEFAULT,
      color = S.POPUP_LABEL_COLOR,
      padding_left = 4,
      padding_right = indent,
    },
    background = {
      drawing = false,
      corner_radius = 6,
      height = S.num("POPUP_HEIGHT") - 4,
    },
  }
end

-- Collects every `drawing = false` in a property table, keeping its nesting.
local function hidden_parts(props)
  local out, found = {}, false
  for key, value in pairs(props) do
    if key == "drawing" and value == false then
      out.drawing, found = false, true
    elseif type(value) == "table" then
      local sub = hidden_parts(value)
      if sub then out[key], found = sub, true end
    end
  end
  return found and out or nil
end

-- sbar.add with one fix: SbarLua sends a table's keys in arbitrary order, and
-- sketchybar turns a background on whenever it receives a color. So
-- `background = { drawing = false, color = X }` sometimes ends up visible.
-- Re-sending just the `drawing = false` parts afterwards makes it deterministic.
function ui.add(kind, name, ...)
  local args = { ... }
  local props = args[#args]
  local item = sbar.add(kind, name, ...)
  local hidden = type(props) == "table" and hidden_parts(props)
  if hidden then item:set(hidden) end
  return item
end

-- Highlights an item while the pointer is over it. This used to cost a process
-- per enter/exit; here it is a callback in the already running Lua process.
function ui.hover(item)
  ui.on(item, "mouse.entered", function()
    item:set({ background = { drawing = true, color = S.COLOR_SURFACE_SOFT } })
  end)
  ui.on(item, { "mouse.exited", "mouse.exited.global" }, function()
    item:set({ background = { drawing = false } })
  end)
end

-- Props for an icon-only popup button, meant to sit in a `row` with others.
function ui.icon_button(icon, row)
  return {
    row = row,
    icon = {
      string = icon,
      font = S.FONT_SF_LARGE or "SF Pro:Regular:16.0",
      color = S.POPUP_ICON_COLOR,
      padding_left = 10,
      padding_right = 10,
    },
    label = { drawing = false },
    -- Shorter than the popup cell: a taller background would make the row grow
    -- (and the popup jump) whenever the hover highlight shows up.
    background = {
      drawing = false,
      corner_radius = 8,
      height = S.num("POPUP_HEIGHT") - 2,
    },
  }
end

-- Hover highlight plus a stronger "pressed" fill between mouse down and up.
-- mouse.pressed comes from our sketchybar fork; on stock sketchybar it simply
-- never fires and the item still works, just without the pressed state.
function ui.button(item, on_click)
  local hovered = false
  local function paint(color)
    item:set({ background = { drawing = color ~= nil, color = color } })
  end
  ui.on(item, "mouse.entered", function()
    hovered = true
    paint(S.COLOR_SURFACE_SOFT)
  end)
  ui.on(item, { "mouse.exited", "mouse.exited.global" }, function()
    hovered = false
    paint(nil)
  end)
  ui.on(item, "mouse.pressed", function()
    paint(S.COLOR_PRIMARY_BG_MEDIUM)
  end)
  ui.on(item, "mouse.clicked", function(env)
    paint(hovered and S.COLOR_SURFACE_SOFT or nil)
    if on_click then on_click(env) end
  end)
end

-- Press feedback for a bar pill: dims `target`'s background while any of
-- `items` is held down.
function ui.press_feedback(items, target, normal_color)
  for _, item in ipairs(items) do
    ui.on(item, "mouse.pressed", function()
      target:set({ background = { color = S.COLOR_SURFACE_BG } })
    end)
    ui.on(item, { "mouse.clicked", "mouse.exited" }, function()
      target:set({ background = { color = normal_color } })
    end)
  end
end

-- Cuts `text` to at most `max` characters, ending in "…" when it had to cut.
-- Counts UTF-8 characters, not bytes, so accented titles are not split
-- mid-character. Paired with a fixed label width, this keeps an item from
-- resizing whenever its text changes.
function ui.truncate(text, max)
  local length = utf8.len(text)
  if not length then return text:sub(1, max) end -- invalid UTF-8: best effort
  if length <= max then return text end
  return text:sub(1, utf8.offset(text, max) - 1) .. "…"
end

-- Runs a command with the PATH our helpers need. sketchybar is started by
-- launchd with a bare PATH, so Homebrew and ~/.local/bin are missing. Exported
-- rather than prefixed, so it also reaches every stage of a pipeline.
local PATH_PREFIX = "export PATH=/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH; "

function ui.exec(command, callback)
  if callback then
    sbar.exec(PATH_PREFIX .. command, callback)
  else
    sbar.exec(PATH_PREFIX .. command)
  end
end

return ui
