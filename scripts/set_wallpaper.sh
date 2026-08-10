#!/usr/bin/env bash

usage() {
    echo "Usage: $0 [-y|--yes] <path_to_image>"
    echo "  -y, --yes   skip the preview and the confirmation prompt"
}

ASSUME_YES=0
IMAGE_ARG=""

while [ $# -gt 0 ]; do
    case "$1" in
        -y | --yes) ASSUME_YES=1 ;;
        -h | --help) usage; exit 0 ;;
        -*) echo "Unknown option: $1"; usage; exit 1 ;;
        *) IMAGE_ARG="$1" ;;
    esac
    shift
done

if [ -z "$IMAGE_ARG" ]; then
    usage
    exit 1
fi

if [ ! -f "$IMAGE_ARG" ]; then
    echo "File not found: $IMAGE_ARG"
    exit 1
fi

IMAGE_PATH=$(realpath "$IMAGE_ARG")

apply() {
    # System Events covers every display; Finder's "set desktop picture" only
    # touches the main one.
    if ! osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$IMAGE_PATH\""; then
        # Bail out instead of recolouring everything for a wallpaper that was
        # never applied. Most likely cause is a missing Automation permission
        # for the app running this script.
        echo "Failed to set the wallpaper. Colors were left untouched." >&2
        return 1
    fi
    echo "Wallpaper set! Syncing SketchyBar colors..."
    # sync_colors.sh accepts the path as $1; passing it avoids the round trip
    # where it asks Finder which wallpaper is current.
    "$(dirname "$0")/sync_colors.sh" "$IMAGE_PATH"
}

if [ "$ASSUME_YES" -eq 1 ]; then
    apply
    exit $?
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
    apply
else
    echo "Cancelled."
fi
