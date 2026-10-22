#!/usr/bin/env bash
# install.sh — bash fallback for machines without Node. Same behaviour as
# `npx blueprint-skill`: pick agents, print the plan, confirm, copy (never symlink),
# back up what it replaces, record every written path in a manifest.
set -euo pipefail

SKILL_NAME="blueprint"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$SKILL_NAME"
STATE_DIR="$HOME/.blueprint-skill"
MANIFEST="$STATE_DIR/manifest"
SHARED_DIR="$HOME/.agents/skills"

# id|label|detect path|target dir|shared(1 = reads ~/.agents/skills)
AGENTS=(
  "claude|Claude Code|$HOME/.claude|$HOME/.claude/skills|0"
  "codex|OpenAI Codex|$HOME/.codex|$HOME/.codex/skills|1"
  "cursor|Cursor|$HOME/.cursor|$HOME/.cursor/skills|1"
  "antigravity|Google Antigravity IDE|$HOME/.gemini/antigravity|$HOME/.gemini/config/skills|1"
  "antigravity-cli|Antigravity CLI|$HOME/.gemini/antigravity-cli|$HOME/.gemini/antigravity-cli/skills|0"
  "copilot|VS Code / GitHub Copilot|$HOME/.copilot|$HOME/.copilot/skills|1"
)

CLIENTS=(); ALL=0; YES=0; DRY=0; NATIVE=0; PROJECT=""; CMD="install"
while [[ $# -gt 0 ]]; do
  case "$1" in
    install|uninstall|doctor) CMD="$1" ;;
    -c|--client) CLIENTS+=("$2"); shift ;;
    --client=*) CLIENTS+=("${1#*=}") ;;
    -a|--all) ALL=1 ;;
    -y|--yes) YES=1 ;;
    -n|--dry-run) DRY=1 ;;
    --native) NATIVE=1 ;;
    -p|--project) PROJECT="$(cd "${2:-.}" && pwd)"; shift ;;
    --project=*) PROJECT="$(cd "${1#*=}" && pwd)" ;;
    -h|--help)
      cat <<USAGE
install.sh — install the "blueprint" skill (bash fallback for npx blueprint-skill)

  ./install.sh [install] [-c <id>]... [-a] [-p <dir>] [--native] [-n] [-y]
  ./install.sh uninstall [-n] [-y]
  ./install.sh doctor

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
    q|"") exit 0 ;;
    a) for a in "${AGENTS[@]}"; do detected "$a" && CHOSEN+=("$a"); done ;;
    e) CHOSEN=("${AGENTS[@]}") ;;
    *) for n in ${ans//,/ }; do [[ "$n" =~ ^[0-9]+$ ]] && [[ $n -ge 1 && $n -le ${#AGENTS[@]} ]] && CHOSEN+=("${AGENTS[$((n-1))]}"); done ;;
  esac
}

targets_for() {
  local t=()
  for a in "$@"; do
    if [[ "$(field "$a" 5)" == "1" && $NATIVE -eq 0 ]]; then t+=("$SHARED_DIR/$SKILL_NAME")
    else t+=("$(field "$a" 4)/$SKILL_NAME"); [[ "$(field "$a" 5)" == "1" ]] && t+=("$SHARED_DIR/$SKILL_NAME"); fi
  done
  printf "%s\n" "${t[@]}" | awk '!seen[$0]++'
}

do_install() {
  [[ -f "$SRC/SKILL.md" ]] || { echo "Skill source not found at $SRC" >&2; exit 1; }
  CHOSEN=()
  if [[ -n "$PROJECT" ]]; then
    TARGETS=("$PROJECT/.agents/skills/$SKILL_NAME" "$PROJECT/.claude/skills/$SKILL_NAME" "$PROJECT/.github/skills/$SKILL_NAME")
  else
    if [[ $ALL -eq 1 ]]; then for a in "${AGENTS[@]}"; do detected "$a" && CHOSEN+=("$a"); done
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
    mkdir -p "$(dirname "$t")"; cp -R "$SRC" "$t"
    if head -5 "$t/SKILL.md" | grep -qE '^name:[[:space:]]*blueprint[[:space:]]*$'; then echo "ok     $t"; grep -qxF "$t" "$MANIFEST" || echo "$t" >> "$MANIFEST"
    else echo "FAIL   $t: name does not match folder"; fi
  done
  echo; echo "Installed. Restart your agent, then type /blueprint (Codex: \$blueprint)."
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
  echo; echo "Agents on this machine"
  for a in "${AGENTS[@]}"; do printf "  %-26s %s\n" "$(field "$a" 2)" "$(detected "$a" && echo detected || echo 'not found')"; done
  echo; echo "blueprint copies"
  for d in "$SHARED_DIR" $(for a in "${AGENTS[@]}"; do field "$a" 4; done); do
    t="$d/$SKILL_NAME"; [[ -e "$t" ]] || continue
    status="ok"; head -5 "$t/SKILL.md" 2>/dev/null | grep -qE '^name:[[:space:]]*blueprint' || status="name does not match folder"
    managed=""; [[ -f "$MANIFEST" ]] && grep -qxF "$t" "$MANIFEST" || managed="(not in manifest - unmanaged)"
    echo "  $t  $status $managed"
  done; echo
}

case "$CMD" in install) do_install ;; uninstall) do_uninstall ;; doctor) do_doctor ;; esac
