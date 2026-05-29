#!/bin/bash
# Weft statusline — OPTIONAL always-on glance. Plugins cannot auto-wire
# a statusline; the product is fully oriented without this (see the
# SessionStart hook). To enable, add to .claude/settings.json:
#   "statusLine": { "type": "command",
#     "command": "${CLAUDE_PLUGIN_ROOT}/bin/weft-statusline.sh" }
#
# Reads Claude session JSON on stdin and the project's Weft state file.
# Emits one concise line. Never errors out.

set -u

session_json=$(cat 2>/dev/null || echo '{}')

model="?"
if command -v jq >/dev/null 2>&1; then
  model=$(printf '%s' "$session_json" | jq -r '.model.display_name // "?"' 2>/dev/null || echo "?")
fi

STATE="${CLAUDE_PROJECT_DIR:-.}/pipeline/session-state.json"

if [ ! -f "$STATE" ]; then
  printf 'Weft · no active project · [%s]\n' "$model"
  exit 0
fi

if command -v jq >/dev/null 2>&1; then
  feature=$(jq -r '.activeFeature // "—"' "$STATE" 2>/dev/null || echo "—")
  lane=$(jq -r '.sessionType // "feature"' "$STATE" 2>/dev/null || echo "feature")
  stage=$(jq -r '.currentStage // "—"' "$STATE" 2>/dev/null || echo "—")
  printf 'Weft · %s · %s · stage %s · [%s]\n' "$lane" "$feature" "$stage" "$model"
else
  printf 'Weft · state present (install jq for detail) · [%s]\n' "$model"
fi
exit 0
