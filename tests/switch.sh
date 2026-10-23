#!/bin/bash -e
# shellcheck source-path=SCRIPTDIR disable=SC2016

# Tests apps/switch and switch steps (modules/switch/README.md) with no Nix build, darwin-rebuild or
# root. Run it as `/bin/bash -e tests/switch.sh`: `bash file` ignores the -e in the shebang.
. "$(dirname "$0")/lib.sh"
trap remove_sandboxes EXIT
unset DOTFILES_LOCAL DOTFILES_SWITCH_REEXEC STUB_LOCAL_SRC STUB_TOOLS_BUILD_RC STUB_SUDO_FAIL FAKE_STEP_RC

read_token=fake-read-token-7c1e
push_token=fake-push-token-94d2
fake_step="$tests_dir/fake-step"

# The steps of most plans. `push` also asks for a reference the fake hook cannot answer.
login='{"name":"login","phase":"preBuild","secrets":{"token":"fake/read"},"settings":{"cache":"my-cache"}}'
plain='{"name":"plain","phase":"postSwitch","secrets":{},"settings":{}}'
push='{"name":"push","phase":"postSwitch","secrets":{"token":"fake/push","other":"fake/unknown"},"settings":{"cache":"my-cache","n":[1,2]}}'

# Stubbed switch commands, plus a spied `hook` that is the fake hook and spied steps that run the
# fake step, so the log shows the order and a secret in their arguments or environment is caught.
function switch_sandbox() {
	new_sandbox
	stub_switch_commands
	stub hook "exec '$tests_dir/fake-secrets-hook'"
	for step in login plain push; do
		stub "$step" "exec '$fake_step'"
	done
	forbid "$read_token"
	forbid "$push_token"
	export FAKE_HOOK_LOG="$sandbox/requests" FAKE_STEP_LOG="$sandbox/steps"
}

# plan <hook stub or null> <step json...>: a version 1 plan; each step runs the stub of its name.
function plan() {
	local hook=null
	[[ $1 == null ]] || hook="\"$sandbox/bin/$1\""
	shift
	switch_plan "$(printf '%s\n' "$@" | jq -sc --argjson hook "$hook" --arg bin "$sandbox/bin/" \
		'{version: 1, hook: $hook, steps: map(. + {exe: ($bin + .name)})}')"
}

# count <file>: its number of lines, 0 when it does not exist.
function count() { if [[ -f "$1" ]]; then wc -l <"$1" | tr -d ' '; else echo 0; fi; }
function requests() { count "$sandbox/requests"; }
function steps_run() { count "$sandbox/steps"; }
# input <n>: what the nth step that ran got on stdin.
function input() { sed -n "${1}p" "$sandbox/steps"; }
function switched() { called "darwin-rebuild switch"; }
function out_lacks_tokens() { lacks "$sandbox/out" "$read_token" && lacks "$sandbox/out" "$push_token"; }
# called <command regex>: a stub was run as that command (a log line is its name and its arguments).
function called() { grep -qE -- "^$1( |\$)" "$sandbox/log"; }
# line <command regex>: the number of the first log line of that command.
function line() { grep -nE -- "^$1( |\$)" "$sandbox/log" | head -n 1 | cut -d: -f1; }
# before <command regex> <command regex>: the first ran before the second.
function before() {
	local first second
	first=$(line "$1")
	second=$(line "$2")
	[[ -n $first && -n $second && $first -lt $second ]]
}

echo "switch, switch.plan does not evaluate"
switch_sandbox
check "succeeds" run_switch example
check "warns" has "$sandbox/out" "warning: could not read switch.plan for example; running without switch steps"
check "shows nix's error" has "$sandbox/out" "error: attribute 'plan' missing"
check "builds no switch.tools" lacks "$sandbox/log" "switch.tools"
check "asks no hook" [ "$(requests)" = 0 ]
check "builds and switches" switched

