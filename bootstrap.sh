#!/usr/bin/env bash
# Sets up a Mac from these dotfiles. Every module is safe to run again.
#
#   ./bootstrap.sh                    all modules
#   ./bootstrap.sh sketchybar borders only these modules
#   ./bootstrap.sh --list             list modules
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/projects/personal/dotfiles}"
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects/personal}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.config-backups}"
BACKUP_DIR="$BACKUP_ROOT/dotfiles-$TIMESTAMP"
BACKUP_CREATED=0

MODULES=(
  homebrew   "Homebrew itself and the Xcode Command Line Tools"
  packages   "CLI tools and apps from the Brewfile"
  fish       "fish shell, starship, zoxide, fzf, eza, bat"
  kitty      "kitty terminal and its font"
  ghostty    "Ghostty terminal"
  tmux       "tmux, its config and plugins (tpm)"
  nvim       "Neovim config and plugins"
  aerospace  "AeroSpace window manager"
  rift       "Rift window manager as Rift.app, signed with the local certificate"
  borders    "JankyBorders, as a brew service"
  sketchybar "SketchyBar fork, SbarLua and its config, as a brew service"
  colors     "pywal colors from the current wallpaper"
  scroll-fix "ScrollFix (natural scrolling per device)"
  notifyq    "notifyq notifications CLI and daemon"
  vscode     "VS Code settings, Islands theme fork and Custom UI Style"
  claude     "Claude Code profiles: default and isa (personal, shared sessions) and work"
  configs    "btop, uv, yarn, zed, opencode and Raycast configs"
)

# ---------------------------------------------------------------- helpers

ensure_backup_dir() {
  if [[ "$BACKUP_CREATED" -eq 0 ]]; then
    mkdir -p "$BACKUP_DIR"
    BACKUP_CREATED=1
    echo "Backup dir: $BACKUP_DIR"
  fi
}

backup_path() {
  local target="$1"
  local safe_name
  safe_name="$(echo "$target" | sed "s#^$HOME/##" | tr '/' '_')"

  ensure_backup_dir
  mv "$target" "$BACKUP_DIR/$safe_name"
  echo "Backup: $target -> $BACKUP_DIR/$safe_name"
}

link_item() {
  local source="$1"
  local target="$2"
  local parent

  if [[ ! -e "$source" && ! -L "$source" ]]; then
    echo "Skip (source not found): $source"
    return
  fi

  parent="$(dirname "$target")"
  mkdir -p "$parent"

  if [[ -L "$target" ]]; then
    local current
    current="$(readlink "$target")"
    if [[ "$current" == "$source" ]]; then
      echo "OK: $target already linked"
      return
    fi
    backup_path "$target"
  elif [[ -e "$target" ]]; then
    backup_path "$target"
  fi

  ln -sfn "$source" "$target"
  echo "Linked: $target -> $source"
}

# Loads brew into PATH, installing Homebrew first when it is missing.
ensure_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    else
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi
  export HOMEBREW_NO_ENV_HINTS=1
}

# brew_tap <name> [url]: taps and trusts a third-party tap once.
brew_tap() {
  ensure_brew
  if ! brew tap | grep -qx "$1"; then
    brew tap "$@"
  fi
  brew trust "$1" >/dev/null 2>&1 || true
}

brew_install() {
  ensure_brew
  local formula
  for formula in "$@"; do
    if brew list --formula "$formula" >/dev/null 2>&1; then
      echo "OK: $formula already installed"
    else
      brew install "$formula"
    fi
  done
}

# cask_install <cask> [app path]: skips apps that are already there, even when
# they were installed without Homebrew.
cask_install() {
  ensure_brew
  local cask="$1" app="${2:-}"
  if brew list --cask "$cask" >/dev/null 2>&1; then
    echo "OK: $cask already installed"
  elif [[ -n "$app" && -e "$app" ]]; then
    echo "OK: $app already present (not managed by brew)"
  else
    brew install --cask "$cask"
  fi
}

brew_service_start() {
  local formula="$1" name
  name="${formula##*/}"
  if brew services list | awk -v n="$name" '$1 == n && $2 == "started" { found = 1 } END { exit !found }'; then
    echo "OK: $name service already started"
  else
    brew services start "$formula"
  fi
}

