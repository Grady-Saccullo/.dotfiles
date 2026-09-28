#!/bin/bash -e

# A secrets hook (modules/secrets/README.md in the framework) that needs no password manager: each
# reference is the name of a password in the login Keychain, saved with
#   security add-generic-password -s <name> -a "$USER" -w
# The login Keychain is unlocked while you are logged in, so this hook never prompts in the terminal.
request=$(cat)
if ! printf '%s' "$request" | jq -e '.version == 1' >/dev/null; then
	echo "keychain hook: not a version 1 request" >&2
	exit 2
fi

while IFS= read -r -d '' label; do
	name=$(printf '%s' "$request" | jq -r --arg k "$label" '.refs[$k] | strings')
	# The value reaches jq through a pipe: as an argument it would be visible to other processes.
	if value=$(security find-generic-password -w -s "$name" </dev/null); then
		printf '%s' "$value" | jq -Rs --arg k "$label" '{($k): .}'
	else
		echo "keychain hook: no Keychain password named '$name' (for $label)" >&2
	fi
done < <(printf '%s' "$request" | jq -j '.refs | keys[] | . + "\u0000"') | jq -s 'add // {}'
