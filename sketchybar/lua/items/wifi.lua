-- Wi-Fi: icon in the bar, popup with signal, address, link rate and a power
-- toggle. The network name is not shown: macOS redacts the SSID for apps
-- without Location access (see helpers/wifi.swift).

local S = require("styles")
local ui = require("ui")

local HELPER = os.getenv("CONFIG_DIR") .. "/helpers/bin/wifi"
local ICON_ON = "􀙇"
local ICON_OFF = "􀙈"

local wifi = ui.add("item", "wifi", {
  position = "right",
  update_freq = 15,
  icon = { string = ICON_ON, font = S.FONT_SF, color = S.DEFAULT_ICON_COLOR },
  label = { drawing = false },
  popup = ui.popup("right"),
})

local POPUP = "popup." .. wifi.name

local function info_row(name, icon)
  local props = ui.popup_row(icon, "")
  props.position = POPUP
  return ui.add("item", name, props)
end

local power_row = info_row("wifi.power", ICON_ON)
local signal_row = info_row("wifi.signal", "􀖀")
local ip_row = info_row("wifi.ip", "􀤆")
local rate_row = info_row("wifi.rate", "􀍽")
local settings_row = info_row("wifi.settings", "􀍟")
settings_row:set({ label = { string = "Configurações de Wi-Fi…" } })

-- --- state ---

local state = { power = true, connected = false }
local open = false

local function quality(rssi)
  if rssi >= -60 then return "Ótimo" end
  if rssi >= -70 then return "Bom" end
  if rssi >= -80 then return "Fraco" end
  return "Ruim"
end

local function render()
  local icon, color = ICON_ON, S.DEFAULT_ICON_COLOR
  if not state.power then
    icon, color = ICON_OFF, S.POPUP_SUBLABEL_COLOR
  elseif not state.connected then
    color = S.POPUP_SUBLABEL_COLOR
  end
  wifi:set({ icon = { string = icon, color = color } })

  power_row:set({
    icon = { string = state.power and ICON_ON or ICON_OFF },
    label = { string = state.power and "Wi-Fi ligado" or "Wi-Fi desligado" },
  })

  local details = state.power and state.connected
  for _, row in ipairs({ signal_row, ip_row, rate_row }) do
    row:set({ drawing = details })
  end
  if details then
    signal_row:set({ label = { string = string.format("Sinal %s (%d dBm)", quality(state.rssi), state.rssi) } })
    ip_row:set({ label = { string = state.ip ~= "" and state.ip or "Sem endereço IP" } })
    rate_row:set({ label = { string = string.format("%d Mbps", state.tx) } })
  end
end

local function refresh()
  sbar.exec(string.format("%q", HELPER), function(result)
    if type(result) ~= "table" then return end
    state = result
    render()
  end)
end

-- --- events ---

ui.on(wifi, { "routine", "forced", "wifi_change", "system_woke" }, refresh)

ui.on(wifi, "mouse.clicked", function()
  open = not open
  if open then refresh() end
  wifi:set({ popup = { drawing = open } })
end)

ui.on(wifi, "mouse.exited.global", function()
  open = false
  wifi:set({ popup = { drawing = false } })
end)

ui.press_feedback({ wifi }, wifi, S.DEFAULT_BACKGROUND_COLOR)

-- Flips the UI at once; the radio takes a couple of seconds to settle, so the
-- real state is read back after that.
ui.button(power_row, function()
  state = { power = not state.power, connected = false }
  render()
  sbar.exec(string.format("%q power %s", HELPER, state.power and "on" or "off"), function()
    sbar.delay(3, refresh)
  end)
end)

ui.button(settings_row, function()
  open = false
  wifi:set({ popup = { drawing = false } })
  sbar.exec("open 'x-apple.systempreferences:com.apple.wifi-settings-extension'")
end)