# Unloads and deletes a LaunchAgent that a module no longer uses.
remove_launch_agent() {
  local label="$1"
  local target="$HOME/Library/LaunchAgents/$label.plist"
  local domain="gui/$(id -u)"

  if launchctl print "$domain/$label" >/dev/null 2>&1; then
    launchctl bootout "$domain/$label" 2>/dev/null || true
    # bootout returns before the job is gone
    for _ in {1..50}; do
      launchctl print "$domain/$label" >/dev/null 2>&1 || break
      sleep 0.1
    done
  fi
  if [[ -f "$target" ]]; then
    rm "$target"
    echo "Removed legacy LaunchAgent: $label"
  fi
}

# clone_repo <github owner/name> <dir>
clone_repo() {
  if [[ -d "$2/.git" ]]; then
    echo "OK: $2 already cloned"
  else
    git clone "https://github.com/$1.git" "$2"
  fi
}

# ---------------------------------------------------------------- modules

module_homebrew() {
  if ! xcode-select -p >/dev/null 2>&1; then
    echo "Installing the Xcode Command Line Tools (finish the dialog, then run again)..."
    xcode-select --install || true
    exit 1
  fi
  ensure_brew
  echo "OK: $(brew --version | head -1)"
}

module_packages() {
  ensure_brew
  brew bundle --file "$DOTFILES_DIR/Brewfile"
}

module_fish() {
  brew_install fish starship zoxide fzf bat eza fastfetch
  link_item "$DOTFILES_DIR/fish" "$HOME/.config/fish"
  link_item "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

  local fish_bin
  fish_bin="$(brew --prefix)/bin/fish"
  if [[ "$SHELL" != "$fish_bin" ]]; then
    echo "To make fish the login shell (asks for your password):"
    echo "  echo $fish_bin | sudo tee -a /etc/shells && chsh -s $fish_bin"
  fi
}

module_kitty() {
  cask_install kitty /Applications/kitty.app
  cask_install font-caskaydia-cove-nerd-font
  link_item "$DOTFILES_DIR/kitty" "$HOME/.config/kitty"

  # kitty.conf includes this file; the colors module fills it from the wallpaper.
  local colors="$DOTFILES_DIR/kitty/pywal-colors.conf"
  if [[ ! -f "$colors" ]]; then
    echo "# Generated by scripts/sync_colors.sh" > "$colors"
    echo "Created placeholder: $colors"
  fi
}

module_ghostty() {
  cask_install ghostty /Applications/Ghostty.app
  link_item "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"
}

module_tmux() {
  brew_install tmux
  link_item "$DOTFILES_DIR/tmux" "$HOME/.config/tmux"
  clone_repo tmux-plugins/tpm "$DOTFILES_DIR/tmux/plugins/tpm"
  "$DOTFILES_DIR/tmux/plugins/tpm/bin/install_plugins" >/dev/null
  echo "OK: tmux plugins installed"
}

module_nvim() {
  # Node (for Copilot and some LSPs) comes from `n`, in the packages module
  brew_install neovim ripgrep fd
  link_item "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
  # Installs the plugin versions pinned in lazy-lock.json
  nvim --headless "+Lazy! restore" +qa
  echo "OK: Neovim plugins restored"
}

module_aerospace() {
  brew_tap nikitabobko/tap
  cask_install nikitabobko/tap/aerospace /Applications/AeroSpace.app
  link_item "$DOTFILES_DIR/aerospace.toml" "$HOME/.aerospace.toml"
}

