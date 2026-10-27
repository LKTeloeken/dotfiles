-- Media widget: [ cover ][ eq ][ title — artist ] pill, popup with a large
-- cover, the track and transport controls.
--
-- Events come from plugins/media_forward.sh as `media_update`. Everything that
-- used to be spread across media.sh, media_click.sh, media_eq.sh and the state
-- file now lives here: one process, no pid files, and the equalizer is a timer
-- instead of a bash loop spawning sketchybar five times a second.

local S = require("styles")
local ui = require("ui")

local CONFIG_DIR = os.getenv("CONFIG_DIR")
local PLUGIN_DIR = CONFIG_DIR .. "/plugins"
local CACHE_DIR = S.MEDIA_CACHE_DIR or "/tmp/sketchybar_media"

local ART_SIZE = S.num("MEDIA_ART_SIZE")
local ART_RADIUS = S.num("MEDIA_ART_RADIUS")
local POPUP_ART_SIZE = S.num("MEDIA_POPUP_ART_SIZE")
local POPUP_ART_RADIUS = S.num("MEDIA_POPUP_ART_RADIUS")
local INDENT = S.num("POPUP_ROW_INDENT")

-- Fixed text widths, so neither the bar pill nor the popup changes size from
-- one track to the next. The label font is monospaced (Hack: 7.22pt per char
-- at 12pt, 6.62pt at 11pt), which turns a width into an exact character count.
-- Note that sketchybar's label.width includes the label's own paddings.
local BAR_CHARS = S.num("MEDIA_LABEL_MAX_CHARS")
local BAR_PAD_LEFT, BAR_PAD_RIGHT = 6, 10
local BAR_LABEL_WIDTH = math.ceil(BAR_CHARS * 7.22) + BAR_PAD_LEFT + BAR_PAD_RIGHT
-- Text area of the popup rows. Every text row is exactly this plus the indent
-- on both sides, which makes it the popup's width; the cover and the controls
-- are narrower and centered in it.
local POPUP_TEXT_WIDTH = 140
local POPUP_ROW_WIDTH = POPUP_TEXT_WIDTH + 2 * INDENT
local TITLE_CHARS = math.floor(POPUP_TEXT_WIDTH / 7.22)
local ARTIST_CHARS = math.floor(POPUP_TEXT_WIDTH / 6.62)
local EQ_INTERVAL = S.num("MEDIA_EQ_INTERVAL") or 0.18

-- MediaRemote briefly reports "nothing playing" between tracks. Hiding straight
-- away would make the widget flicker, so an empty state must last this long.
local HIDE_GRACE = 2
-- MediaRemote often publishes the title before the cover: retry after these.
local ART_RETRIES = { 1, 2, 4 }

-- Hand-picked so consecutive frames differ on every bar - a random walk reads
-- as noise, this reads as a meter.
local EQ_FRAMES = {
  "▁▃▂", "▂▅▄", "▄▇▅", "▆▅▇", "▇▃▆", "▅▂▄",
  "▃▄▂", "▂▆▃", "▄▇▆", "▇▄▇", "▅▂▅", "▃▁▃",
}
local EQ_IDLE = "▁▁▁"

-- Only these players show up. media-control reports whatever owns "Now
-- Playing" (a browser tab included), so this keeps it to music apps.
local allowed = {}
for bundle in (S.MEDIA_BUNDLES or "com.apple.Music com.spotify.client"):gmatch("%S+") do
  allowed[bundle] = true
end

-- --- bar items (right side is added right to left) ---

local info = ui.add("item", "media.info", {
  position = "right",
  drawing = false,
  icon = { drawing = false },
  background = { drawing = false },
  label = {
    color = S.CONTENT_LABEL_COLOR,
    font = S.FONT_LABEL_DEFAULT,
    width = BAR_LABEL_WIDTH,
    padding_left = BAR_PAD_LEFT,
    padding_right = BAR_PAD_RIGHT,
  },
})

local eq = ui.add("item", "media.eq", {
  position = "right",
  drawing = false,
  label = { drawing = false },
  background = { drawing = false },
  icon = {
    string = EQ_IDLE,
    font = S.FONT_MONO_BOLD,
    color = S.COLOR_PRIMARY,
    padding_left = 4,
    padding_right = 2,
  },
})

local art = ui.add("item", "media.art", {
  position = "right",
  drawing = false,
  updates = true,
  width = ART_SIZE + 8,
  label = { drawing = false },
  icon = { drawing = false, font = S.FONT_SF, color = S.COLOR_PRIMARY },
  background = {
    drawing = true,
    color = S.COLOR_TRANSPARENT,
    height = ART_SIZE,
    corner_radius = ART_RADIUS,
    image = { scale = 0.5, corner_radius = ART_RADIUS },
  },
  popup = ui.popup("center", "center"),
})

