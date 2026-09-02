#!/usr/bin/env bash
#
# Gerenciador simples de sessoes do tmux (abre com Ctrl+F).
#
#   enter   -> abre a sessao (criando ela a partir do projeto, se preciso)
#   ctrl-x  -> mata a sessao selecionada
#   ctrl-o  -> alterna a ordenacao (nome <-> uso mais recente)
#
# A lista mostra as sessoes existentes seguidas dos projetos das pastas fixas
# definidas em tmux-project-dirs.sh — nao varre o computador inteiro.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
# shellcheck source=./tmux-project-dirs.sh
source "$SCRIPT_DIR/tmux-project-dirs.sh"

SORT_STATE="${TMPDIR:-/tmp}/tmux-sessions-sort"

# Mesma normalizacao usada pelo tmux-sessionizer.sh, pra que os dois criem
# sessoes com o mesmo nome pro mesmo projeto.
session_name_for() {
    basename "$1" | tr ' .' '__'
}

sort_mode() {
    local mode
    mode=$(cat "$SORT_STATE" 2>/dev/null)
    [[ $mode == "recent" ]] && echo "recent" || echo "name"
}

toggle_sort() {
    if [[ $(sort_mode) == "name" ]]; then
        echo "recent" >"$SORT_STATE"
    else
        echo "name" >"$SORT_STATE"
    fi
}

# Cada linha tem 3 campos separados por TAB: tipo, texto exibido, alvo.
# O fzf mostra so o campo 2 (--with-nth=2) e usa 1 e 3 nos binds.
list_entries() {
    local sessions name path parent
    if [[ $(sort_mode) == "recent" ]]; then
        sessions=$(tmux list-sessions -F '#{session_last_attached} #{session_name}' 2>/dev/null |
            sort -rn | cut -d' ' -f2-)
    else
        sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | sort -f)
    fi

    while IFS= read -r name; do
        [[ -z $name ]] && continue
        printf 'S\t\033[32m\033[0m %s\t%s\n' "$name" "$name"
    done <<<"$sessions"

    while IFS= read -r path; do
        [[ -z $path ]] && continue
        grep -Fxq "$(session_name_for "$path")" <<<"$sessions" && continue
        parent=$(dirname "$path")
        [[ $parent == "$HOME"/* ]] && parent="~${parent#$HOME}"
        printf 'P\t\033[90m\033[0m %s \033[90m%s\033[0m\t%s\n' \
            "$(basename "$path")" "$parent" "$path"
    done < <(find "${TMUX_PROJECT_DIRS[@]}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null |
        awk -F/ '{print tolower($NF) "\t" $0}' | sort -f | cut -f2-)
}

kill_entry() {
    local tag=$1 target=$2 current other
    [[ $tag != "S" || -z $target ]] && return 0

    # Se for a sessao atual, pula pra outra antes de matar — senao o cliente
    # cai fora junto com o popup.
    current=$(tmux display-message -p '#S')
    if [[ $target == "$current" ]]; then
        other=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -Fxv "$target" | head -n1)
        [[ -z $other ]] && return 0
        tmux switch-client -t "=$other"
    fi
    tmux kill-session -t "=$target" 2>/dev/null
}

open_entry() {
    local tag=$1 target=$2
    [[ -z $target ]] && return 0

    if [[ $tag == "P" ]]; then
        local dir=$target
        target=$(session_name_for "$dir")
        tmux has-session -t "=$target" 2>/dev/null || tmux new-session -ds "$target" -c "$dir"
    fi

    if [[ -z ${TMUX:-} ]]; then
        tmux attach-session -t "=$target"
    else
        tmux switch-client -t "=$target"
    fi
}

# Subcomandos usados de dentro do fzf (reload/execute-silent).
case ${1:-menu} in
list)
    [[ ${2:-} == "toggle" ]] && toggle_sort
    list_entries
    exit 0
    ;;
kill)
    kill_entry "${2:-}" "${3:-}"
    exit 0
    ;;
esac

selected=$(list_entries | fzf \
    --ansi \
    --delimiter=$'\t' \
    --with-nth=2 \
    --tiebreak=index \
    --no-multi \
    --exit-0 \
    --info=inline \
    --prompt='  ' \
    --pointer='▌' \
    --header='enter abrir · ctrl-x matar · ctrl-o ordenar' \
    --header-first \
    --bind "ctrl-x:execute-silent('$SCRIPT' kill {1} {3})+reload('$SCRIPT' list)" \
    --bind "ctrl-o:reload('$SCRIPT' list toggle)")

[[ -z $selected ]] && exit 0

open_entry "$(cut -f1 <<<"$selected")" "$(cut -f3 <<<"$selected")"
