if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -x N_PREFIX "$HOME/n"; contains "$N_PREFIX/bin" $PATH; or set -a PATH "$N_PREFIX/bin"  # Added by n-install (see http://git.io/n-install-repo).

starship init fish | source

zoxide init fish | source

nerdfetch

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
