#!/bin/bash -e
# shellcheck source-path=SCRIPTDIR disable=SC2016

# Tests app re-signing (modules/codesign/README.md) with stub codesign, security and openssl, so no
# keychain or certificate is touched. Run it as `/bin/bash -e tests/codesign.sh`.
. "$(dirname "$0")/lib.sh"
trap remove_sandboxes EXIT

identity="Nix self-signed"
sign_apps=$framework_dir/modules/codesign/sign-apps.sh
create_identity=$framework_dir/modules/codesign/create-identity.sh

# codesign_sandbox <identity>...: a sandbox whose keychain holds these identities. The stub codesign
# reports each app's signature from its `signature` file and fails to sign Broken.app; the stub
# openssl keeps the certificate request it is given.
function codesign_sandbox() {
	new_sandbox
	printf '%s\n' "$@" >"$sandbox/identities"
	stub security '
case "$1" in
find-identity)
	n=0
	while IFS= read -r id; do
		[[ -n $id ]] || continue
		n=$((n + 1))
		printf "  %s) 0123ABCD \"%s\" (CSSMERR_TP_NOT_TRUSTED)\n" "$n" "$id"
	done <"$SANDBOX/identities"
	echo "     $n identities found"
	;;
import) ;;
*) exit 2 ;;
esac'
	stub codesign '
for arg in "$@"; do app=$arg; done
if [[ $1 == -dvv ]]; then
	signature=$(cat "$app/signature")
	if [[ $signature == adhoc ]]; then echo "Signature=adhoc" >&2; else echo "Authority=$signature" >&2; fi
elif [[ $app == *Broken* ]]; then
	echo "$app: errSecInternalComponent" >&2
	exit 1
fi'
	stub openssl '
previous=
for arg in "$@"; do
	if [[ $previous == -config ]]; then
		dirname "$arg" >"$SANDBOX/workdir"
		cp "$arg" "$SANDBOX/req.cnf"
	fi
	previous=$arg
done'
	mkdir "$sandbox/apps" "$sandbox/system"
}

# app <dir> <name> <signature>: an app bundle whose stub signature is "adhoc" or an authority.
function app() {
	mkdir "$sandbox/$1/$2.app"
	printf '%s' "$3" >"$sandbox/$1/$2.app/signature"
}

# signed <dir>/<name>: codesign was asked to re-sign that app with the identity.
function signed() {
	has "$sandbox/log" "$(printf 'codesign --force --deep --preserve-metadata=entitlements --sign %q %q' "$identity" "$sandbox/$1.app")"
}

# sign <args...>: runs sign-apps with the identity on the sandbox's apps, reporting its system apps.
function sign() { run_spied /dev/null /bin/bash -e "$sign_apps" "$identity" "$sandbox/apps" "$sandbox/system"; }

echo "sign-apps"
codesign_sandbox "Other identity" "$identity"
app apps WezTerm adhoc
app apps Hoppscotch adhoc
app apps Brave "Developer ID Application: Brave Software, Inc. (KL8N8XSYF4)"
app system AeroSpace adhoc
app system UTM "Developer ID Application: Turing Software, LLC (WDNLXAD4W8)"
check "exits 0" sign
check "signs each ad-hoc signed app, keeping its entitlements" eval 'signed apps/WezTerm && signed apps/Hoppscotch'
check "says what it signed" has "$sandbox/stdout" "codesign: signed $sandbox/apps/WezTerm.app"
check "leaves a developer-signed app alone" eval '! signed apps/Brave'
check "signs nothing installed system-wide" eval '! signed system/AeroSpace'
check "reports an ad-hoc signed app installed system-wide" \
	has "$sandbox/stderr" "codesign: $sandbox/system/AeroSpace.app is ad-hoc signed and installed system-wide"
check "but not a developer-signed one" lacks "$sandbox/stderr" UTM

codesign_sandbox "$identity"
app apps Broken adhoc
app apps WezTerm adhoc
check "exits 1 when an app cannot be signed" eval '! sign'
check "still signs the others" signed apps/WezTerm
check "says which app keeps its ad-hoc signature, with codesign's error" \
	eval 'has "$sandbox/stderr" "could not sign $sandbox/apps/Broken.app, so it keeps its ad-hoc signature" && has "$sandbox/stderr" "errSecInternalComponent"'

codesign_sandbox "$identity (old)"
app apps WezTerm adhoc
app system AeroSpace adhoc
check "exits 1 without an identity of exactly that name" eval '! sign'
check "points to codesign-setup" has "$sandbox/stderr" "no code-signing identity named \"$identity\" in the keychain; run \`nix run .#codesign-setup <host>\` in your flake to create it"
check "signs nothing" eval '! signed apps/WezTerm'
check "still reports the system-wide app" has "$sandbox/stderr" "$sandbox/system/AeroSpace.app is ad-hoc signed"