echo "switch, switch.plan in another format"
switch_sandbox
plan hook "$login" "$plain"
switch_plan "$(jq -c '.version = 2' "$sandbox/plan.json")"
check "succeeds" run_switch example
check "warns with both formats" has "$sandbox/out" "the switch steps of example use format 2, but this switch reads format 1"
check "says how to fix it" has "$sandbox/out" "update the dotfiles input or run with --local"
check "builds no switch.tools" lacks "$sandbox/log" "switch.tools"
check "asks no hook" [ "$(requests)" = 0 ]
check "runs no step" [ "$(steps_run)" = 0 ]
check "builds and switches" switched

echo "switch, switch.plan that is not a valid plan"
switch_sandbox
switch_plan '{"version":1,"hook":null,"steps":[{"name":"login","phase":"preBuild"}]}'
check "succeeds" run_switch example
check "warns" has "$sandbox/out" "warning: the switch steps of example are not a valid plan; running without them"
check "builds no switch.tools" lacks "$sandbox/log" "switch.tools"
check "runs no step" [ "$(steps_run)" = 0 ]
check "builds and switches" switched

echo "switch, flakes enabled for every nix call"
switch_sandbox
plan null
check "succeeds" with NIX_CONFIG="max-jobs = 2" run_switch example
check "adds flakes to NIX_CONFIG" has "$sandbox/nix-config" "extra-experimental-features = nix-command flakes"
check "and keeps what was there" has "$sandbox/nix-config" "max-jobs = 2"

echo "switch, no steps"
switch_sandbox
plan null
check "succeeds" run_switch example
check "builds no switch.tools" lacks "$sandbox/log" "switch.tools"
check "asks no hook" [ "$(requests)" = 0 ]
check "builds and switches" switched
check "shows the package changes" has "$sandbox/out" "=== Package changes ==="
check "prints no warning" lacks "$sandbox/out" "warning:"

echo "switch, preBuild and postSwitch steps with secrets"
switch_sandbox
plan hook "$login" "$plain" "$push"
stub plain "echo 'plain: on stdout'; echo 'plain: on stderr' >&2; exec '$fake_step'"
check "succeeds" run_switch example
check "builds switch.tools once" [ "$(grep -c 'switch\.tools' "$sandbox/log")" = 1 ]
check "(by attribute)" has "$sandbox/log" "nix build --no-link .#darwinConfigurations.example.config.switch.tools"
check "asks the hook once" [ "$(requests)" = 1 ]
check "for every step's secrets, labelled <step>.<label>, not interactive" \
	[ "$(cat "$sandbox/requests")" = '{"version":1,"purpose":"switch","interactive":false,"refs":{"login.token":"fake/read","push.token":"fake/push","push.other":"fake/unknown"}}' ]
check "builds the steps, then asks the hook" before 'nix build --no-link' hook
check "runs the preBuild step before the build" before login 'nix build .*\.system'
check "runs the postSwitch steps after the switch and the package diff" \
	eval 'before "darwin-rebuild switch" "nix store diff-closures" && before "nix store diff-closures" plain'
check "in name order" before plain push
check "runs each step once" [ "$(steps_run)" = 3 ]
check "login gets no system, its settings and only its secret" \
	[ "$(input 1)" = "{\"version\":1,\"step\":\"login\",\"host\":\"example\",\"phase\":\"preBuild\",\"interactive\":false,\"system\":null,\"settings\":{\"cache\":\"my-cache\"},\"secrets\":{\"token\":\"$read_token\"}}" ]
check "plain gets the built system and no secrets" \
	[ "$(input 2)" = "{\"version\":1,\"step\":\"plain\",\"host\":\"example\",\"phase\":\"postSwitch\",\"interactive\":false,\"system\":\"$sandbox/system\",\"settings\":{},\"secrets\":{}}" ]
