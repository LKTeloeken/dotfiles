#!/usr/bin/env sh

# Identifica a porta Wi-Fi (interface de rede sem fio)
WirelessPort=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $NF}')
[ -z "$WirelessPort" ] && WirelessPort="en0"   # se não encontrar, assume "en0" por padrão

# Obtém status do Wi-Fi (nome da rede ou mensagem de desconectado)
wifi_status=$(networksetup -getairportnetwork "$WirelessPort")

# Define os ícones para conectado e desconectado (usar glifos Nerd Font compatíveis)
connected_icon=""       # ícone Wi-Fi (conectado)
disconnected_icon="󰤮"    # ícone Wi-Fi com desconexão (por exemplo, um Wi-Fi off)

# Verifica se não está conectado a nenhuma rede Wi-Fi
if echo "$wifi_status" | grep -q "You are not associated"; then
    # Não há Wi-Fi conectado; tenta verificar se existe *alguma* conexão à internet (ex: via Ethernet)
    if ping -c 1 1.1.1.1 >/dev/null 2>&1; then
        # Consegue alcançar um host externo, considera como conectado (provavelmente via cabo)
        sketchybar --set $NAME icon="$connected_icon"
    else
        # Sem conexão à internet
        sketchybar --set $NAME icon="$disconnected_icon"
    fi
else
    # Wi-Fi está conectado (wifi_status retornou o SSID da rede)
    sketchybar --set $NAME icon="$connected_icon"
fi