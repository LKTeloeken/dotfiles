#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_image>"
    exit 1
fi

IMAGE_PATH=$(realpath "$1")

if [ ! -f "$IMAGE_PATH" ]; then
    echo "File not found: $IMAGE_PATH"
    exit 1
fi

# Try to preview if kitty is available
if command -v kitty >/dev/null 2>&1; then
    echo "Preview:"
    kitty +kitten icat --align left --place 40x40@0x0 "$IMAGE_PATH"
    echo ""
fi

read -p "Set this as wallpaper? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$IMAGE_PATH\""
    echo "Wallpaper set! Syncing SketchyBar colors..."
    "$(dirname "$0")/sync_colors.sh"
else
    echo "Cancelled."
fi