check "push gets its answered secret, without the prefix, and not the missing one" \
	[ "$(input 3)" = "{\"version\":1,\"step\":\"push\",\"host\":\"example\",\"phase\":\"postSwitch\",\"interactive\":false,\"system\":\"$sandbox/system\",\"settings\":{\"cache\":\"my-cache\",\"n\":[1,2]},\"secrets\":{\"token\":\"$push_token\"}}" ]
check "shows a header for each step" eval 'has "$sandbox/out" "=== login ===" && has "$sandbox/out" "=== plain ===" && has "$sandbox/out" "=== push ==="'
check "shows the step's stdout and stderr" eval 'has "$sandbox/out" "plain: on stdout" && has "$sandbox/out" "plain: on stderr"'
check "prints no warning" lacks "$sandbox/out" "warning:"
check "prints no token" out_lacks_tokens
no_leaks

echo "switch, steps without secrets"
switch_sandbox
plan null "$plain"
check "succeeds" run_switch example
check "asks no hook" eval '[ "$(requests)" = 0 ] && ! called hook'
check "runs the step with empty secrets" [ "$(jq -c .secrets "$sandbox/steps")" = '{}' ]

echo "switch, a secrets variable exported by the caller"
switch_sandbox
plan hook "$login" "$plain" "$push"
check "succeeds" with secrets=from-the-caller run_switch example
check "the steps get their secrets" [ "$(jq -r '.secrets.token // empty' "$sandbox/steps" | tr '\n' ' ')" = "$read_token $push_token " ]
no_leaks

echo "switch, hook fails"
switch_sandbox
plan hook "$login" "$plain" "$push"
stub hook 'cat >/dev/null; echo "vault: cancelled" >&2; exit 1'
check "succeeds" run_switch example
check "shows the hook's message" has "$sandbox/out" "vault: cancelled"
check "warns" has "$sandbox/out" "warning: the secrets hook failed; switch steps run without their secrets"
check "still runs every step" [ "$(steps_run)" = 3 ]
check "with no secrets" [ "$(jq -c .secrets "$sandbox/steps" | sort -u)" = '{}' ]
check "builds and switches" switched

for answer in 'not json' '["fake-read-token-7c1e"]' '"fake-push-token-94d2"'; do
	echo "switch, hook answers $answer"
	switch_sandbox
	plan hook "$login" "$push"
	printf '%s\n' "$answer" >"$sandbox/answer"
	stub hook 'cat >/dev/null; cat "$SANDBOX/answer"'
	check "succeeds" run_switch example
	check "warns" has "$sandbox/out" "warning: the secrets hook failed; switch steps run without their secrets"
	check "still runs every step, with no secrets" [ "$(jq -c .secrets "$sandbox/steps" | tr '\n' ' ')" = '{} {} ' ]
	check "builds and switches" switched
	check "prints no token" out_lacks_tokens
	no_leaks
done

echo "switch, failing steps"
switch_sandbox
plan hook "$login" "$plain" "$push"
stub login "FAKE_STEP_RC=3 exec '$fake_step'"
stub plain "FAKE_STEP_RC=4 exec '$fake_step'"
check "succeeds" run_switch example
check "warns about the preBuild step" has "$sandbox/out" "warning: switch step login failed (exit 3); carrying on"
check "builds and switches" switched
check "warns about the postSwitch step" has "$sandbox/out" "warning: switch step plain failed (exit 4); carrying on"
check "still runs the later step" eval 'called push && [ "$(steps_run)" = 3 ]'
check "(with its secret)" [ "$(input 3 | jq -r .secrets.token)" = "$push_token" ]
check "prints no token" out_lacks_tokens
no_leaks

echo "switch, the package changes cannot be shown"
switch_sandbox
plan null "$plain"
stub readlink '[[ "$1" != /nix/var/nix/profiles/system ]] || exit 1
exec /usr/bin/readlink "$@"'
check "succeeds" run_switch example
check "builds and switches" switched
check "still runs the postSwitch step" [ "$(steps_run)" = 1 ]
check "(with the new system)" [ "$(input 1 | jq -r .system)" = "$sandbox/system" ]