# Signs Rift.app with a local certificate so its Accessibility permission
# survives upgrades (see lkteloeken/tap/rift). Run again after `brew upgrade`.
module_rift() {
  brew_tap lkteloeken/tap
  brew_install lkteloeken/tap/rift
  local identity="${RIFT_SIGN_IDENTITY:-Local Code Signing}"
  local app
  app="$(brew --prefix lkteloeken/tap/rift)/Rift.app"
  # opt/ always points at the current version, so the link survives upgrades
  link_item "$app" "/Applications/Rift.app"
  link_item "$DOTFILES_DIR/rift/config.toml" "$HOME/.config/rift/config.toml"

  if ! security find-certificate -c "$identity" >/dev/null 2>&1; then
    echo "Skip signing: no \"$identity\" certificate. Create it in Keychain Access >"
    echo "Certificate Assistant > Create a Certificate (type: Code Signing), then run this again."
    return
  fi
  # Captured first: under pipefail, grep -q closing the pipe early fails codesign
  local signature
  signature="$(codesign -dvv "$app" 2>&1 || true)"
  if grep -qx "Authority=$identity" <<<"$signature"; then
    echo "OK: Rift.app already signed with $identity"
  else
    codesign --force --sign "$identity" "$app"
    echo "Signed: Rift.app with $identity"
  fi
}

module_borders() {
  brew_tap felixkratz/formulae
  brew_install felixkratz/formulae/borders
  link_item "$DOTFILES_DIR/borders" "$HOME/.config/borders"
  brew_service_start felixkratz/formulae/borders
}

module_sketchybar() {
  brew_tap lkteloeken/tap
  brew_install lua jq media-control
  cask_install font-sketchybar-app-font
  cask_install font-sf-pro
  cask_install font-hack-nerd-font

  # The fork replaces the upstream formula: both install a `sketchybar` binary.
  if brew list --formula felixkratz/formulae/sketchybar >/dev/null 2>&1; then
    brew services stop felixkratz/formulae/sketchybar >/dev/null 2>&1 || true
    brew uninstall felixkratz/formulae/sketchybar
  fi
  brew_install lkteloeken/tap/sketchybar

  # SbarLua, the Lua module the config runs on. Built against the bundled Lua,
  # so rebuild it (delete the .so and rerun) when brew moves to a new Lua.
  local sbarlua="$HOME/.local/share/sketchybar_lua/sketchybar.so"
  if [[ -f "$sbarlua" ]]; then
    echo "OK: SbarLua already installed"
  else
    local tmp
    tmp="$(mktemp -d)"
    git clone --depth 1 https://github.com/FelixKratz/SbarLua.git "$tmp/SbarLua"
    make -C "$tmp/SbarLua" install
    rm -rf "$tmp"
  fi

  link_item "$DOTFILES_DIR/sketchybar" "$HOME/.config/sketchybar"
  # Earlier setups ran the fork from a LaunchAgent; brew services owns it now.
  remove_launch_agent com.lkteloeken.sketchybar
  brew_service_start lkteloeken/tap/sketchybar
}

module_colors() {
  brew_install pipx imagemagick wallpaper
  if [[ -x "$HOME/.local/bin/wal" ]] || command -v wal >/dev/null 2>&1; then
    echo "OK: pywal already installed"
  else
    pipx install pywal
  fi
  "$DOTFILES_DIR/scripts/sync_colors.sh"
}

module_scroll_fix() {
  brew_tap lkteloeken/scroll-fix https://github.com/LKTeloeken/scroll-fix
  if brew list --cask scroll-fix >/dev/null 2>&1; then
    echo "OK: scroll-fix already installed"
  else
    brew install --cask lkteloeken/scroll-fix/scroll-fix
    open -a ScrollFix
    echo "Allow ScrollFix in Privacy & Security -> Accessibility"
  fi
}

module_notifyq() {
  brew_install lua
  clone_repo LKTeloeken/notifyq "$PROJECTS_DIR/notifyq"
  "$PROJECTS_DIR/notifyq/install.sh"
  if launchctl print "gui/$(id -u)/com.lkteloeken.notifyq" >/dev/null 2>&1; then
    echo "OK: notifyq daemon already loaded"
  else
    "$HOME/.local/bin/notifyq" daemon install
  fi
}

