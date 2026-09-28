# `switch`: rebuilding a machine and running its steps

`nix run .#switch <host>` builds the host, switches to it and runs the **steps** the host declares:
small programs that run before the build or after the switch. The framework ships no steps and
knows nothing about any cache or service. A step is a package in your own flake, so it is versioned
with your hosts and brings its own tools.

A typical use is a private binary cache (Cachix, attic, S3 and so on): a `preBuild` step logs in to
it so the build can download from it, and a `postSwitch` step uploads the new system. Downloading
also needs the cache as a substituter, either in the `nixConfig` of the flake you run (Nix only
reads `nixConfig` from that flake) or in `nix.settings`.

## What a switch does

1. Reads the host's plan (`switch.plan`) with `nix eval`: the enabled steps, sorted by name.
2. If there are steps, builds all of them, and the secrets hook when a step has secrets, with one
   `nix build` (`switch.tools`).
3. If a step has secrets, asks the hook for the secrets of every step in one call.
4. Runs the `preBuild` steps in name order.
5. Builds the system, runs `darwin-rebuild switch` (`nixos-rebuild switch` on NixOS) and prints the
   package changes.
6. Runs the `postSwitch` steps in name order, then forgets the secrets.

Each step starts with a `=== <name> ===` header. Its stdout and stderr go to the terminal.

## Options

| Option | Type | Default |
| --- | --- | --- |
| `switch.hook` | package or `null` | `secrets.hook` |
| `switch.steps.<name>.enable` | bool | `true` |
| `switch.steps.<name>.phase` | `"preBuild"` or `"postSwitch"` | required |
| `switch.steps.<name>.package` | package; its `meta.mainProgram` is run | required |
| `switch.steps.<name>.secrets` | label to reference (a string or a list of strings) | `{}` |
| `switch.steps.<name>.settings` | any JSON value, passed to the step as it is | `{}` |

- `switch.hook` is a secrets hook as described in [modules/secrets](../secrets/README.md). Only set
  it when the steps' secrets live somewhere else than the host's other secrets.
- `secrets` holds references, never values. `settings` is for everything that is not secret (a
  cache name, a URL, a file path), and ends up in the Nix store.
- Step names and secret labels may only use letters, digits, `-` and `_`
  (`^[A-Za-z0-9_-]+$`), because the switch joins them as `<step>.<label>`.
- A step with secrets on a host without a hook fails evaluation, with a message naming the step.
- `switch.plan` and `switch.tools` are internal and read-only: what the switch reads with
  `nix eval --json`, and the one derivation that holds every enabled step's package and the hook
  they need.

## Phases

- **`preBuild`** runs before the system is built, for anything the build needs: logging in to a
  cache, for example. `system` in its input is `null`.
- **`postSwitch`** runs after `darwin-rebuild switch` and the package changes, with `system` set to
  the new system's store path: uploading it to a cache or sending a notification, for example.

A failed build or switch stops `nix run .#switch` as it always has, so the `postSwitch` steps only
run after a successful switch.

## Step input

The step gets one JSON document on stdin and no arguments:

```json
{
  "version": 1,
  "step": "upload",
  "host": "my-mac",
  "phase": "postSwitch",
  "interactive": true,
  "system": "/nix/store/...-darwin-system-...",
  "settings": {"store": "s3://my-cache?region=eu-west-1"},
  "secrets": {"token": "the token"}
}
```

- `version`: reject any version you do not know (exit non-zero).
- `step`, `host`, `phase`: the step's name, the host being switched and the phase.
- `interactive`: `true` only when a person is at a terminal (the switch's stdin and stderr are both a
  terminal).
  Only then may the step prompt, and on `/dev/tty`, because stdin carries the input.
- `system`: `null` in `preBuild`, the new system's store path in `postSwitch`.
- `settings`: the step's `settings`, as declared.
- `secrets`: the values of this step's own labels, and nothing from other steps. A label the hook
  could not read is missing, and the step decides what to do without it.

## Secrets

