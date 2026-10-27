-- Clock, with a month calendar in the popup.
--
-- The calendar is a real grid: every day is its own item, and the items of a
-- week share a popup `row` (our sketchybar fork). That is what lets today be
-- highlighted on its own instead of the whole week line.

local S = require("styles")
local ui = require("ui")

local MONTHS = { "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho",
                 "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro" }
local WEEKDAYS = { "Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado" }
local WEEK_INITIALS = { "D", "S", "T", "Q", "Q", "S", "S" }

local CELL = 28
local WEEKS = 6

local date = ui.add("item", "date", {
  position = "right",
  update_freq = 5,
  icon = { string = "􀧞", font = S.FONT_SF, color = S.DEFAULT_ICON_COLOR },
  label = { color = S.CONTENT_LABEL_COLOR },
  popup = ui.popup("right", "center"),
})

local POPUP = "popup." .. date.name

local header = ui.add("item", "date.cal.header", {
  position = POPUP,
  icon = { drawing = false },
  background = { drawing = false },
  label = {
    font = S.FONT_LABEL_DEFAULT,
    color = S.COLOR_PRIMARY,
    padding_left = 12,
    padding_right = 12,
  },
})

local function cell(name, row, color)
  return ui.add("item", name, {
    position = POPUP,
    row = row,
    width = CELL,
    padding_left = 0,
    padding_right = 0,
    icon = { drawing = false },
    label = {
      font = S.FONT_MONO,
      color = color or S.POPUP_LABEL_COLOR,
      align = "center",
      width = CELL,
      padding_left = 0,
      padding_right = 0,
    },
    background = {
      drawing = false,
      height = CELL - 6,
      corner_radius = (CELL - 6) // 2,
    },
  })
end

for i, initial in ipairs(WEEK_INITIALS) do
  local initials = cell("date.cal.wd" .. i, "date.cal.weekdays", S.POPUP_SUBLABEL_COLOR)
  initials:set({ label = { string = initial } })
end

-- WEEKS x 7 cells, created once; opening the popup only relabels them.
local cells = {}
for week = 1, WEEKS do
  for day = 1, 7 do
    cells[#cells + 1] = cell(string.format("date.cal.w%d.%d", week, day), "date.cal.week" .. week)
  end
end

local function fill_month()
  local now = os.date("*t")
  local first_wday = os.date("*t", os.time({ year = now.year, month = now.month, day = 1 })).wday
  local days = os.date("*t", os.time({ year = now.year, month = now.month + 1, day = 0 })).day
  local weeks_used = math.ceil((first_wday - 1 + days) / 7)

  header:set({ label = {
    string = string.format("%s, %d de %s de %d", WEEKDAYS[now.wday], now.day, MONTHS[now.month], now.year),
  } })

  for index, item in ipairs(cells) do
    local day = index - first_wday + 1
    local in_month = day >= 1 and day <= days
    local is_today = day == now.day
    local weekend = (index - 1) % 7 == 0 or (index - 1) % 7 == 6
    item:set({
      -- Leading blanks stay drawn so the first week keeps its columns.
      drawing = index <= weeks_used * 7 and (in_month or index < first_wday),
      label = {
        string = in_month and tostring(day) or "",
        color = is_today and S.COLOR_BASE
          or (weekend and S.POPUP_SUBLABEL_COLOR or S.POPUP_LABEL_COLOR),
      },
      -- No color on the hidden case: a color would switch the background back on.
      background = is_today and { drawing = true, color = S.COLOR_PRIMARY } or { drawing = false },
    })
  end
end

ui.on(date, { "routine", "forced", "system_woke" }, function()
  date:set({ label = { string = os.date("%d %b  -  %H:%M") } })
end)

local open = false

ui.on(date, "mouse.clicked", function()
  open = not open
  -- Refilled on every open so the grid never goes stale across midnight or a
  -- month boundary.
  if open then fill_month() end
  date:set({ popup = { drawing = open } })
end)

ui.on(date, "mouse.exited.global", function()
  open = false
  date:set({ popup = { drawing = false } })
end)

ui.press_feedback({ date }, date, S.DEFAULT_BACKGROUND_COLOR)
