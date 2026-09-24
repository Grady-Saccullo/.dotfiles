# `secrets` — runtime secret resolution bus

One place to say **how secret values are fetched at runtime**. Any module
that needs a token, password or connection string at launch reads
`config.secrets.readCommand` instead of hard-coding a CLI, so switching from
1Password to Bitwarden (or anything else) is a one-line change on the host.

## The rule

**Secret values never enter the Nix store.** The store is world-readable and
`apps/switch` pushes the whole closure to Cachix, so a value that becomes a
Nix string has already left the machine. Only *references* (an `op://` URI,
an item name) may appear in Nix; the value is read by the backend CLI when the
program starts.

## Options

| Option | Shape | Default |
| --- | --- | --- |
| `secrets.backend` | `null \| "op" \| "rbw" \| "bw"` | `null` |
| `secrets.readCommand` | `listOf str` | derived from `backend` (below) |

`readCommand` is the command that prints one secret to stdout given the
reference as trailing arguments:

| backend | `readCommand` | CLI provided by |
| --- | --- | --- |
| `op` | `op read --no-newline` | 1Password desktop app (macOS) |
| `rbw` | `rbw get` | nixpkgs |
| `bw` | `bw get password` | nixpkgs |

The CLI is looked up on `PATH` at runtime; this module installs nothing.
Set `secrets.readCommand` directly to use a custom backend.

## Host setup

```nix
# hosts/<host>/default.nix
secrets.backend = "op";
```

Leaving `backend` unset is fine on hosts that declare no secret references.
As soon as one is declared, the consuming module's assertion fails
evaluation with a message telling you to set `secrets.backend`.

## Consuming: `utils.secrets.mkEnvWrapper`

Consumers never call the CLI themselves; they wrap the program:

```nix
utils.secrets.mkEnvWrapper {
  inherit pkgs;
  name = "ai-mcp-my-server";                 # script is named secret-env-<name>
  readCommand = config.secrets.readCommand;
  secretEnv = {
    DATABASE_URL = "op://Vault/my-server/database_url";  # string: one trailing arg
    API_TOKEN = ["--field" "token" "my-server"];          # list: passed verbatim
  };
  command = "/path/to/my-server";
  args = ["serve"];
}
```

The result is a `writeShellScript` derivation that, when executed:

1. extends `PATH` with `/usr/local/bin`, `/opt/homebrew/bin` and
   `/run/current-system/sw/bin` so GUI-installed CLIs are found;
2. runs `<readCommand> <ref>` for each variable and exports the result,
   exiting 1 with `<name>: failed to read secret for VAR` on stderr if any
   read fails;
3. `exec`s `<command> <args> "$@"`.

Consumers should also assert `config.secrets.readCommand != []` whenever
they hold at least one secret reference, so a missing backend fails at
evaluation time rather than at launch. `modules/ai/mcp.nix` is the reference
implementation.

## Reference formats

| backend | reference | example |
| --- | --- | --- |
| `op` | `op://Vault/item/field` | `"op://Work/my-server/database_url"` |
| `rbw` | item name, or a list of `rbw get` args | `"github-token"`, `["--field" "token" "github"]` |
| `bw` | item id or name | `"github-token"` |
