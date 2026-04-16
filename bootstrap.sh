#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Documents/projects/personal/dotfiles}"
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

if [[ "$BACKUP_CREATED" -eq 0 ]]; then
  echo "No backup needed."
fi

echo "Done."