echo "switch, a step's program is missing"
switch_sandbox
plan null "$plain" "$push"
rm "$sandbox/bin/plain"
check "succeeds" run_switch example
check "warns" has "$sandbox/out" "warning: switch step plain failed (exit"
check "still runs the next step" [ "$(input 1 | jq -r .step)" = push ]

echo "switch, switch.tools does not build"
switch_sandbox
plan hook "$login" "$plain" "$push"
check "succeeds" with STUB_TOOLS_BUILD_RC=1 run_switch example
check "warns" has "$sandbox/out" "warning: could not build the switch steps of example; running without them"
check "never asks the hook" [ "$(requests)" = 0 ]
check "runs no step" [ "$(steps_run)" = 0 ]
check "builds and switches" switched

echo "switch, darwin-rebuild fails"
switch_sandbox
plan hook "$login" "$plain" "$push"
check "fails" eval '! with STUB_SUDO_FAIL=./result/sw/bin/darwin-rebuild run_switch example'
check "after the preBuild step" [ "$(input 1 | jq -r .step)" = login ]
check "and runs no postSwitch step" [ "$(steps_run)" = 1 ]
no_leaks

# local_flake: a flake with a `dotfiles` input, and $sandbox/local as the snapshot --local resolves to.
function local_flake() {
	echo '{"root":"root","nodes":{"root":{"inputs":{"dotfiles":"dotfiles"}}}}' >"$sandbox/flake/flake.lock"
	mkdir -p "$sandbox/local/apps"
	{
		head -n 1 "$framework_dir/apps/switch"
		echo 'echo "snapshot switch: $*"'
		tail -n +2 "$framework_dir/apps/switch"
	} >"$sandbox/local/apps/switch"
}
function run_local_switch() { with STUB_LOCAL_SRC="$sandbox/local" with DOTFILES_LOCAL="$sandbox/checkout" run_switch "$@"; }

echo "switch --local, the snapshot has its own switch"
switch_sandbox
plan hook "$login" "$plain" "$push"
local_flake
check "succeeds" run_local_switch example --local --extra-arg
check "says it hands over" has "$sandbox/out" "switching to the local framework's switch: $sandbox/local/apps/switch"
check "runs the snapshot's switch once, with the other arguments" \
	eval '[ "$(grep -c "snapshot switch" "$sandbox/out")" = 1 ] && has "$sandbox/out" "snapshot switch: example --extra-arg"'
check "which uses the local framework" has "$sandbox/out" "using local framework: $sandbox/checkout -> $sandbox/local"
check "reads the plan from it" has "$sandbox/log" "nix eval --json --override-input dotfiles path:$sandbox/local .#darwinConfigurations.example.config.switch.plan"
check "builds the steps from it" has "$sandbox/log" "nix build --no-link --override-input dotfiles path:$sandbox/local .#darwinConfigurations.example.config.switch.tools"
check "switches once, with the other arguments" eval '[ "$(grep -c "^darwin-rebuild switch" "$sandbox/log")" = 1 ] &&
	has "$sandbox/log" "darwin-rebuild switch --show-trace --override-input dotfiles path:$sandbox/local --flake .#example --extra-arg"'
check "asks the hook once" [ "$(requests)" = 1 ]
check "runs each step once" [ "$(steps_run)" = 3 ]
no_leaks

echo "switch --local, already handed over"
switch_sandbox
plan null "$plain"
local_flake
check "succeeds" with DOTFILES_SWITCH_REEXEC=1 run_local_switch example --local
check "does not hand over again" eval 'lacks "$sandbox/out" "switching to the local" && lacks "$sandbox/out" "snapshot switch"'
check "uses the local framework" has "$sandbox/log" "nix eval --json --override-input dotfiles path:$sandbox/local"
check "switches once" [ "$(grep -c "^darwin-rebuild switch" "$sandbox/log")" = 1 ]