codesign_sandbox
app apps Brave "Developer ID Application: Brave Software, Inc. (KL8N8XSYF4)"
check "with nothing to sign, needs no identity" sign
check "and prints nothing" eval '[ ! -s "$sandbox/stdout" ] && [ ! -s "$sandbox/stderr" ]'

echo "create-identity"
codesign_sandbox "$identity"
check "exits 0 when the identity exists" run_spied /dev/null /bin/bash -e "$create_identity" "$identity"
check "creates nothing" eval 'lacks "$sandbox/log" openssl && lacks "$sandbox/log" "security import"'

codesign_sandbox
check "exits 0 after creating the identity" run_spied /dev/null /bin/bash -e "$create_identity" "$identity"
check "names the certificate after the identity, for code signing only" \
	eval 'has "$sandbox/req.cnf" "CN = $identity" && has "$sandbox/req.cnf" "extendedKeyUsage = critical,codeSigning"'
workdir=$(cat "$sandbox/workdir")
check "imports it into the login keychain, usable by codesign" \
	has "$sandbox/log" "$(printf 'security import %q -k %q -P import -T /usr/bin/codesign' "$workdir/identity.p12" "$HOME/Library/Keychains/login.keychain-db")"
check "leaves no key file behind" [ ! -e "$workdir" ]

echo "apps/codesign-setup"
codesign_sandbox
# The stub nix builds a setup that only says it ran; `flake metadata` resolves --local to local-src.
stub nix '
case "$1" in
flake) printf "{\"path\":\"%s\"}\n" "$SANDBOX/local-src" ;;
build)
	mkdir -p "$SANDBOX/setup/bin"
	printf "#!/bin/bash\necho setup ran\n" >"$SANDBOX/setup/bin/codesign-setup"
	chmod +x "$SANDBOX/setup/bin/codesign-setup"
	echo "$SANDBOX/setup"
	;;
*) exit 2 ;;
esac'
echo '{"root":"root","nodes":{"root":{"inputs":{"dotfiles":"dotfiles"}}}}' >"$sandbox/flake/flake.lock"
# setup_app <args...>: runs apps/codesign-setup from the sandbox flake.
function setup_app() { (cd "$sandbox/flake" && run_spied /dev/null /bin/bash -e "$framework_dir/apps/codesign-setup" "$@"); }
check "exits 1 without a host" eval '! setup_app'
check "asks for the host" has "$sandbox/stdout" "usage codesign-setup <config name> [--local]"
check "exits 0" setup_app my-host
check "builds the host's setup" has "$sandbox/log" ".#darwinConfigurations.my-host.config.codesign.setup"
check "against the locked framework" lacks "$sandbox/log" "--override-input"
check "runs it" has "$sandbox/stdout" "setup ran"
: >"$sandbox/log"
check "--local: exits 0" setup_app my-host --local
check "--local: builds against the local checkout" has "$sandbox/log" "--override-input dotfiles path:$sandbox/local-src"

echo "nix: codesign options (tests/hosts.nix)"
flake_url="git+file://$framework_dir"
# Assigned by capture, which shellcheck cannot follow.
hosts=
capture hosts nix eval --json --impure --expr "(import $tests_dir/hosts.nix { flake = builtins.getFlake \"$flake_url\"; }).codesign"
# q <jq filter>: true when the filter holds for the evaluated hosts.
function q() { printf '%s' "$hosts" | jq -e "$1" >/dev/null; }
check "off: nothing re-signed" q '.none == {after: null, failing: [], aerospace: {}}'
check "on: re-signs after copyApps" q '.on == {after: ["copyApps"], failing: [], aerospace: {}}'
check "on, with linked apps: fails with the assertion" \
	q '.linkedApps.failing == ["codesign.enable needs home-manager'"'"'s targets.darwin.copyApps: linked apps stay in the read-only Nix store."]'
check "AeroSpace without codesign runs from the store, installed system-wide" \
	q '.aerospace.aerospace | (.command | test("exec /nix/store/[^ ]*-aerospace-[^/]*/Applications/AeroSpace.app/Contents/MacOS/AeroSpace --config-path ")) and .app == {home: false, system: true} and .restarts == false'
check "AeroSpace with codesign runs from the home-manager copy, which gets signed" \
	q '.aerospaceSigned.aerospace | (.command | test("&& exec '"'"'/Users/test/Applications/Home Manager Apps/AeroSpace.app'"'"'/Contents/MacOS/AeroSpace --config-path /nix/store/[^ ]*-aerospace.toml$")) and .app == {home: true, system: false}'
check "and keeps the CLI system-wide" q '.aerospaceSigned.aerospace.cli'
check "and restarts AeroSpace after signing a new build" q '.aerospaceSigned.aerospace.restarts and .aerospaceSigned.failing == []'

summary
