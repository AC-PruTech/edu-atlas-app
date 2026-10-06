#!/usr/bin/env bash
# Sync Salesforce agent skills from https://github.com/forcedotcom/sf-skills
# into .agents/skills/ (read by Codex, Cursor, GitHub Copilot, Gemini CLI, OpenCode)
# and .claude/skills/ (a symlink to the same folder, read by Claude Code).
#
# The skill list lives in .agents/sf-skills.txt (one skill name per line, # for comments).
# Use the single line "*" to install every skill in the library.
#
# Usage: bash scripts/sync-sf-skills.sh [git-ref]   (default ref: main)
set -euo pipefail

REF="${1:-main}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LIST="$ROOT/.agents/sf-skills.txt"
DEST="$ROOT/.agents/skills"
MANIFEST="$DEST/.sf-skills-manifest"
UPSTREAM="https://github.com/forcedotcom/sf-skills.git"

[ -f "$LIST" ] || { echo "Missing $LIST"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --quiet --depth 1 --branch "$REF" "$UPSTREAM" "$TMP/sf-skills"
SHA="$(git -C "$TMP/sf-skills" rev-parse HEAD)"

# Index every skill folder in the library: skills/<name> and plugins/*/*/skills/<name>.
# The top-level skills/ copy wins when a name exists in both places.
declare -A SRC
while IFS= read -r d; do
  n="$(basename "$d")"; [ -z "${SRC[$n]:-}" ] && SRC[$n]="$d"
done < <(find "$TMP/sf-skills/skills" "$TMP/sf-skills/plugins" -mindepth 1 -maxdepth 4 -type d \
          -path '*skills/*' -exec test -f '{}/SKILL.md' ';' -print | sort)

mapfile -t WANT < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$LIST" | grep -v '^$' || true)
if [ "${WANT[0]:-}" = "*" ]; then mapfile -t WANT < <(printf '%s\n' "${!SRC[@]}" | sort); fi

mkdir -p "$DEST"
# Remove only skills this script installed before, so custom skills stay untouched.
if [ -f "$MANIFEST" ]; then
  while IFS= read -r old; do [ -n "$old" ] && rm -rf "${DEST:?}/$old"; done < "$MANIFEST"
fi

: > "$MANIFEST.new"; MISSING=()
for n in "${WANT[@]}"; do
  if [ -n "${SRC[$n]:-}" ]; then
    cp -R "${SRC[$n]}" "$DEST/$n"; echo "$n" >> "$MANIFEST.new"
  else
    MISSING+=("$n")
  fi
done
sort -o "$MANIFEST" "$MANIFEST.new"; rm -f "$MANIFEST.new"

cat > "$DEST/SF_SKILLS_SOURCE.md" << MD
# Salesforce skills source

These skill folders are copied from [forcedotcom/sf-skills](https://github.com/forcedotcom/sf-skills)
(Apache 2.0, maintained by Salesforce). Do not edit them here; changes are overwritten on the next sync.

- Upstream commit: \`$SHA\`
- Skills installed: $(wc -l < "$MANIFEST")
- Skill list: \`.agents/sf-skills.txt\`
- Update: \`bash scripts/sync-sf-skills.sh\` (also runs weekly in GitHub Actions)
MD

# Claude Code reads .claude/skills; point it at the same folder.
mkdir -p "$ROOT/.claude"
if [ ! -e "$ROOT/.claude/skills" ]; then ln -s ../.agents/skills "$ROOT/.claude/skills"; fi

echo "Synced $(wc -l < "$MANIFEST") skills from sf-skills@${SHA:0:7}"
if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Not found upstream (renamed or removed): ${MISSING[*]}"
  echo "missing=${MISSING[*]}" >> "${GITHUB_OUTPUT:-/dev/null}"
fi
echo "sha=$SHA" >> "${GITHUB_OUTPUT:-/dev/null}"
