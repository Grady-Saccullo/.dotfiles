# Helpers for testing a secrets hook (modules/secrets/README.md) and apps/switch without a password
# manager, a Nix build or root. Source it from a script run with `/bin/bash -e`, as tests/secrets.sh
# does; a consumer can source it from the framework input to test its own hook the same way.

tests_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
framework_dir=$(dirname "$tests_dir")
real_jq=$(command -v jq)
passed=0
failed=0
sandboxes=()

function pass() {
	passed=$((passed + 1))
	echo "  ok    $*"
}

function fail() {
	failed=$((failed + 1))
	echo "  FAIL  $*"
}

# check <description> <command...>
function check() {
	local description=$1
	shift
	if "$@"; then pass "$description"; else fail "$description"; fi
}

# has / lacks <file> <text>
function has() { grep -qF -- "$2" "$1" 2>/dev/null; }
function lacks() { ! has "$@"; }

# Deletes every sandbox, unless KEEP_SANDBOXES is set to look at them after a failure.
function remove_sandboxes() {
	[[ -n "${KEEP_SANDBOXES:-}" || ${#sandboxes[@]} == 0 ]] || rm -rf "${sandboxes[@]}"
}

function summary() {
	echo
	echo "$passed passed, $failed failed"
	[[ $failed == 0 ]]
}

# with <VAR=value> <command...>: runs a command or function with one more exported variable.
function with() { (
	export "${1?}"
	shift
	"$@"
); }

# A fresh $sandbox: bin/ holds the stubs (first on PATH in run_switch and run_spied), flake/ is where
# apps/switch runs, log gets one line per stub call and leaks one line per secret a stub was given.
function new_sandbox() {
	sandbox=$(mktemp -d "${TMPDIR:-/tmp}/secrets-test.XXXXXX")
	sandboxes+=("$sandbox")
	mkdir "$sandbox/bin" "$sandbox/flake"
	: >"$sandbox/log"
	: >"$sandbox/leaks"
	: >"$sandbox/forbidden"
	export SANDBOX=$sandbox
	cat >"$sandbox/spy.sh" <<'EOF'
# Sourced by every stub as `spy.sh <name> <args...>`: logs the call and records any forbidden value
# found in the arguments or in an environment variable not listed in SPY_ALLOW_ENV.
spy_name=$1
shift
{
	printf '%s' "$spy_name"
	printf ' %q' "$@"
	echo
} >>"$SANDBOX/log"
while IFS= read -r spy_value; do
	[[ -n $spy_value ]] || continue
	for spy_arg in "$@"; do
		[[ $spy_arg != *"$spy_value"* ]] || echo "$spy_name: a secret in its arguments" >>"$SANDBOX/leaks"
	done
	for spy_var in $(compgen -e); do
		case " ${SPY_ALLOW_ENV:-} " in *" $spy_var "*) continue ;; esac
		[[ ${!spy_var} != *"$spy_value"* ]] || echo "$spy_name: a secret in \$$spy_var" >>"$SANDBOX/leaks"
	done
done <"$SANDBOX/forbidden"
EOF
	stub jq "exec '$real_jq' \"\$@\""
	for tool in awk cmp tee chmod; do
		stub "$tool" "exec '$(PATH=/usr/bin:/bin command -v "$tool")' \"\$@\""
	done
}

# forbid <value>: a stub that sees <value> in its arguments or environment records a leak.
function forbid() { printf '%s\n' "$1" >>"$sandbox/forbidden"; }

function no_leaks() {
	if [[ -s "$sandbox/leaks" ]]; then
		fail "no secret in any command's arguments or environment:"
		sed 's/^/          /' "$sandbox/leaks"
	else
		pass "no secret in any command's arguments or environment"
	fi
}

# stub <name> <body> [env vars allowed to hold a secret]: a command on the sandbox PATH that is spied
# on, then runs <body>.
function stub() {
	{
		echo '#!/bin/bash -e'
		[[ -z "${3:-}" ]] || echo "SPY_ALLOW_ENV='$3'"
		echo ". \"\$SANDBOX/spy.sh\" $1 \"\$@\""
		printf '%s\n' "$2"
	} >"$sandbox/bin/$1"
	chmod +x "$sandbox/bin/$1"
}

# The commands apps/switch runs besides the hook. `nix eval` prints $sandbox/switch-config.json,
# STUB_HOOK_BUILD_RC fails the hook build, and STUB_SUDO_FAIL=<command> fails `sudo <command>`.
function stub_switch_commands() {
	stub nix '
case "$1" in
eval) cat "$SANDBOX/switch-config.json" ;;
build)
	for arg in "$@"; do installable=$arg; done
	case "$installable" in
	*.config.cachix.hook) exit "${STUB_HOOK_BUILD_RC:-0}" ;;
	*.system)
		mkdir -p result/sw/bin
		cp "$SANDBOX/bin/darwin-rebuild" result/sw/bin/
		;;
	esac
	;;
esac'
	stub darwin-rebuild ':'
	stub sudo '[[ "${STUB_SUDO_FAIL:-}" != "$1" ]] || exit 1
exec "$@"'
	stub cachix 'printf "%s\n" "$CACHIX_AUTH_TOKEN" >"$SANDBOX/pushed-with"' CACHIX_AUTH_TOKEN
}

# switch_config <json>: what `nix eval ...cachix.switchConfig` prints for the next run_switch.
function switch_config() { printf '%s' "$1" >"$sandbox/switch-config.json"; }

# run_switch <args...>: runs apps/switch with no terminal; its output goes to $sandbox/out.
function run_switch() {
	(cd "$sandbox/flake" && PATH="$sandbox/bin:$PATH" /bin/bash -e "$framework_dir/apps/switch" "$@" \
		</dev/null >"$sandbox/out" 2>&1)
}

# run_spied <stdin file> <command...>: runs a command with the sandbox PATH; stdout goes to
# $sandbox/stdout and stderr to $sandbox/stderr.
function run_spied() {
	local input=$1
	shift
	PATH="$sandbox/bin:$PATH" "$@" <"$input" >"$sandbox/stdout" 2>"$sandbox/stderr"
}