echo "switch --local, no DOTFILES_LOCAL in the environment"
switch_sandbox
plan null "$plain"
local_flake
check "succeeds" with HOME="$sandbox" with STUB_LOCAL_SRC="$sandbox/local" run_switch example --local
check "hands over to the snapshot's switch" has "$sandbox/out" "snapshot switch: example"
check "which still uses the default checkout" has "$sandbox/out" "using local framework: $sandbox/.dotfiles -> $sandbox/local"
check "and reads the plan from it" has "$sandbox/log" "nix eval --json --override-input dotfiles path:$sandbox/local .#darwinConfigurations.example.config.switch.plan"
check "and switches with it" has "$sandbox/log" "darwin-rebuild switch --show-trace --override-input dotfiles path:$sandbox/local --flake .#example"

# run_snapshot_switch <args...>: run_switch, but with the snapshot's own switch.
function run_snapshot_switch() {
	(cd "$sandbox/flake" && PATH="$sandbox/bin:$PATH" /bin/bash -e "$sandbox/local/apps/switch" "$@" \
		</dev/null >"$sandbox/out" 2>&1)
}

echo "switch --local, run as the snapshot's own switch"
switch_sandbox
plan null "$plain"
local_flake
check "succeeds" with STUB_LOCAL_SRC="$sandbox/local" with DOTFILES_LOCAL="$sandbox/checkout" run_snapshot_switch example --local
check "does not hand over to itself" eval 'lacks "$sandbox/out" "switching to the local" && [ "$(grep -c "snapshot switch" "$sandbox/out")" = 1 ]'
check "uses the local framework" has "$sandbox/log" "nix eval --json --override-input dotfiles path:$sandbox/local"
check "switches once" [ "$(grep -c "^darwin-rebuild switch" "$sandbox/log")" = 1 ]

echo "switch --local, a snapshot without apps/switch"
switch_sandbox
plan null "$plain"
local_flake
rm "$sandbox/local/apps/switch"
check "succeeds" run_local_switch example --local
check "runs this switch" lacks "$sandbox/out" "switching to the local"
check "with the local framework" has "$sandbox/log" "nix eval --json --override-input dotfiles path:$sandbox/local"

echo "switch --local, a flake without a dotfiles input"
switch_sandbox
plan null "$plain"
check "succeeds" run_local_switch example --local
check "says --local is ignored" has "$sandbox/out" "--local ignored: this flake has no 'dotfiles' input"
check "runs this switch, without an override" eval 'lacks "$sandbox/out" "switching to the local" && lacks "$sandbox/log" "--override-input"'

echo "switch, in a terminal"
switch_sandbox
plan hook "$login" "$plain" "$push"
export FRAMEWORK_DIR=$framework_dir
check "succeeds" /usr/bin/expect -c '
	log_user 0
	log_file -a -noappend $env(SANDBOX)/transcript
	set timeout 60
	spawn -noecho /bin/bash -c "cd \"$env(SANDBOX)/flake\" && PATH=\"$env(SANDBOX)/bin:$env(PATH)\" /bin/bash -e \"$env(FRAMEWORK_DIR)/apps/switch\" example"
	catch {expect eof}
	exit [lindex [wait] 3]'
check "the transcript caught the output" test -s "$sandbox/transcript"
check "shows the steps and the switch in the terminal" \
	eval 'has "$sandbox/transcript" "=== login ===" && has "$sandbox/transcript" "=== Package changes ===" && has "$sandbox/transcript" "=== push ==="'
check "marks the request interactive" [ "$(jq -r .interactive "$sandbox/requests")" = true ]
check "and every step's input" [ "$(jq -r .interactive "$sandbox/steps" | tr '\n' ' ')" = "true true true " ]
check "still gives each step its secret" [ "$(jq -r '.secrets.token // empty' "$sandbox/steps" | tr '\n' ' ')" = "$read_token $push_token " ]
check "shows no token in the terminal" eval 'lacks "$sandbox/transcript" "$read_token" && lacks "$sandbox/transcript" "$push_token"'
no_leaks