module_vscode() {
  cask_install visual-studio-code "/Applications/Visual Studio Code.app"
  brew_install jq
  local code_bin="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  local user_dir="$HOME/Library/Application Support/Code/User"

  link_item "$DOTFILES_DIR/vscode/settings.json" "$user_dir/settings.json"
  link_item "$DOTFILES_DIR/vscode/keybindings.json" "$user_dir/keybindings.json"

  # The theme is a symlinked folder; VS Code registers it on its next start.
  clone_repo LKTeloeken/vscode-dark-islands "$PROJECTS_DIR/vscode-dark-islands"
  local version
  version="$(jq -r .version "$PROJECTS_DIR/vscode-dark-islands/package.json")"
  link_item "$PROJECTS_DIR/vscode-dark-islands" "$HOME/.vscode/extensions/lkteloeken.islands-dark-$version"

  # Injects islands.css (see custom-ui-style.external.imports in settings.json)
  if "$code_bin" --list-extensions | grep -qx subframe7536.custom-ui-style; then
    echo "OK: Custom UI Style already installed"
  else
    "$code_bin" --install-extension subframe7536.custom-ui-style
  fi
  echo "In VS Code, run \"Custom UI Style: Reload\" once to apply the panels"
}

# Links the versioned Claude Code files into one config dir. Skills, agents and
# commands are linked one by one so app-managed entries (skills/synced) stay local.
link_claude_profile() {
  local profile="$1"
  local config_dir="$2"
  local source_dir="$DOTFILES_DIR/claude/$profile"
  local item entry

  mkdir -p "$config_dir"
  for item in CLAUDE.md settings.json; do
    link_item "$source_dir/$item" "$config_dir/$item"
  done
  for item in skills agents commands; do
    [[ -d "$source_dir/$item" ]] || continue
    mkdir -p "$config_dir/$item"
    for entry in "$source_dir/$item"/*; do
      [[ -e "$entry" ]] || continue
      link_item "$entry" "$config_dir/$item/$(basename "$entry")"
    done
  done
}

module_claude() {
  # Accounts are separate logins, one per config dir (see the claude-* aliases
  # in fish/config.fish). Run /login once in each.
  link_claude_profile personal "$HOME/.claude"
  link_claude_profile personal "$HOME/.claude-isa"
  link_claude_profile work "$HOME/.claude-work"

  # The two personal accounts share sessions, memory and history through ~/.claude
  local item
  for item in projects file-history plans history.jsonl; do
    [[ -e "$HOME/.claude/$item" ]] || mkdir -p "$HOME/.claude/$item"
    link_item "$HOME/.claude/$item" "$HOME/.claude-isa/$item"
  done
}

module_configs() {
  brew_install btop
  cask_install raycast /Applications/Raycast.app
  link_item "$DOTFILES_DIR/btop" "$HOME/.config/btop"
  link_item "$DOTFILES_DIR/uv" "$HOME/.config/uv"
  link_item "$DOTFILES_DIR/yarn" "$HOME/.config/yarn"
  link_item "$DOTFILES_DIR/zed" "$HOME/.config/zed"
  link_item "$DOTFILES_DIR/opencode" "$HOME/.config/opencode"
  link_item "$DOTFILES_DIR/raycast" "$HOME/.config/raycast"
}

# ---------------------------------------------------------------- main

list_modules() {
  local i
  for ((i = 0; i < ${#MODULES[@]}; i += 2)); do
    printf "  %-11s %s\n" "${MODULES[i]}" "${MODULES[i + 1]}"
  done
}

is_module() {
  local i
  for ((i = 0; i < ${#MODULES[@]}; i += 2)); do
    [[ "${MODULES[i]}" == "$1" ]] && return 0
  done
  return 1
}

case "${1:-}" in
  -h | --help | --list)
    echo "Usage: $0 [module...]   (no module = all)"
    echo
    list_modules
    exit 0
    ;;
esac

selected=()
if [[ $# -eq 0 ]]; then
  for ((i = 0; i < ${#MODULES[@]}; i += 2)); do
    selected+=("${MODULES[i]}")
  done
else
  for module in "$@"; do
    if ! is_module "$module"; then
      echo "Unknown module: $module" >&2
      echo "Modules:" >&2
      list_modules >&2
      exit 1
    fi
    selected+=("$module")
  done
fi

echo "Using dotfiles dir: $DOTFILES_DIR"
for module in "${selected[@]}"; do
  echo
  echo "==> $module"
  "module_${module//-/_}"
done

echo
if [[ "$BACKUP_CREATED" -eq 0 ]]; then
  echo "No backup needed."
fi
echo "Done."
