#!/bin/bash
# Weft SessionStart hook — build-readiness probe + pipeline orientation
# + plugin-update signal.
#
# Contract: exit 0 with a single JSON object on stdout. Must never
# break a session: every path emits valid JSON and exits 0.
#
# The update-signal block at the top of this script is contained and
# can be removed when the marketplace listing makes it redundant; no
# other file in the plugin has a dependency on it existing.

set -u

input=$(cat 2>/dev/null || echo '')

# -----------------------------------------------------------------
# Update notice — plugin-update-signal feature.
#
# Detects an available Weft update or a Claude Code floor violation
# and prepends a notice to whatever additionalContext the rest of the
# hook emits. Every path degrades quietly: a network error, missing
# config, malformed manifest, or absent tool produces no notice
# rather than an error in the session.
# -----------------------------------------------------------------

CC_FLOOR="2.1.150"

# Resolve the running plugin root from the script's own location, so
# the hook does not depend on CLAUDE_PLUGIN_ROOT being present in the
# script's environment (Claude Code substitutes it at launch but
# setting it for the child process is not documented behavior).
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PLUGIN_ROOT=$(dirname "$SCRIPT_DIR")

# Compare semver versions. Returns 0 if $1 > $2, 1 otherwise.
ver_gt() {
  [ "$1" = "$2" ] && return 1
  printf '%s\n%s\n' "$1" "$2" | sort -V -C -r 2>/dev/null
}

detect_cc_version() {
  local v=""
  if [ -n "${CLAUDE_CODE_EXECPATH:-}" ]; then
    v=$(printf '%s' "$CLAUDE_CODE_EXECPATH" \
      | grep -oE 'claude-code/[0-9]+\.[0-9]+\.[0-9]+' \
      | head -n 1 \
      | sed 's|claude-code/||')
    [ -n "$v" ] && printf '%s' "$v" && return 0
  fi
  if [ -n "${AI_AGENT:-}" ]; then
    v=$(printf '%s' "$AI_AGENT" \
      | grep -oE 'claude-code_[0-9]+-[0-9]+-[0-9]+' \
      | head -n 1 \
      | sed 's|claude-code_||; s|-|.|g')
    [ -n "$v" ] && printf '%s' "$v" && return 0
  fi
  printf ''
}

read_installed_version() {
  local mfile="$PLUGIN_ROOT/.claude-plugin/plugin.json"
  [ -f "$mfile" ] || return 1
  command -v jq >/dev/null 2>&1 || return 1
  jq -r '.version // empty' "$mfile" 2>/dev/null
}

discover_marketplace_url() {
  local cfg="$HOME/.claude/plugins/known_marketplaces.json"
  [ -f "$cfg" ] || return 1
  command -v jq >/dev/null 2>&1 || return 1
  jq -r '."weft-marketplace".source.url // empty' "$cfg" 2>/dev/null
}

fetch_served_version() {
  local url="$1"
  command -v curl >/dev/null 2>&1 || return 1
  command -v jq >/dev/null 2>&1 || return 1
  local manifest
  manifest=$(curl -fsS --max-time 4 --retry 2 --retry-delay 0 --retry-all-errors "$url" 2>/dev/null) || return 1
  printf '%s' "$manifest" \
    | jq -r '.plugins[]? | select(.name=="weft") | .version' 2>/dev/null \
    | head -n 1
}

count_stale_cache_siblings() {
  local parent
  parent=$(dirname "$PLUGIN_ROOT")
  local self
  self=$(basename "$PLUGIN_ROOT")
  [ -d "$parent" ] || { printf '0'; return 0; }
  ls "$parent" 2>/dev/null | grep -v "^${self}\$" | wc -l | tr -d ' '
}

build_update_notice() {
  local cc_version
  cc_version=$(detect_cc_version)

  # CC floor takes precedence: if Claude Code is too old, that is the
  # only notice that fires. Weft-update and stale-cache are suppressed
  # because they are downstream of fixing the deeper failure.
  if [ -n "$cc_version" ] && ver_gt "$CC_FLOOR" "$cc_version"; then
    printf "Claude Code %s is below Weft's minimum (%s). Older versions can install plugins with files missing. Update Claude Code before updating Weft." "$cc_version" "$CC_FLOOR"
    return 0
  fi

  local installed served url
  installed=$(read_installed_version) || installed=""
  [ -n "$installed" ] || return 0

  url=$(discover_marketplace_url) || url=""
  [ -n "$url" ] || return 0

  served=$(fetch_served_version "$url") || served=""
  [ -n "$served" ] || return 0

  local out=""
  if ver_gt "$served" "$installed"; then
    out=$(printf "Weft %s is available (you're on %s). Run claude plugin update weft@weft-marketplace and restart Claude Code to apply." "$served" "$installed")
  fi

  # Stale-cache footnote only appears alongside a Weft-update notice;
  # alone it would be noise next to a current install.
  if [ -n "$out" ]; then
    local siblings
    siblings=$(count_stale_cache_siblings)
    if [ "$siblings" -gt 0 ]; then
      local parent
      parent=$(dirname "$PLUGIN_ROOT")
      out=$(printf "%s\n\nOlder Weft versions are cached at %s (%s found). They're not in the way; clean them up when you're ready." "$out" "$parent" "$siblings")
    fi
  fi

  printf '%s' "$out"
}

