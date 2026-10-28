# First: everything below (fastfetch, starship, zoxide) comes from Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

if status is-interactive
    # Commands to run in interactive sessions can go here

 fastfetch -c neofetch
end

set -U fish_greeting

if test -f $HOME/.config/colors/setup.fish
 source $HOME/.config/colors/setup.fish
end

starship init fish | source

# Global, not universal: fish_variables is machine-local and not in git
fish_add_path -g $HOME/go/bin /Applications/Ghostty.app/Contents/MacOS

if test -f $HOME/.local/bin/env.fish
 source $HOME/.local/bin/env.fish
end

zoxide init fish | source
fzf --fish | source

export FZF_CTRL_T_OPTS="
 --style full
 --walker-skip .git,node_modules,target
 --preview 'bat -n --color=always {}'
 --bind 'ctrl-/:change-preview-window(down|hidden|)'"


# Aliases
alias cd="z"
alias cat="bat"
alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"



# Aliases for python
alias uv_run="uv run manage.py runserver 0.0.0.0:8000"
alias uv_migrate="uv run manage.py migrate_schemas"

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/lucasteloeken/.lmstudio/bin
# End of LM Studio CLI section

