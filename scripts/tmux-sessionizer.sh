#!/usr/bin/env bash

# pastas fixas de busca (compartilhadas com o tmux-sessions.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./tmux-project-dirs.sh
source "$SCRIPT_DIR/tmux-project-dirs.sh"

# preview: eza se disponivel, senao ls simples (fzf roda o preview via /bin/sh,
# entao nao da pra depender de alias do fish)
if command -v eza >/dev/null 2>&1; then
    preview_cmd='eza --tree --level=2 --git-ignore --color=always {}'
else
    preview_cmd='ls -1 {}'
fi

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find "${TMUX_PROJECT_DIRS[@]}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | fzf --style full --preview "$preview_cmd" --bind 'ctrl-/:change-preview-window(down|hidden|)')
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr ' .' '__')
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

if ! tmux has-session -t="$selected_name" 2>/dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"
fi

if [[ -z $TMUX ]]; then
    tmux attach-session -t "$selected_name"
else
    tmux switch-client -t "$selected_name"
fi
