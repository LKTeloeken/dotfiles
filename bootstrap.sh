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
  borders    "JankyBorders, as a brew service"
  sketchybar "SketchyBar fork, SbarLua and its config, as a brew service"
  colors     "pywal colors from the current wallpaper"
  scroll-fix "ScrollFix (natural scrolling per device)"
  notifyq    "notifyq notifications CLI and daemon"
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
