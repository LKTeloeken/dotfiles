-- Battery: level icon (bolt while on AC) and percentage.

local S = require("styles")
local ui = require("ui")

local battery = ui.add("item", "battery", {
  position = "right",
  update_freq = 10,
  icon = { font = S.FONT_SF, color = S.DEFAULT_ICON_COLOR },
  label = { color = S.CONTENT_LABEL_COLOR },
})

local function icon_for(percent, charging)
  if charging then return "􀋦" end
  if percent >= 90 then return "􀛨" end
  if percent >= 60 then return "􀺸" end
  if percent >= 30 then return "􀺶" end
  if percent >= 10 then return "􀛩" end
  return "􀛪"
end

local function refresh()
  sbar.exec("pmset -g batt", function(result)
    if type(result) ~= "string" then return end
    local percent = tonumber(result:match("(%d+)%%"))
    if not percent then return end -- desktop Mac, no battery
    local charging = result:find("AC Power", 1, true) ~= nil
    sbar.animate("tanh", 10, function()
      battery:set({
        icon = { string = icon_for(percent, charging) },
        label = { string = percent .. "%" },
      })
    end)
  end)
end

ui.on(battery, { "routine", "forced", "system_woke", "power_source_change" }, refresh)
