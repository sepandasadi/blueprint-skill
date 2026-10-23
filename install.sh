#!/usr/bin/env bash
# install.sh — bash fallback for machines without Node. Same behaviour as
# `npx blueprint-skill`: pick agents, print the plan, confirm, copy (never symlink),
# back up what it replaces, record every written path in a manifest.
# Every run checks npm for a newer version (2 s timeout, silent when offline);
# BLUEPRINT_SKILL_NO_UPDATE_CHECK=1 turns that off.
set -euo pipefail

SKILL_NAME="blueprint"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$SKILL_NAME"
STATE_DIR="$HOME/.blueprint-skill"
MANIFEST="$STATE_DIR/manifest"
SHARED_DIR="$HOME/.agents/skills"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(sed -n 's/^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$ROOT/package.json" 2>/dev/null | head -1)"
VERSION="${VERSION:-unknown}"
VERSION_FILE=".blueprint-version"
REGISTRY="${BLUEPRINT_SKILL_REGISTRY:-https://registry.npmjs.org}"
UPDATE_CMD="npx blueprint-skill@latest update   (no Node: git pull && ./install.sh update)"

# id|label|detect path|target dir|shared(1 = reads ~/.agents/skills)
AGENTS=(
  "claude|Claude Code|$HOME/.claude|$HOME/.claude/skills|0"
  "codex|OpenAI Codex|$HOME/.codex|$HOME/.codex/skills|1"
  "cursor|Cursor|$HOME/.cursor|$HOME/.cursor/skills|1"
  "antigravity|Google Antigravity|$HOME/.gemini/antigravity|$HOME/.gemini/antigravity/skills|0"
  "antigravity-cli|Antigravity CLI|$HOME/.gemini/antigravity-cli|$HOME/.gemini/antigravity-cli/skills|0"
  "copilot|VS Code / GitHub Copilot|$HOME/.copilot|$HOME/.copilot/skills|1"
)

CLIENTS=(); ALL=0; YES=0; DRY=0; NATIVE=0; PROJECT=""; CMD="install"
while [[ $# -gt 0 ]]; do
  case "$1" in
    install|uninstall|doctor|update) CMD="$1" ;;
    -c|--client) CLIENTS+=("$2"); shift ;;
    --client=*) CLIENTS+=("${1#*=}") ;;
    -a|--all) ALL=1 ;;
    -y|--yes) YES=1 ;;
    -n|--dry-run) DRY=1 ;;
    --native) NATIVE=1 ;;
    -p|--project) PROJECT="$(cd "${2:-.}" && pwd)"; shift ;;
    --project=*) PROJECT="$(cd "${1#*=}" && pwd)" ;;
    -v|--version) echo "$VERSION"; exit 0 ;;
    -h|--help)
      cat <<USAGE
install.sh $VERSION — install the "blueprint" skill (bash fallback for npx blueprint-skill)

  ./install.sh [install] [-c <id>]... [-a] [-p <dir>] [--native] [-n] [-y]
  ./install.sh update [-n] [-y]     reinstall this version into every folder in the manifest
  ./install.sh uninstall [-n] [-y]
  ./install.sh doctor               installed copies and their versions
  ./install.sh --version

Every run checks npm for a newer version; BLUEPRINT_SKILL_NO_UPDATE_CHECK=1 turns it off.

ids: claude, codex, cursor, antigravity, antigravity-cli, copilot
USAGE
      exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

field() { echo "$1" | cut -d'|' -f"$2"; }
detected() { [[ -e "$(field "$1" 3)" ]]; }
agent_by_id() { for a in "${AGENTS[@]}"; do [[ "$(field "$a" 1)" == "$1" ]] && { echo "$a"; return; }; done; echo "Unknown client: $1" >&2; exit 2; }

