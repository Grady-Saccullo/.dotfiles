#!/usr/bin/env bash
# PostToolUse (Edit|Write): fail loudly when an edited .yml/.yaml no longer
# parses. Exit 2 feeds the parser error back to the model; anything that is
# not a YAML file, or no longer exists, exits 0 silently.
#
# @jq@ / @python3@ are substituted with store paths by modules/ai/hooks.nix.
set -euo pipefail

FILE_PATH=$(@jq@ -r '.tool_input.file_path // .tool_input.path // empty')

case "$FILE_PATH" in
  *.yml|*.yaml) ;;
  *) exit 0 ;;
esac

[ -f "$FILE_PATH" ] || exit 0

# safe_load_all so multi-document files (k8s manifests) are not false alarms;
# print only the parser message, not a traceback.
if ! ERROR=$(@python3@ -c 'import sys, yaml
try:
    with open(sys.argv[1]) as f:
        list(yaml.safe_load_all(f))
except yaml.YAMLError as e:
    sys.exit(str(e))' "$FILE_PATH" 2>&1); then
  echo "YAML syntax error in $FILE_PATH:" >&2
  echo "$ERROR" >&2
  exit 2
fi
