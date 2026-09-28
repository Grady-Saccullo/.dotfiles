#!/bin/bash -e

# Secrets hook (./README.md) behind `secrets.backend` and `secrets.readCommand`: runs the command given
# as arguments once per reference, with the reference appended. It never prompts.
if [[ $# == 0 ]]; then
	echo "usage: read-command-hook <read command...> < request.json" >&2
	exit 2
fi

request=$(cat)
if ! printf '%s' "$request" | jq -e '.version == 1 and (.refs | type == "object")' >/dev/null 2>&1; then
	echo "secrets hook: not a version 1 request" >&2
	exit 2
fi

# NUL-separated, so labels and reference arguments can hold any other character.
while IFS= read -r -d '' label; do
	ref=()
	while IFS= read -r -d '' arg; do ref+=("$arg"); done < <(
		printf '%s' "$request" | jq -j --arg k "$label" '.refs[$k] | if type == "array" then .[] else . end | tostring + "\u0000"'
	)
	if value=$("$@" "${ref[@]}" </dev/null); then
		printf '%s' "$value" | jq -Rs --arg k "$label" '{($k): .}'
	else
		echo "secrets hook: could not read $label" >&2
	fi
done < <(printf '%s' "$request" | jq -j '.refs | keys[] | . + "\u0000"') | jq -s 'add // {}'
