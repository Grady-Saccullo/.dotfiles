#!/bin/bash -e

# Tests the secrets hook plumbing (modules/secrets/README.md) with no password manager, Nix build or
# root. Run it as `/bin/bash -e tests/secrets.sh`: `bash file` ignores the -e in the shebang.
. "$(dirname "$0")/lib.sh"
trap remove_sandboxes EXIT

read_token=fake-read-token-7c1e
push_token=fake-push-token-94d2
fake_hook="$tests_dir/fake-secrets-hook"

# config <hook or null> <refs json>: the switch config of a host with the cache `my-cache`.
function config() {
	local hook=null
	[[ $1 == null ]] || hook="\"$1\""
	switch_config "{\"cache\":\"my-cache\",\"hook\":$hook,\"refs\":$2,\"netrcFile\":\"$sandbox/netrc\"}"
}

function switch_sandbox() {
	new_sandbox
	stub_switch_commands
	forbid "$read_token"
	forbid "$push_token"
	export FAKE_HOOK_LOG="$sandbox/requests"
}

function switched() { has "$sandbox/log" "darwin-rebuild switch"; }
function pushed_with() { [[ $(cat "$sandbox/pushed-with" 2>/dev/null) == "$1" ]]; }
function not_pushed() { lacks "$sandbox/log" "cachix push"; }
function requests() { if [[ -f "$sandbox/requests" ]]; then wc -l <"$sandbox/requests" | tr -d ' '; else echo 0; fi; }
function netrc_is() { [[ $(cat "$sandbox/netrc" 2>/dev/null) == "$1" ]]; }
function out_lacks_tokens() { lacks "$sandbox/out" "$read_token" && lacks "$sandbox/out" "$push_token"; }

echo "switch, no cache configured"
switch_sandbox
switch_config "{\"cache\":null,\"hook\":null,\"refs\":{},\"netrcFile\":\"$sandbox/netrc\"}"
check "succeeds" run_switch example
check "builds and switches" switched
check "builds no hook" lacks "$sandbox/log" "cachix.hook"
check "pushes nothing" not_pushed

echo "switch, cache but no hook and no token references"
switch_sandbox
config null '{}'
check "succeeds" run_switch example
check "builds and switches" switched
check "says the netrc is left alone" has "$sandbox/out" "no cachix.readToken; leaving $sandbox/netrc as it is"
check "does not create the netrc" test ! -e "$sandbox/netrc"
check "says the push is skipped" has "$sandbox/out" "no Cachix push token (set cachix.pushToken); skipping the push"
check "pushes nothing" not_pushed

echo "switch, no hook, CACHIX_AUTH_TOKEN in the environment"
switch_sandbox
config null '{}'
check "succeeds" with CACHIX_AUTH_TOKEN=token-from-env run_switch example
check "pushes with the environment's token" pushed_with token-from-env

echo "switch, fake hook with both tokens"
switch_sandbox
config "$fake_hook" '{"read":"fake/read","push":"fake/push"}'
printf 'machine other.example.com password keep-me\nmachine my-cache.cachix.org password old-token\n' >"$sandbox/netrc"
check "succeeds" run_switch example
check "calls the hook once" [ "$(requests)" = 1 ]
check "sends a version 1 switch request with the references, not interactive" \
	[ "$(jq -c . "$sandbox/requests")" = '{"version":1,"purpose":"switch","interactive":false,"refs":{"read":"fake/read","push":"fake/push"}}' ]
check "replaces only the cache's netrc line" \
	netrc_is "$(printf 'machine other.example.com password keep-me\nmachine my-cache.cachix.org password %s' "$read_token")"
check "writes the netrc through sudo tee" has "$sandbox/log" "sudo tee $sandbox/netrc"
check "builds and switches" switched
check "pushes with the push token" pushed_with "$push_token"
check "prints no warning" lacks "$sandbox/out" "warning:"
check "prints no token" out_lacks_tokens
no_leaks
: >"$sandbox/log"
check "a second switch succeeds" run_switch example
check "and leaves an unchanged netrc alone, without sudo" lacks "$sandbox/log" "sudo tee"
no_leaks

echo "switch, hook fails"
switch_sandbox
config "$sandbox/bin/failing-hook" '{"read":"fake/read","push":"fake/push"}'
stub failing-hook 'cat >/dev/null; echo "vault: cancelled" >&2; exit 1'
echo 'machine my-cache.cachix.org password old-token' >"$sandbox/netrc"
check "succeeds" run_switch example
check "shows the hook's message" has "$sandbox/out" "vault: cancelled"
check "warns" has "$sandbox/out" "warning: the secrets hook failed; skipping the Cachix tokens"
check "keeps the netrc" netrc_is 'machine my-cache.cachix.org password old-token'
check "builds and switches" switched
check "pushes nothing" not_pushed

echo "switch, hook prints something that is not a JSON object"
switch_sandbox
config "$sandbox/bin/garbage-hook" '{"read":"fake/read"}'
stub garbage-hook 'cat >/dev/null; echo "not json"'
check "succeeds" run_switch example
check "warns" has "$sandbox/out" "warning: the secrets hook failed"
check "does not create the netrc" test ! -e "$sandbox/netrc"
check "builds and switches" switched

echo "switch, hook answers only the read token"
switch_sandbox
config "$fake_hook" '{"read":"fake/read","push":"fake/unknown"}'
check "succeeds" run_switch example
check "writes the read token" netrc_is "machine my-cache.cachix.org password $read_token"
check "warns about the push token" has "$sandbox/out" "could not read the Cachix push token; the push will be skipped"
check "pushes nothing" not_pushed
no_leaks

