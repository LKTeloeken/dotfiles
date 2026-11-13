#!/usr/bin/env bash
# Moves a reviewed skill from the quarantine into claude/<profile>/skills/.
# Usage: install.sh <quarantine-folder-name> <subpath-with-SKILL.md> <skill-name>
#                   [personal|work] [--exclude <entry>]...
# --exclude drops a top-level file or folder of the skill (for example agents).
# Only run this after the user approved the review report.
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/projects/personal/dotfiles}"
QUARANTINE="$DOTFILES_DIR/claude/quarantine"
LOCK="$DOTFILES_DIR/claude/skills-lock.json"

qdir="${1:-}"; sub="${2:-}"; name="${3:-}"; profile="personal"
if [[ -z "$qdir" || -z "$sub" || -z "$name" ]]; then
  echo "Usage: install.sh <quarantine-folder> <subpath> <skill-name> [personal|work] [--exclude <entry>]..." >&2
  exit 1
fi
shift 3
if [[ $# -gt 0 && "$1" != --* ]]; then profile="$1"; shift; fi
excludes=()
while [[ $# -gt 0 ]]; do
  [[ "$1" == --exclude && -n "${2:-}" ]] || { echo "Unexpected argument: $1" >&2; exit 1; }
  [[ "$2" != */* && "$2" != *..* && "$2" != SKILL.md ]] || { echo "Invalid --exclude: $2" >&2; exit 1; }
  excludes+=("$2"); shift 2
done
[[ "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "Invalid skill name: $name" >&2; exit 1; }
[[ "$profile" == personal || "$profile" == work ]] || { echo "Profile must be personal or work" >&2; exit 1; }
[[ "$qdir" != */* && "$qdir" != *..* ]] || { echo "Invalid quarantine folder" >&2; exit 1; }
[[ "$sub" != /* && "$sub" != *..* ]] || { echo "Invalid subpath" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required (brew install jq)" >&2; exit 1; }

src="$(cd "$QUARANTINE/$qdir/$sub" && pwd -P)"
case "$src" in "$QUARANTINE"/*) ;; *) echo "Source is outside the quarantine" >&2; exit 1 ;; esac
[[ -f "$src/SKILL.md" ]] || { echo "No SKILL.md in $src" >&2; exit 1; }
if [[ -n "$(find "$src" -type l -print -quit)" ]]; then
  echo "Refusing: the skill contains symlinks" >&2; exit 1
fi

dest="$DOTFILES_DIR/claude/$profile/skills/$name"
[[ ! -e "$dest" ]] || { echo "Already exists: $dest (remove it first to update)" >&2; exit 1; }

mkdir -p "$(dirname "$dest")"
cp -R "$src" "$dest"
if [[ ${#excludes[@]} -gt 0 ]]; then
  for entry in "${excludes[@]}"; do rm -rf "${dest:?}/$entry"; done
fi

# Restore the names fetch.sh changed, then drop every exec bit.
while IFS= read -r -d '' path; do mv "$path" "${path%.quarantined}"; done \
  < <(find "$dest" -depth -name '*.quarantined' -print0)
find "$dest" -type d -exec chmod 755 {} +
find "$dest" -type f -exec chmod 644 {} +

info="$QUARANTINE/$qdir.info.json"
treehash="$(cd "$dest" && find . -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | cut -d' ' -f1)"
[[ -f "$LOCK" ]] || echo '{ "skills": {} }' > "$LOCK"
jq --arg key "$profile/$name" --arg sub "$sub" --arg tree "$treehash" \
   --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --slurpfile info "$info" \
   '.skills[$key] = {url: $info[0].url, sha: $info[0].sha, subpath: $sub, treeSha256: $tree, installedAt: $date}' \
   "$LOCK" > "$LOCK.tmp" && mv "$LOCK.tmp" "$LOCK"

"$DOTFILES_DIR/bootstrap.sh" claude
echo "Installed $profile/$name (tree sha256 $treehash)"
