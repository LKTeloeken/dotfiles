#!/usr/bin/env bash
# Downloads a GitHub repo into claude/quarantine/ and prints an inventory.
# It never runs anything that comes from the repo.
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/projects/personal/dotfiles}"
QUARANTINE="$DOTFILES_DIR/claude/quarantine"

url="${1:-}"
if [[ ! "$url" =~ ^https://github\.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+(\.git)?/?$ ]]; then
  echo "Usage: fetch.sh https://github.com/<owner>/<repo>" >&2
  exit 1
fi
url="${url%/}"
url="${url%.git}"
slug="${url#https://github.com/}"
slug="${slug//\//__}"

mkdir -p "$QUARANTINE"
tmp="$(mktemp -d "$QUARANTINE/.tmp.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/empty-template"

# No prompts, no LFS filters, no user or system git config, no hooks, no submodules.
GIT_TERMINAL_PROMPT=0 GIT_LFS_SKIP_SMUDGE=1 GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
  git clone --depth 1 --no-recurse-submodules --template="$tmp/empty-template" \
  -c core.hooksPath=/dev/null -c core.fsmonitor=false \
  "$url.git" "$tmp/repo" >&2

sha="$(git -C "$tmp/repo" rev-parse HEAD)"
dest="$QUARANTINE/$slug@${sha:0:12}"
rm -rf "$tmp/repo/.git"

rm -rf "$dest" "$dest.info.json"
mv "$tmp/repo" "$dest"
printf '{ "url": "%s", "sha": "%s" }\n' "$url" "$sha" > "$dest.info.json"

# Claude Code auto-loads these names when it reads files nearby. Rename them so
# untrusted instructions are not pulled into a session by accident.
renamed=()
while IFS= read -r -d '' path; do
  mv "$path" "$path.quarantined"
  renamed+=("${path#"$dest"/}")
done < <(find "$dest" -depth \( -name CLAUDE.md -o -name CLAUDE.local.md -o -name AGENTS.md -o -name .claude \) -print0)

echo "repo:        $url"
echo "commit:      $sha"
echo "quarantine:  $dest"
echo
echo "== renamed to *.quarantined (auto-loaded names) =="
if [[ ${#renamed[@]} -gt 0 ]]; then printf '%s\n' "${renamed[@]}"; else echo "(none)"; fi
echo
echo "== symlinks (do NOT read through these) =="
find "$dest" -type l -exec sh -c 'for l; do printf "%s -> %s\n" "${l#$1/}" "$(readlink "$l")"; done' _ "$dest" {} + | sed 's/^/  /'
echo
echo "== files: size  sha256  flags  path =="
while IFS= read -r -d '' file; do
  size="$(wc -c < "$file" | tr -d ' ')"
  hash="$(shasum -a 256 "$file" | cut -c1-16)"
  flags=""
  [[ -x "$file" ]] && flags+="exec "
  [[ "$(file -b --mime-encoding "$file")" == "binary" ]] && flags+="binary "
  [[ "$size" -gt 262144 ]] && flags+="large "
  printf '%10s  %s  %-14s %s\n' "$size" "$hash" "$flags" "${file#"$dest"/}"
done < <(find "$dest" -type f -print0 | sort -z)