-- The pill behind the three items. Members are named explicitly so the popup
-- items below are never pulled into the bracket.
local pill = ui.add("bracket", "media", { art.name, eq.name, info.name }, {
  background = {
    drawing = false,
    color = S.DEFAULT_BACKGROUND_COLOR,
    border_width = S.num("ITEM_BG_BORDER_WIDTH"),
    corner_radius = S.num("ITEM_BG_CORNER_RADIUS"),
    height = S.num("ITEM_BG_HEIGHT"),
  },
})

-- --- popup ---

local POPUP = "popup." .. art.name

-- The image is drawn centred in the background box, so the box is exactly the
-- art size. Being in a `row` of its own lets popup.row_align center it.
local popup_art = ui.add("item", "media.popup.art", {
  position = POPUP,
  row = "media.cover",
  drawing = false,
  icon = { drawing = false },
  label = { drawing = false },
  width = POPUP_ART_SIZE,
  padding_left = 0,
  padding_right = 0,
  background = {
    drawing = true,
    color = S.COLOR_TRANSPARENT,
    padding_left = 0,
    padding_right = 0,
    height = POPUP_ART_SIZE,
    corner_radius = POPUP_ART_RADIUS,
    image = { scale = 0.5, corner_radius = POPUP_ART_RADIUS },
  },
})

local function text_row(name, props)
  local row = ui.popup_row("", "")
  row.position = POPUP
  row.icon.drawing = false
  row.label.padding_left = INDENT
  for key, value in pairs(props) do row.label[key] = value end
  return ui.add("item", name, row)
end

local popup_title = text_row("media.popup.title", { width = POPUP_ROW_WIDTH })
local popup_artist = text_row("media.popup.artist", {
  width = POPUP_ROW_WIDTH,
  font = S.FONT_LABEL_SMALL,
  color = S.POPUP_SUBLABEL_COLOR,
})

-- Transport controls share one popup row (the `row` property comes from our
-- sketchybar fork), centered under the cover via popup.row_align.
local function control(name, icon)
  local props = ui.icon_button(icon, "media.controls")
  props.position = POPUP
  return ui.add("item", name, props)
end

local popup_prev = control("media.popup.prev", "􀊊")
local popup_play = control("media.popup.play", "􀊆")
local popup_next = control("media.popup.next", "􀊌")

-- --- equalizer ---

local eq_gen = 0

local function eq_start()
  eq_gen = eq_gen + 1
  local gen, frame = eq_gen, 0
  local function tick()
    if gen ~= eq_gen then return end
    frame = frame % #EQ_FRAMES + 1
    eq:set({ icon = { string = EQ_FRAMES[frame] } })
    sbar.delay(EQ_INTERVAL, tick)
  end
  tick()
end

local function eq_stop()
  eq_gen = eq_gen + 1
  eq:set({ icon = { string = EQ_IDLE } })
end

-- --- state ---

local current_key = nil   -- artwork cache key of the track on screen
local current_state = nil -- "playing" / "paused"
local shown = nil         -- full signature of the last rendered event
local hide_gen = 0

-- 32-bit FNV-1a: only names cache files, collisions just mean a wrong cover.
local function hash(text)
  local h = 2166136261
  for i = 1, #text do
    h = ((h ~ text:byte(i)) * 16777619) & 0xffffffff
  end
  return string.format("%08x", h)
end

local function file_ok(path)
  local file = io.open(path, "rb")
  if not file then return false end
  local size = file:seek("end")
  file:close()
  return size > 0
end

local function art_paths(key)
  return CACHE_DIR .. "/" .. key .. "_sm.jpg", CACHE_DIR .. "/" .. key .. "_lg.jpg"
end

local function apply_art(key)
  local small, large = art_paths(key)
  if file_ok(small) then
    art:set({ icon = { drawing = false }, background = { image = { string = small, drawing = true } } })
  else
    -- No cover available: a note glyph in the same slot.
    art:set({ icon = { string = "􀑪", drawing = true }, background = { image = { drawing = false } } })
  end
  if file_ok(large) then
    popup_art:set({ drawing = true, background = { image = { string = large, drawing = true } } })
  else
    popup_art:set({ drawing = false })
  end
end

