#!/bin/bash -e
# shellcheck source-path=SCRIPTDIR disable=SC2016

# Tests the secrets hook plumbing (modules/secrets/README.md) with no password manager, Nix build or
# root; tests/switch.sh covers the switch. Run it as `/bin/bash -e tests/secrets.sh`: `bash file`
# ignores the -e in the shebang.
. "$(dirname "$0")/lib.sh"
trap remove_sandboxes EXIT

read_token=fake-read-token-7c1e

echo "read-command hook (the presets' adapter)"
new_sandbox
forbid "$read_token"
forbid "  two words"
stub fakecli '
case "$*" in
"get fake/read") printf "%s" fake-read-token-7c1e ;;
"get --field token my-item") printf "  two words\n" ;;
*) echo "fakecli: no such item: $*" >&2; exit 1 ;;
esac'
printf '%s' '{"version":1,"purpose":"switch","interactive":false,"refs":{"a":"fake/read","b":["--field","token","my-item"],"c":"missing"}}' >"$sandbox/request"
check "exits 0" run_spied "$sandbox/request" /bin/bash -e "$framework_dir/modules/secrets/read-command-hook.sh" fakecli get
check "answers the readable references, trailing newline dropped" \
	[ "$(jq -c . "$sandbox/stdout")" = "{\"a\":\"$read_token\",\"b\":\"  two words\"}" ]
check "passes a list reference as separate arguments" has "$sandbox/log" "fakecli get --field token my-item"
check "reports the failed one on stderr" has "$sandbox/stderr" "could not read c"
no_leaks
printf '%s' '{"version":2,"refs":{}}' >"$sandbox/request"
check "rejects an unknown version" eval '! run_spied "$sandbox/request" /bin/bash -e "$framework_dir/modules/secrets/read-command-hook.sh" fakecli get'

echo "example host's Keychain hook, with a stub security command"
new_sandbox
forbid "$read_token"
stub security '
[[ "$1 $2 $3" == "find-generic-password -w -s" ]] || exit 2
case "$4" in
my-cache-read) echo fake-read-token-7c1e ;;
*) echo "security: SecKeychainSearchCopyNext: The specified item could not be found in the keychain." >&2; exit 44 ;;
esac'
printf '%s' '{"version":1,"purpose":"switch","interactive":true,"refs":{"login.token":"my-cache-read","push.token":"my-cache-push"}}' >"$sandbox/request"
check "exits 0" run_spied "$sandbox/request" /bin/bash -e "$framework_dir/hosts/example/secrets-hook.sh"
check "answers the one it found" [ "$(jq -c . "$sandbox/stdout")" = "{\"login.token\":\"$read_token\"}" ]
check "names the missing one" has "$sandbox/stderr" "no Keychain password named 'my-cache-push' (for push.token)"
no_leaks

echo "nix: secrets options (tests/hosts.nix)"
flake_url="git+file://$framework_dir"
# Assigned by capture, which shellcheck cannot follow.
hosts=
capture hosts nix eval --json --impure --expr "(import $tests_dir/hosts.nix { flake = builtins.getFlake \"$flake_url\"; }).secrets"
# q <jq filter>: true when the filter holds for the evaluated hosts.
function q() { printf '%s' "$hosts" | jq -e "$1" >/dev/null; }
check "no settings: no hook" q '.none | .secretsHook == null and .failing == []'
check "secrets.backend = op: the op preset hook" q '.op | .secretsHook == .expected'
check "secrets.hook = a package: used as it is" q '.custom | .failing == [] and (.secretsHook | endswith("-my-hook.drv"))'
check "an MCP secret without a hook fails with the assertion, not an evaluation error" q '.mcpWithoutHook.failing[0] | startswith("ai.mcpServers: a server uses a `{ secret = ...; }` env reference but there is\nno `secrets.hook`.")'

echo "nix: mkEnvWrapper and a preset hook (tests/wrappers.nix)"
new_sandbox
forbid "$read_token"
# built <attr>: the store path of a tests/wrappers.nix attribute.
function built() {
	nix build --no-link --print-out-paths --impure \
		--expr "(import $tests_dir/wrappers.nix { flake = builtins.getFlake \"$flake_url\"; }).$1" 2>/dev/null
}
# Assigned by capture, which shellcheck cannot follow.
wrapped='' missing='' via_read_command='' op_preset=''
capture wrapped built wrapped
capture missing built missing
capture via_read_command built viaReadCommand
capture op_preset built opPreset
op_preset=$op_preset/bin/secrets-read-command-hook
export FAKE_HOOK_LOG="$sandbox/requests"
check "a wrapped program starts" run_spied /dev/null "$wrapped"
check "with the secret in its environment" has "$sandbox/stdout" "A=$read_token"
check "and an awkward value intact" has "$sandbox/stdout" 'B= two  words, a "quote" and a newline'
check "from one runtime request, not interactive" \
	[ "$(jq -cS . "$sandbox/requests")" = '{"interactive":false,"purpose":"runtime:test","refs":{"A":"fake/read","B":"fake/odd"},"version":1}' ]
check "without the hook's answer in its environment" lacks "$sandbox/stdout" "response="
check "a missing secret stops the program starting" eval "! run_spied /dev/null '$missing'"
check "with a message naming it" has "$sandbox/stderr" "test: failed to read secret for C"
check "and the program never ran" lacks "$sandbox/stdout" "A="
: >"$sandbox/requests"
check "in a terminal the request is interactive" /usr/bin/expect -c "
	log_user 0
	spawn -noecho $wrapped
	catch {expect eof}
	exit [lindex [wait] 3]"
check "(checked)" [ "$(jq -r .interactive "$sandbox/requests")" = true ]
stub fakecli '[ "$*" = "get fake/read" ] && printf "%s" fake-read-token-7c1e'
check "readCommand still works without a hook" run_spied /dev/null "$via_read_command"
check "(its secret arrives)" has "$sandbox/stdout" "A=$read_token"
stub op '[ "$*" = "read --no-newline op://Vault/item/field" ] && printf "%s" fake-read-token-7c1e'
printf '%s' '{"version":1,"purpose":"switch","interactive":false,"refs":{"read":"op://Vault/item/field"}}' >"$sandbox/request"
check "the built op preset hook answers" run_spied "$sandbox/request" "$op_preset"
check "(with the value)" [ "$(jq -c . "$sandbox/stdout")" = "{\"read\":\"$read_token\"}" ]
no_leaks

summary