echo "nix: switch options (tests/hosts.nix)"
flake_url="git+file://$framework_dir"
# Assigned by capture, which shellcheck cannot follow.
hosts=
capture hosts nix eval --json --impure --expr "(import $tests_dir/hosts.nix { flake = builtins.getFlake \"$flake_url\"; }).switch"
# q <jq filter>: true when the filter holds for the evaluated hosts.
function q() { printf '%s' "$hosts" | jq -e "$1" >/dev/null; }
check "no settings: no hook and an empty plan" q '.none | .switchHook == null and .failing == [] and .plan == {version: 1, hook: null, steps: []}'
check "switch.hook defaults to secrets.hook" q '.op | .switchHook == .expected and .secretsHook == .expected'
check "a hook but no step with secrets: the plan has no hook" q '(.op.plan.hook == null) and (.noStepSecrets | .plan.hook == null and ([.plan.steps[].name] == ["plain"]))'
check "a step with secrets: the plan runs the default hook" q '.opWithSecrets | .failing == [] and (.plan.hook | endswith("/bin/secrets-read-command-hook"))'
check "enabled steps only, in name order" q '.custom | .failing == [] and [.plan.steps[] | {name, phase}] == [{name: "aa-login", phase: "preBuild"}, {name: "plain", phase: "postSwitch"}, {name: "zz-push", phase: "postSwitch"}]'
check "each step runs its package's program" q '.custom.plan.steps | all(. as $step | .exe | endswith("-\($step.name)-step/bin/\($step.name)-step"))'
check "references and settings passed as written" q '.custom.plan.steps[2] | .secrets == {token: ["--field", "p"]} and .settings == {cache: "my-cache", n: [1, 2]}'
check "secrets.hook = a package: the plan runs it" q '.custom.plan.hook | endswith("/bin/my-hook")'
check "switch.hook alone is enough" q '.switchHookOnly | .secretsHook == null and .failing == [] and (.plan.hook | endswith("/bin/switch-only-hook"))'
check "switch.hook wins over secrets.hook" q '.switchHookOverrides | .switchHook != .secretsHook and (.plan.hook | endswith("/bin/other-hook"))'
check "a step's secrets without a hook fail evaluation, naming the step" \
	q '.secretsWithoutHook.failing | length == 1 and (.[0] | startswith("switch.steps.needs.secrets is set but there is no secrets hook") and contains("modules/switch/README.md"))'
check "(and the plan is refused, so no preBuild step runs before the build fails)" q '.secretsWithoutHook.plan == "refused"'
check "a disabled step's secrets need no hook" q '.disabledWithoutHook | .failing == [] and .plan.steps == []'
check "a step name or label with a dot fails evaluation" q '.badNames.failing | length == 1 and (.[0] | startswith("switch.steps.\"a.b\": ") and contains("not: a.b, x.y."))'
check "(and its plan is refused)" q '.badNames.plan == "refused"'
check "every removed cachix option fails evaluation with the removal message" \
	q '.removedCachix.failing | length == 5 and all(contains("Cachix support left the framework") and contains("`switch.steps`, see modules/switch/README.md"))'
check "(naming each)" q '[.removedCachix.failing[] | capture("definition `cachix\\.(?<o>[A-Za-z]+)'"'"'").o] | sort == ["backend", "cache", "hook", "pushToken", "readToken"]'
function example_plan() {
	nix eval --json "$flake_url#darwinConfigurations.example.config.switch.plan" 2>/dev/null |
		jq -e '.version == 1 and .hook == null and [.steps[] | {name, phase}] == [{name: "notify", phase: "postSwitch"}]' >/dev/null
}
check "the example host's plan reads as the switch expects" example_plan
check "the switch can build the example host's switch.tools by attribute" \
	nix build --no-link "$flake_url#darwinConfigurations.example.config.switch.tools" 2>/dev/null

summary