# ---------- versions ----------
installed_version() { [[ -f "$1/$VERSION_FILE" ]] && tr -d '[:space:]' < "$1/$VERSION_FILE" || true; }
# cmp_version A B -> prints -1, 0 or 1 (dotted numbers; prerelease tags ignored)
cmp_version() {
  local a="${1%%-*}" b="${2%%-*}" i x y
  IFS=. read -r -a pa <<< "$a"; IFS=. read -r -a pb <<< "$b"
  for i in 0 1 2 3; do
    x="${pa[$i]:-0}"; y="${pb[$i]:-0}"; [[ "$x" =~ ^[0-9]+$ ]] || x=0; [[ "$y" =~ ^[0-9]+$ ]] || y=0
    if (( 10#$x < 10#$y )); then echo -1; return; fi
    if (( 10#$x > 10#$y )); then echo 1; return; fi
  done
  echo 0
}
fetch_latest() {
  [[ -n "${BLUEPRINT_SKILL_NO_UPDATE_CHECK:-}" ]] && return 0
  command -v curl >/dev/null 2>&1 || return 0
  curl -fsS --max-time 2 -H 'accept: application/json' "${REGISTRY%/}/blueprint-skill/latest" 2>/dev/null \
    | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || true
}
newer_notice() {
  local latest="$1"
  [[ -n "$latest" && "$VERSION" != unknown ]] || return 0
  [[ "$(cmp_version "$VERSION" "$latest")" == "-1" ]] || return 0
  echo; echo "update blueprint-skill $latest is available (this installer is $VERSION). Run: $UPDATE_CMD"
}

choose_agents() {
  echo; echo "Which coding agents should get the blueprint skill?"; echo
  local i=1 det=()
  for a in "${AGENTS[@]}"; do
    if detected "$a"; then mark="detected"; det+=("$(field "$a" 1)"); else mark="not found"; fi
    printf "  %s. %-26s %s\n" "$i" "$(field "$a" 2)" "$mark"; i=$((i+1))
  done
  echo; echo "  a. All detected (${det[*]:-none})  <- recommended"; echo "  e. Everything, detected or not"; echo "  q. Quit"; echo
  read -r -p "Pick numbers separated by commas, or a / e / q: " ans
  case "$ans" in
    q|"") echo "Nothing selected."; exit 0 ;;
    a) for a in "${AGENTS[@]}"; do if detected "$a"; then CHOSEN+=("$a"); fi; done ;;
    e) CHOSEN=("${AGENTS[@]}") ;;
    *) for n in ${ans//,/ }; do if [[ "$n" =~ ^[0-9]+$ ]] && [[ $n -ge 1 && $n -le ${#AGENTS[@]} ]]; then CHOSEN+=("${AGENTS[$((n-1))]}"); fi; done ;;
  esac
}

targets_for() {
  local t=()
  for a in "$@"; do
    if [[ "$(field "$a" 5)" == "1" && $NATIVE -eq 0 ]]; then t+=("$SHARED_DIR/$SKILL_NAME")
    else t+=("$(field "$a" 4)/$SKILL_NAME"); if [[ "$(field "$a" 5)" == "1" ]]; then t+=("$SHARED_DIR/$SKILL_NAME"); fi; fi
  done
  printf "%s\n" "${t[@]}" | awk '!seen[$0]++'
}

do_install() {
  [[ -f "$SRC/SKILL.md" ]] || { echo "Skill source not found at $SRC" >&2; exit 1; }
  CHOSEN=()
  if [[ -n "$PROJECT" ]]; then
    TARGETS=("$PROJECT/.agents/skills/$SKILL_NAME" "$PROJECT/.claude/skills/$SKILL_NAME" "$PROJECT/.github/skills/$SKILL_NAME")
  else
    if [[ $ALL -eq 1 ]]; then for a in "${AGENTS[@]}"; do if detected "$a"; then CHOSEN+=("$a"); fi; done
    elif [[ ${#CLIENTS[@]} -gt 0 ]]; then for id in "${CLIENTS[@]}"; do CHOSEN+=("$(agent_by_id "$id")"); done
    elif [[ -t 0 ]]; then choose_agents
    else echo "No TTY and no --client/--all/--project given." >&2; exit 2; fi
    [[ ${#CHOSEN[@]} -gt 0 ]] || { echo "Nothing selected."; exit 0; }
    TARGETS=(); while IFS= read -r line; do TARGETS+=("$line"); done < <(targets_for "${CHOSEN[@]}")
  fi

  echo; echo "Plan (source: $SRC)"
  for t in "${TARGETS[@]}"; do
    if [[ -L "$t" ]]; then note="SYMLINK - will be skipped"; elif [[ -e "$t" ]]; then note="exists - will be backed up and replaced"; else note="new"; fi
    echo "  $t  $note"
  done
  echo "  manifest: $MANIFEST"; echo
  [[ $DRY -eq 1 ]] && { echo "dry run - nothing written"; exit 0; }
  if [[ $YES -eq 0 ]]; then read -r -p "Proceed? [y/N] " ok; [[ "$ok" =~ ^[Yy]([Ee][Ss])?$ ]] || { echo "Aborted."; exit 0; }; fi

  stamp="$(date +%Y%m%dT%H%M%S)"; mkdir -p "$STATE_DIR"; touch "$MANIFEST"
  for t in "${TARGETS[@]}"; do
    if [[ -L "$t" ]]; then echo "skip   $t is a symlink; remove it first if you want blueprint there."; continue; fi
    if [[ -e "$t" ]]; then b="$STATE_DIR/backups/$stamp/$(echo "$t" | tr '/:' '__')"; mkdir -p "$(dirname "$b")"; mv "$t" "$b"; echo "backup $t -> $b"; fi
    mkdir -p "$(dirname "$t")"; cp -R "$SRC" "$t"; echo "$VERSION" > "$t/$VERSION_FILE"
    if head -5 "$t/SKILL.md" | grep -qE '^name:[[:space:]]*blueprint[[:space:]]*$'; then echo "ok     $t"; grep -qxF "$t" "$MANIFEST" || echo "$t" >> "$MANIFEST"
    else echo "FAIL   $t: name does not match folder"; fi
  done
  echo; echo "Installed blueprint $VERSION. Restart your agent, then type /blueprint (Codex: \$blueprint)."
}

do_update() {
  local latest="$1"
  [[ -f "$SRC/SKILL.md" ]] || { echo "Skill source not found at $SRC" >&2; exit 1; }
  [[ -s "$MANIFEST" ]] || { echo "Nothing was installed by blueprint-skill yet. Run ./install.sh to install."; exit 0; }
  if [[ -n "$latest" && "$(cmp_version "$VERSION" "$latest")" == "-1" ]]; then
    echo "note  this installer is $VERSION but $latest is published. To get $latest, run: $UPDATE_CMD"
  fi
  local targets=() p v
  echo; echo "Update to blueprint $VERSION"
  while IFS= read -r p; do
    [[ -n "$p" ]] || continue
    if [[ ! -e "$p" || -L "$p" ]]; then echo "  $p  missing or a symlink - skipped"; continue; fi
    v="$(installed_version "$p")"
    if [[ -n "$v" && "$(cmp_version "$v" "$VERSION")" == "0" ]] && head -5 "$p/SKILL.md" 2>/dev/null | grep -qE '^name:[[:space:]]*blueprint[[:space:]]*$'; then
      echo "  $p  already $VERSION"
    else
      echo "  $p  ${v:-unknown version} -> $VERSION"; targets+=("$p")
    fi
  done < "$MANIFEST"
  [[ ${#targets[@]} -gt 0 ]] || { echo; echo "Already up to date."; exit 0; }
  [[ $DRY -eq 1 ]] && { echo; echo "dry run - nothing written"; exit 0; }
  if [[ $YES -eq 0 ]]; then
    [[ -t 0 ]] || { echo "No TTY; pass --yes to update without a prompt." >&2; exit 2; }
    read -r -p "Proceed? [y/N] " ok; [[ "$ok" =~ ^[Yy]([Ee][Ss])?$ ]] || { echo "Aborted."; exit 0; }
  fi
  echo
  stamp="$(date +%Y%m%dT%H%M%S)"; local n=0
  for t in "${targets[@]}"; do
    b="$STATE_DIR/backups/$stamp/$(echo "$t" | tr '/:' '__')"; mkdir -p "$(dirname "$b")"; mv "$t" "$b"; echo "backup $t -> $b"
    cp -R "$SRC" "$t"; echo "$VERSION" > "$t/$VERSION_FILE"
    if head -5 "$t/SKILL.md" | grep -qE '^name:[[:space:]]*blueprint[[:space:]]*$'; then echo "ok     $t"; n=$((n+1)); else echo "FAIL   $t: name does not match folder"; fi
  done
  echo; echo "Updated $n cop$([[ $n -eq 1 ]] && echo y || echo ies) to blueprint $VERSION. Restart your agent to load it."
}

do_uninstall() {
  [[ -s "$MANIFEST" ]] || { echo "Manifest is empty; nothing was installed by blueprint-skill."; exit 0; }
  echo; echo "Will remove"; while read -r p; do [[ -n "$p" ]] && echo "  $p $([[ -e "$p" ]] || echo '(already gone)')"; done < "$MANIFEST"
  [[ $DRY -eq 1 ]] && { echo; echo "dry run - nothing removed"; exit 0; }
  if [[ $YES -eq 0 ]]; then read -r -p "Proceed? [y/N] " ok; [[ "$ok" =~ ^[Yy]([Ee][Ss])?$ ]] || { echo "Aborted."; exit 0; }; fi
  while read -r p; do [[ -n "$p" && -e "$p" && ! -L "$p" ]] && rm -rf "$p"; done < "$MANIFEST"
  rm -f "$MANIFEST"; echo "Removed. Backups, if any, stay in $STATE_DIR/backups."
}

do_doctor() {
  local latest="$1" newest="$VERSION" stale=0 v vnote
  [[ -n "$latest" && "$(cmp_version "$latest" "$VERSION")" == "1" ]] && newest="$latest"
  echo; echo "Versions"
  echo "  installer        $VERSION"
  echo "  latest on npm    ${latest:-unknown (offline or check disabled)}"
  echo; echo "Agents on this machine"
  for a in "${AGENTS[@]}"; do printf "  %-26s %s\n" "$(field "$a" 2)" "$(detected "$a" && echo detected || echo 'not found')"; done
  echo; echo "blueprint copies"
  for d in "$SHARED_DIR" $(for a in "${AGENTS[@]}"; do field "$a" 4; done); do
    t="$d/$SKILL_NAME"; [[ -e "$t" ]] || continue
    status="ok"; head -5 "$t/SKILL.md" 2>/dev/null | grep -qE '^name:[[:space:]]*blueprint' || status="name does not match folder"
    managed=""; [[ -f "$MANIFEST" ]] && grep -qxF "$t" "$MANIFEST" || managed="(not in manifest - unmanaged)"
    v="$(installed_version "$t")"
    if [[ -z "$v" ]]; then vnote="version unknown"; stale=1
    elif [[ "$(cmp_version "$v" "$newest")" == "-1" ]]; then vnote="$v, outdated"; stale=1
    else vnote="$v"; fi
    echo "  $t  $status  $vnote $managed"
  done
  # When this installer is newer than npm (a local checkout), @latest would go backwards.
  local cmd="$UPDATE_CMD"; [[ "$newest" == "$VERSION" ]] && cmd="./install.sh update"
  [[ $stale -eq 1 ]] && { echo; echo "  To update every copy in the manifest, run: $cmd"; }
  echo
}

case "$CMD" in
  doctor) do_doctor "$(fetch_latest)" ;;
  update) do_update "$(fetch_latest)" ;;
  install|uninstall)
    trap 'newer_notice "$(fetch_latest)"' EXIT   # do_install/do_uninstall may exit early
    if [[ "$CMD" == install ]]; then do_install; else do_uninstall; fi ;;
esac