UPDATE_NOTICE=$(build_update_notice 2>/dev/null || printf '')

# -----------------------------------------------------------------
# Standard emit logic. Every path prepends UPDATE_NOTICE if set.
# -----------------------------------------------------------------

emit() {
  local ctx="$1"
  # When an update or floor-violation notice exists, surface it
  # directly in the chat UI via the top-level `systemMessage`
  # field — additionalContext alone is too quiet (Claude sees it
  # but doesn't proactively surface it). We still mirror the
  # notice into additionalContext so the model has it as backup
  # context if the user asks.
  if [ -n "$UPDATE_NOTICE" ]; then
    ctx="${UPDATE_NOTICE}

${ctx}"
  fi
  if command -v jq >/dev/null 2>&1; then
    if [ -n "$UPDATE_NOTICE" ]; then
      jq -n --arg ctx "$ctx" --arg msg "$UPDATE_NOTICE" \
        '{continue: true, systemMessage: $msg, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
    else
      jq -n --arg ctx "$ctx" \
        '{continue: true, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
    fi
  else
    esc=$(printf '%s' "$ctx" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk 'BEGIN{ORS="\\n"}{print}')
    if [ -n "$UPDATE_NOTICE" ]; then
      msg_esc=$(printf '%s' "$UPDATE_NOTICE" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk 'BEGIN{ORS="\\n"}{print}')
      printf '{"continue":true,"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$msg_esc" "$esc"
    else
      printf '{"continue":true,"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$esc"
    fi
  fi
  exit 0
}

# Resolve project dir: cwd from stdin JSON → $CLAUDE_PROJECT_DIR → "."
proj=""
if command -v jq >/dev/null 2>&1 && [ -n "$input" ]; then
  proj=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || echo "")
fi
[ -z "$proj" ] && proj="${CLAUDE_PROJECT_DIR:-}"
[ -z "$proj" ] && proj="."

# Build-readiness probe. Weft can only build with a writable project
# directory. If there isn't one, guide the user instead of pretending
# the session is ready. Capability-based, not surface-name based.
if [ ! -d "$proj" ] || [ ! -w "$proj" ]; then
  emit "Weft is loaded but this session is NOT in a buildable state — there is no writable project directory. To build with Weft you need Claude Code running in a project folder (the CLI, the desktop app, or an IDE). Open or create a project folder, start Claude Code there, then run /weft. Weft cannot build from the Claude chat app or claude.ai/code."
fi

STATE="$proj/pipeline/session-state.json"

if [ ! -f "$STATE" ]; then
  emit "Weft is installed and this is a buildable project. No active Weft project here yet. Run /weft to begin."
fi

if command -v jq >/dev/null 2>&1; then
  feature=$(jq -r '.activeFeature // "none"' "$STATE" 2>/dev/null || echo "none")
  lane=$(jq -r '.sessionType // "feature"' "$STATE" 2>/dev/null || echo "feature")
  stage=$(jq -r '.currentStage // "none"' "$STATE" 2>/dev/null || echo "none")
  done_stage=$(jq -r '.lastCompletedStage // 0' "$STATE" 2>/dev/null || echo 0)
  status=$(jq -r '.lastCheckpointStatus // "unknown"' "$STATE" 2>/dev/null || echo "unknown")
  awaiting=$(jq -r 'if .awaitingHuman then "yes (" + (.awaitingHuman.gateId // "gate") + ")" else "no" end' "$STATE" 2>/dev/null || echo "unknown")
  emit "Weft pipeline state — feature: ${feature}; lane: ${lane}; current stage: ${stage}; last completed stage: ${done_stage}; checkpoint status: ${status}; awaiting human: ${awaiting}. Run /weft to continue. The state file is authoritative; re-read pipeline/session-state.json before acting."
else
  emit "Weft pipeline state file present at pipeline/session-state.json (jq not available to parse it here). Run /weft and read that file directly to orient."
fi