-- Fetches the cover and renders both sizes, at 2x so they stay sharp on retina.
local function store_art(key, done)
  local small, large = art_paths(key)
  local raw = CACHE_DIR .. "/" .. key .. "_raw"
  local cmd = string.format(
    "mkdir -p %q; media-control get 2>/dev/null | jq -r '.artworkData // empty' "
      .. "| base64 -D > %q 2>/dev/null; "
      .. "if [ -s %q ]; then sips -Z %d %q --out %q >/dev/null 2>&1; "
      .. "sips -Z %d %q --out %q >/dev/null 2>&1; fi; rm -f %q; "
      .. "touch -c %q %q; %q maybe-prune; [ -s %q ]",
    CACHE_DIR, raw, raw,
    ART_SIZE * 2, raw, small,
    POPUP_ART_SIZE * 2, raw, large,
    raw, small, large, PLUGIN_DIR .. "/media_cache.sh", small
  )
  ui.exec(cmd, function(_, exit_code) done(exit_code == 0) end)
end

local function load_art(key, attempt)
  attempt = attempt or 0
  store_art(key, function(ok)
    if key ~= current_key then return end -- track changed meanwhile
    if ok then
      apply_art(key)
    elseif attempt < #ART_RETRIES then
      sbar.delay(ART_RETRIES[attempt + 1], function()
        if key == current_key then load_art(key, attempt + 1) end
      end)
    end
  end)
end

local function hide()
  shown, current_key = nil, nil
  for _, item in ipairs({ art, eq, info }) do item:set({ drawing = false }) end
  pill:set({ background = { drawing = false } })
  art:set({ popup = { drawing = false } })
  eq_stop()
  current_state = nil
end

local function set_play_button(state)
  if state == "playing" then
    popup_play:set({ icon = { string = "􀊆" } })
  else
    popup_play:set({ icon = { string = "􀊄" } })
  end
end

local function render(track)
  local key = hash(table.concat({ track.bundle, track.artist, track.album, track.title }, "|"))

  pill:set({ background = { drawing = true } })
  eq:set({ drawing = true })
  info:set({ drawing = true, label = {
    string = ui.truncate(track.title .. " — " .. track.artist, BAR_CHARS),
  } })
  popup_title:set({ label = { string = ui.truncate(track.title, TITLE_CHARS) } })
  popup_artist:set({ label = {
    string = ui.truncate(track.artist .. " — " .. track.album, ARTIST_CHARS),
  } })
  set_play_button(track.state)

  if key ~= current_key then
    current_key = key
    -- Cached covers show at once; otherwise the glyph shows until the fetch
    -- (or one of its retries) lands.
    apply_art(key)
    art:set({ drawing = true })
    load_art(key)
  end

  if track.state ~= current_state then
    current_state = track.state
    if track.state == "playing" then eq_start() else eq_stop() end
  end
end

-- --- events ---

ui.add("event", "media_update")

ui.on(art, "media_update", function(env)
  local track = {
    bundle = env.BUNDLE or "",
    state = env.STATE or "paused",
    title = env.TITLE or "",
    artist = env.ARTIST or "",
    album = env.ALBUM or "",
  }

  if track.title == "" or not allowed[track.bundle] then
    -- Nothing (or something that is not music) is playing. Hide only if that
    -- outlasts the grace period; a new track bumps hide_gen and cancels it.
    if shown then
      shown = nil
      hide_gen = hide_gen + 1
      local gen = hide_gen
      sbar.delay(HIDE_GRACE, function()
        if gen == hide_gen then hide() end
      end)
    end
    return
  end

  hide_gen = hide_gen + 1
  local signature = table.concat({ track.bundle, track.state, track.title, track.artist, track.album }, "\31")
  if signature == shown then return end
  shown = signature
  render(track)
end)

local function toggle_popup()
  art:set({ popup = { drawing = "toggle" } })
end

for _, item in ipairs({ art, eq, info }) do
  ui.on(item, "mouse.clicked", toggle_popup)
end
ui.press_feedback({ art, eq, info }, pill, S.DEFAULT_BACKGROUND_COLOR)

ui.on(art, "mouse.exited.global", function()
  art:set({ popup = { drawing = false } })
end)

ui.button(popup_prev, function()
  ui.exec("media-control previous-track")
end)

ui.button(popup_next, function()
  ui.exec("media-control next-track")
end)

-- Flip the button right away; the stream confirms (or corrects) it shortly.
ui.button(popup_play, function()
  set_play_button(current_state == "playing" and "paused" or "playing")
  ui.exec("media-control toggle-play-pause")
end)

ui.exec(string.format("%q start", PLUGIN_DIR .. "/media_forward.sh"))