echo "switch, the hook does not build"
switch_sandbox
config "$fake_hook" '{"read":"fake/read","push":"fake/push"}'
check "succeeds" with STUB_HOOK_BUILD_RC=1 run_switch example
check "warns" has "$sandbox/out" "warning: could not build the secrets hook"
check "never runs the hook" [ "$(requests)" = 0 ]
check "builds and switches" switched

echo "switch, sudo fails while writing the netrc"
switch_sandbox
config "$fake_hook" '{"read":"fake/read","push":"fake/push"}'
check "succeeds" with STUB_SUDO_FAIL=tee run_switch example
check "warns" has "$sandbox/out" "warning: could not write $sandbox/netrc"
check "builds and switches" switched
check "still pushes" pushed_with "$push_token"
no_leaks

echo "switch, token references but no hook"
switch_sandbox
config null '{"read":"fake/read"}'
check "succeeds" run_switch example
check "warns" has "$sandbox/out" "cachix token references are set but there is no secrets hook"
check "builds and switches" switched

echo "switch, in a terminal"
switch_sandbox
config "$fake_hook" '{"read":"fake/read","push":"fake/push"}'
export FRAMEWORK_DIR=$framework_dir
check "succeeds" /usr/bin/expect -c '
	log_user 0
	log_file -a -noappend $env(SANDBOX)/transcript
	set timeout 60
	spawn -noecho /bin/bash -c "cd \"$env(SANDBOX)/flake\" && PATH=\"$env(SANDBOX)/bin:$env(PATH)\" /bin/bash -e \"$env(FRAMEWORK_DIR)/apps/switch\" example"
	catch {expect eof}
	exit [lindex [wait] 3]'
check "shows the switch in the terminal" has "$sandbox/transcript" "=== Package changes ==="
check "marks the request interactive" [ "$(jq -r .interactive "$sandbox/requests")" = true ]
check "shows no token in the terminal" eval 'lacks "$sandbox/transcript" "$read_token" && lacks "$sandbox/transcript" "$push_token"'
no_leaks

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
printf '%s' '{"version":1,"purpose":"switch","interactive":true,"refs":{"read":"my-cache-read","push":"my-cache-push"}}' >"$sandbox/request"
check "exits 0" run_spied "$sandbox/request" /bin/bash -e "$framework_dir/hosts/example/secrets-hook.sh"
check "answers the one it found" [ "$(jq -c . "$sandbox/stdout")" = "{\"read\":\"$read_token\"}" ]
check "names the missing one" has "$sandbox/stderr" "no Keychain password named 'my-cache-push' (for push)"
no_leaks

echo "nix: option defaults and assertions (tests/hosts.nix)"
flake_url="git+file://$framework_dir"
hosts=$(nix eval --json --impure --expr "import $tests_dir/hosts.nix { flake = builtins.getFlake \"$flake_url\"; }" 2>/dev/null)
# q <jq filter>: true when the filter holds for the evaluated hosts.
function q() { printf '%s' "$hosts" | jq -e "$1" >/dev/null; }
check "no settings: no hook anywhere, nothing for the switch" q '.none | .secretsHook == null and .cachixHook == null and .failing == [] and .switchConfig == {cache: null, hook: null, netrcFile: "/etc/nix/netrc", refs: {}}'
check "secrets.backend = op: the op preset hook, shared with cachix" q '.op | .secretsHook == .expected and .cachixHook == .expected and (.switchConfig.hook | endswith("/bin/secrets-read-command-hook"))'
check "cachix.backend = rbw: its own preset hook for the tokens" q '.opRbw | .cachixHook == .expected and .cachixHook != .secretsHook'
check "cachix.backend = null: no hook for the tokens" q '.opNoCachixPreset | .cachixHook == null and .secretsHook != null'
check "secrets.hook = a package: used for the tokens, references passed as written" q '.custom | .cachixHook == .secretsHook and .failing == [] and .switchConfig.cache == "my-cache" and .switchConfig.refs == {read: "r", push: ["--field", "p"]} and (.switchConfig.hook | endswith("/bin/my-hook"))'
check "token references without a hook fail evaluation" q '.refsWithoutHook.failing[0] | startswith("cachix.readToken / cachix.pushToken are set but there is nothing to read them with.")'
check "token references without a cache fail evaluation" q '.refsWithoutCache.failing == ["cachix.readToken / cachix.pushToken are set but cachix.cache is not."]'
check "an MCP secret without a hook fails with the assertion, not an evaluation error" q '.mcpWithoutHook.failing[0] | startswith("ai.mcpServers: a server uses a `{ secret = ...; }` env reference but there is\nno `secrets.hook`.")'
check "the switch can build a host's hook by attribute" nix build --no-link "$flake_url#darwinConfigurations.example.config.cachix.hook" 2>/dev/null

echo "nix: mkEnvWrapper and a preset hook (tests/wrappers.nix)"
new_sandbox
forbid "$read_token"
# built <attr>: the store path of a tests/wrappers.nix attribute.
function built() {
	nix build --no-link --print-out-paths --impure \
		--expr "(import $tests_dir/wrappers.nix { flake = builtins.getFlake \"$flake_url\"; }).$1" 2>/dev/null
}
wrapped=$(built wrapped)
missing=$(built missing)
via_read_command=$(built viaReadCommand)
op_preset=$(built opPreset)/bin/secrets-read-command-hook
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
