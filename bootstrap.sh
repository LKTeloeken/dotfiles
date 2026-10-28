#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/projects/personal/dotfiles}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.config-backups}"
BACKUP_DIR="$BACKUP_ROOT/dotfiles-$TIMESTAMP"
BACKUP_CREATED=0

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

# Copies a LaunchAgent plist (launchd does not reliably load symlinks) and
# reloads it only when the installed copy is missing or outdated.
install_launch_agent() {
  local source="$1"
  local label target domain
  label="$(basename "$source" .plist)"
  target="$HOME/Library/LaunchAgents/$label.plist"
  domain="gui/$(id -u)"

  if [[ ! -f "$source" ]]; then
    echo "Skip (source not found): $source"
    return
  fi

  if cmp -s "$source" "$target" && launchctl print "$domain/$label" >/dev/null 2>&1; then
    echo "OK: $label already installed"
    return
  fi

  mkdir -p "$(dirname "$target")"
  # bootout returns before the job is gone; bootstrap fails until it is
  launchctl bootout "$domain/$label" 2>/dev/null || true
  for _ in {1..50}; do
    launchctl print "$domain/$label" >/dev/null 2>&1 || break
    sleep 0.1
  done
  cp "$source" "$target"
  launchctl bootstrap "$domain" "$target"
  echo "Installed: $label"
}

echo "Using dotfiles dir: $DOTFILES_DIR"

# Files
link_item "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
link_item "$DOTFILES_DIR/aerospace.toml" "$HOME/.aerospace.toml"

# Directories in ~/.config
link_item "$DOTFILES_DIR/borders" "$HOME/.config/borders"
link_item "$DOTFILES_DIR/btop" "$HOME/.config/btop"
link_item "$DOTFILES_DIR/fish" "$HOME/.config/fish"
link_item "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"
link_item "$DOTFILES_DIR/kitty" "$HOME/.config/kitty"
link_item "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
link_item "$DOTFILES_DIR/opencode" "$HOME/.config/opencode"
link_item "$DOTFILES_DIR/raycast" "$HOME/.config/raycast"
link_item "$DOTFILES_DIR/sketchybar" "$HOME/.config/sketchybar"
link_item "$DOTFILES_DIR/tmux" "$HOME/.config/tmux"
link_item "$DOTFILES_DIR/uv" "$HOME/.config/uv"
link_item "$DOTFILES_DIR/yarn" "$HOME/.config/yarn"
link_item "$DOTFILES_DIR/zed" "$HOME/.config/zed"

# LaunchAgents
SKETCHYBAR_BIN="$HOME/projects/personal/sketchybar/bin/sketchybar"
if [[ ! -x "$SKETCHYBAR_BIN" ]]; then
  echo "Warning: $SKETCHYBAR_BIN not found; clone LKTeloeken/SketchyBar"
  echo "  (branch lucas/popup-rows-pressed) into ~/projects/personal and run make."
fi
install_launch_agent "$DOTFILES_DIR/sketchybar/launchd/com.lkteloeken.sketchybar.plist"

# Apps
if ! command -v brew >/dev/null 2>&1; then
  echo "Skip (brew not found): scroll-fix"
elif brew list --cask scroll-fix >/dev/null 2>&1; then
  echo "OK: scroll-fix already installed"
else
  brew tap LKTeloeken/scroll-fix https://github.com/LKTeloeken/scroll-fix
  brew trust lkteloeken/scroll-fix
  brew install --cask scroll-fix
  echo "Installed: scroll-fix (allow it in Privacy & Security -> Accessibility)"
fi

if [[ "$BACKUP_CREATED" -eq 0 ]]; then
  echo "No backup needed."
fi

echo "Done."
