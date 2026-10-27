-- Focused app: icon from sketchybar-app-font plus the app name.

local S = require("styles")
local ui = require("ui")
local icon_for = require("icon_map")

-- Sits directly after the spaces bracket, which covers its own members'
-- padding, so front_app pays the whole gap on its side.
local front_app = ui.add("item", "front_app", {
  position = "left",
  padding_left = S.num("LEFT_ITEM_GAP"),
  icon = { font = S.FONT_FRONT_APP_ICON, color = S.DEFAULT_ICON_COLOR },
  label = { color = S.CONTENT_LABEL_COLOR },
  background = {
    color = S.DEFAULT_BACKGROUND_COLOR,
    border_width = S.num("ITEM_BG_BORDER_WIDTH"),
  },
})

ui.on(front_app, "front_app_switched", function(env)
  sbar.animate("tanh", 10, function()
    front_app:set({ icon = { string = icon_for(env.INFO) }, label = { string = env.INFO } })
  end)
end)
