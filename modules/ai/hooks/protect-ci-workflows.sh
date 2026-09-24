#!/usr/bin/env bash
# PreToolUse (Edit|Write): ask before editing CI definitions — anything under
# .github/workflows/ or an action.yml/action.yaml. Emits a permissionDecision
# of "ask" so the user confirms; every other path exits 0 without output.
#
# @jq@ is substituted with a store path by modules/ai/hooks.nix.
set -euo pipefail

FILE_PATH=$(@jq@ -r '.tool_input.file_path // .tool_input.path // empty')

case "$FILE_PATH" in
  */.github/workflows/*) KIND="CI workflow" ;;
  */action.yml|*/action.yaml) KIND="composite action" ;;
  *) exit 0 ;;
esac

@jq@ -cn --arg kind "$KIND" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: ("This is a " + $kind + ". Changes take effect for every caller on their next run; confirm before editing.")
  }
}'
