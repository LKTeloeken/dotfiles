#!/usr/bin/env bash
#
# Pastas fixas onde os projetos sao procurados.
#
# Fonte unica de verdade: usada tanto pelo tmux-sessionizer.sh quanto pelo
# tmux-sessions.sh (o gerenciador de sessoes do Ctrl+F). Pra adicionar ou
# remover um diretorio de busca, edite so este arquivo.

TMUX_PROJECT_DIRS=(
    "$HOME/projects/personal"
    "$HOME/Documents/projects/personal"
    "$HOME/Documents/projects/work/suitable"
    "$HOME/Documents/projects/unisc"
)
