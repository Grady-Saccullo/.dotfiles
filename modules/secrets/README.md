# `secrets`: reading secret values at runtime

One place to say **how secret values are fetched**. Any module that needs a token, password or
connection string reads it through the host's **secrets hook**, a small program the host chooses.
The framework does not depend on any password manager, or on having one at all: a hook can read
from 1Password, Bitwarden, the macOS Keychain, a hardware token or anything else.

## The rule

**Secret values never enter the Nix store.** The store is readable by every user on the machine and
a switch step may push the whole closure to a binary cache, so a value that becomes a Nix string has
already left the machine. Only *references* (an `op://` URI, an item name) may appear in Nix; the
hook turns them into values when they are needed.

## Options

| Option | Type | Default |
| --- | --- | --- |
| `secrets.hook` | package or `null` | a hook built from `readCommand`, or `null` without one |
| `secrets.readCommand` | list of strings | the `backend` preset, or `[]` |
| `secrets.backend` | `null`, `"op"`, `"rbw"` or `"bw"` | `null` |
| `switch.hook` | package or `null` | `secrets.hook` (see [modules/switch](../switch/README.md)) |

There are three ways to set a host up, from least to most work:

1. **A preset.** `secrets.backend = "op";` reads with a password manager CLI the framework already
   knows:

   | backend | runs | reference | CLI provided by |
   | --- | --- | --- | --- |
   | `op` | `op read --no-newline <ref>` | `op://Vault/item/field` | 1Password desktop app (macOS) |
   | `rbw` | `rbw get <ref>` | item name, or a list of `rbw get` arguments | nixpkgs |
   | `bw` | `bw get password --nointeraction <ref>` | item id or name | nixpkgs (`applications.bitwarden.cli.enable`) |

   The CLI is looked up on `PATH` when a secret is read. None of them prompts: `bw` needs an
   unlocked vault in the environment (`export BW_SESSION=$(bw unlock --raw)`) and otherwise fails
   straight away.
2. **Any command that prints one secret.** `secrets.readCommand = ["pass" "show"];` runs
   `pass show <ref>` once per reference. It must not prompt.
3. **Your own hook.** `secrets.hook = pkgs.callPackage ./my-secrets-hook.nix {};` for anything
   else: a password manager without a preset, one unlock shared by several reads, or no password
   manager at all.
   The hook is a package in your own flake, so it is versioned with your hosts and brings its own
   tools (the first switch on a new machine can use it before anything is installed).

The first two build a hook for you with `utils.secrets.mkReadCommandHook`, so everything below
applies to all three. Leaving all of them unset is fine on hosts that declare no secret references.
As soon as one is declared, evaluation fails with a message telling you to set one.

## The hook contract (version 1)

A hook is an executable (the package's `meta.mainProgram`). The framework runs it with no
arguments, once for each batch of secrets it needs: once per `nix run .#switch` for every step's
secrets, and once each time a wrapped program starts (for example an MCP server).

**stdin** is one JSON request:

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

- `version`: reject any version you do not know (exit non-zero).
- `purpose`: who is asking, for messages only: `switch`, or `runtime:<name>` for a wrapped program.
- `interactive`: `true` only when a person is at a terminal. Then the hook may prompt, on
  `/dev/tty` (stdin and stdout carry the request and the answer). When `false` it must not prompt in
  the terminal at all: a wrapped MCP server talks to its client over stdin and stdout, and a prompt
  would corrupt the client's screen.
- `refs`: label to reference, exactly as written in the Nix config (a string or a list of strings).
  The framework never looks inside a reference, so its format is up to the hook. Labels only name
  the keys of the answer: the switch uses `<step>.<label>` and strips the prefix again itself.

**stdout** is one JSON object from label to value, and nothing else:

```json
{"login.token": "the read token", "upload.token": "the push token"}
```

A label that is missing means that read failed. The exit status is `0` when stdout holds an answer
(even a partial one) and non-zero when nothing could be read. **stderr** is shown to the person as
it is: use it for warnings, errors and anything that explains a prompt.

Rules for the hook:

- **Values go to stdout only.** Never put one in a command argument (other processes can read
  those), an environment variable you export, or a file. To build the JSON, pipe the value into
  `jq -Rs`, as below; `jq --arg v "$value"` would put it in `jq`'s arguments.
- **Unlock at most once per call, and lock again before exiting**, also when something fails or
  the switch is interrupted (`trap ... EXIT` in bash). Session keys stay inside the hook and the
  tool that needs them.
- **Never block.** Anything that goes wrong (not set up, prompt cancelled, wrong password, tool
  missing) is a message on stderr and a missing label or a non-zero exit. The switch then runs its
  steps without those values (warning when the hook failed); a wrapped program fails to start with
  a clear message.

In return, the framework only sends references, reads the answer through pipes (never a temporary
file or a command argument) and never exports a value, except into the program a wrapper starts.

### Writing one

The framework's example host has a complete hook that reads the macOS Keychain, so it needs no
password manager: [`hosts/example/secrets-hook.sh`](../../hosts/example/secrets-hook.sh), packaged
in [`hosts/example/default.nix`](../../hosts/example/default.nix). Its core is the pattern every
bash hook needs:

```bash
request=$(cat)
while IFS= read -r -d '' label; do
  ref=$(printf '%s' "$request" | jq -r --arg k "$label" '.refs[$k]')
  if value=$(my-password-cli get "$ref" </dev/null); then
    printf '%s' "$value" | jq -Rs --arg k "$label" '{($k): .}'
  fi
done < <(printf '%s' "$request" | jq -j '.refs | keys[] | . + "\u0000"') | jq -s 'add // {}'
```

A hook that unlocks a vault does it once before that loop, and locks again in an `EXIT` trap.

`tests/fake-secrets-hook` is the smallest possible hook (a fixed table). `tests/secrets.sh` tests
the hooks and wrappers, and `tests/switch.sh` runs the real `apps/switch` against a hook with every
external command stubbed: no password manager, no Nix build, no `sudo`. `tests/lib.sh` has the
helpers, so a consumer can test its own hook the same way (see that file).

## Consuming: `utils.secrets.mkEnvWrapper`

Modules never run the hook themselves; they wrap the program:

```nix
utils.secrets.mkEnvWrapper {
  inherit pkgs;
  name = "ai-mcp-my-server";                 # script is named secret-env-<name>
  hook = config.secrets.hook;
  secretEnv = {
    DATABASE_URL = "op://Vault/my-server/database_url";
    API_TOKEN = ["--field" "token" "my-server"];
  };
  command = "/path/to/my-server";
  args = ["serve"];
}
```

The result is a script that, when run:

1. extends `PATH` with `/usr/local/bin`, `/opt/homebrew/bin` and `/run/current-system/sw/bin` so
   CLIs installed outside Nix are found;
2. sends every reference to the hook in one request (`purpose` is `runtime:<name>`, `interactive`
   is true only when stdin and stderr are a terminal), exports each value under its variable name,
   and exits 1 with `<name>: failed to read secret for VAR` if one is missing;
3. `exec`s `<command> <args> "$@"`.

Modules should also assert `config.secrets.hook != null` whenever they hold at least one secret
reference, so a missing hook fails at evaluation rather than at launch. `modules/ai/mcp.nix` does
this.