Before the build, the switch asks the hook for the secrets of every step in **one** request, so a
hook that unlocks a vault unlocks it once and can lock it again before the build starts. The
request follows the [hook contract](../secrets/README.md#the-hook-contract-version-1), with
`purpose` set to `switch` and each label prefixed with its step's name:

```json
{
  "version": 1,
  "purpose": "switch",
  "interactive": true,
  "refs": {
    "login.token": "my-cache-read",
    "upload.token": ["--field", "token", "my-cache"]
  }
}
```

The switch strips the prefix again, so the `upload` step gets `{"token": "..."}` in its `secrets`.
The hook's answer only travels through pipes: the switch never puts a value in a command argument,
an exported variable or a file, and forgets it after the last step.

## Failures

A step never stops the switch. Anything that goes wrong is a warning, and the switch carries on:

| What happened | What the switch does |
| --- | --- |
| A step exits non-zero | `warning: switch step <name> failed (exit N); carrying on` |
| The hook fails, or answers something that is not a JSON object | Warns and runs the steps with no secrets |
| The steps or the hook cannot be built | Warns and runs no steps |
| `switch.plan` cannot be evaluated | Warns with the first `error:` line from Nix and runs no steps |
| The plan has another format version | Says which, and runs no steps (see below) |

## Format version

The plan carries a format version. This switch reads version 1. When it finds another one, it says
that the host's steps use another format and that updating the `dotfiles` input, or switching with
`--local`, brings the two back in step. The step input also carries `version: 1`.

## `--local`

`nix run .#switch <host> -- --local` builds against your local checkout of the framework (root
README, "Changing the framework"). It also runs that checkout's own `apps/switch` instead of the
one locked in your flake, and prints a line saying so. That way the script and the modules always
come from the same snapshot, and an older switch never reads a plan it does not understand.

## Writing a step

- Read stdin once and check `version`. Take values out of the input with `jq`, reading it from a
  pipe (`printf '%s' "$input" | jq ...`).
- A secret value only travels through pipes, or into the environment of the one program that
  needs it (`TOKEN=$token some-tool`). Never put it in a command argument (other processes can read
  those), a variable you export, a file, or a bash here-string or heredoc (macOS bash 3.2 backs
  those with temporary files).
- When a secret is missing or something fails, print a message on stderr and exit non-zero. The
  switch warns and carries on.
- Steps run as your user. A step that writes a root-owned file (for example `/etc/nix/netrc`) runs
  `sudo` itself.
- Steps run on every switch, so make them cheap when there is nothing to do, for example by only
  writing a file when its content changed.

A `postSwitch` step that uploads the new system to an S3 binary cache with `nix copy`, with its
credentials read by the host's secrets hook:

```nix
{pkgs, ...}: {
  switch.steps.upload = {
    phase = "postSwitch";
    settings.store = "s3://my-cache?region=eu-west-1";
    secrets = {
      keyId = "my-cache-access-key-id";
      secretKey = "my-cache-secret-access-key";
    };
    package = pkgs.writeShellApplication {
      name = "upload-system";
      runtimeInputs = [pkgs.jq];
      text = ''
        input=$(cat)
        if ! printf '%s' "$input" | jq -e '.version == 1' >/dev/null; then
          echo "upload: unknown input version" >&2
          exit 2
        fi
        store=$(printf '%s' "$input" | jq -r .settings.store)
        system=$(printf '%s' "$input" | jq -r .system)
        key_id=$(printf '%s' "$input" | jq -r '.secrets.keyId // empty')
        secret_key=$(printf '%s' "$input" | jq -r '.secrets.secretKey // empty')
        if [[ -z $key_id || -z $secret_key ]]; then
          echo "upload: no credentials for $store; skipping the upload" >&2
          exit 1
        fi
        echo "uploading $system to $store"
        AWS_ACCESS_KEY_ID=$key_id AWS_SECRET_ACCESS_KEY=$secret_key nix copy --to "$store" "$system"
      '';
    };
  };
}
```

The example host has a smaller one that needs no secrets: a notification after every switch, in
[`hosts/example/default.nix`](../../hosts/example/default.nix).

## Coming from `cachix.*`

Earlier versions of the framework logged in to and pushed to a Cachix cache themselves, through the
`cachix.*` options. Those options are gone, and setting one fails evaluation with a message pointing
here. The same thing is now two steps in your own flake: a `preBuild` step that logs in and a
`postSwitch` step that pushes, each with its token in `secrets`.

## Testing

`tests/switch.sh` runs the real `apps/switch` with every external command stubbed: no Nix build, no
`darwin-rebuild` and no `sudo`. `tests/lib.sh` has the helpers (`stub_switch_commands`,
`switch_plan`, `run_switch` and checks that no secret reached a command's arguments or
environment), and `tests/fake-step` is a step that only records its input. A flake with its own
steps can source `tests/lib.sh` from the framework input and test them the same way. Run the tests
with `/bin/bash -e tests/switch.sh`: `bash file` ignores the `-e` in the shebang.
