# `ai` — tool-agnostic AI configuration bus

One bus, many consumers. Everything an AI coding tool can be fed — skills,
agents, commands, rules, hooks, plugins, user-level context, MCP and LSP servers —
is declared once under `ai.*` and consumed by each tool module
(`modules/applications/claude-code` today; codex/opencode later) which maps
it onto home-manager's per-tool options.

## The dependency rule

```
app modules (jj, neovim, …)            ─┐
modules/ai/content.nix (shared dirs)    ├─ SET ──▶ ai.*
host modules                           ─┘            │
                                                     │ READ
                                                     ├──▶ modules/ai/mcp.nix        ──▶ HM programs.mcp.*
                                                     ├──▶ applications.claude-code  ──▶ HM programs.claude-code.*
                                                     └──▶ applications.<tool>       ──▶ HM programs.<tool>.*
```

* Only `modules/ai/` and tool modules write to home-manager's
  `programs.claude-code.*` / `programs.mcp.*` / `programs.<tool>.*`.
* Everyone else writes `ai.*`. `ai.*` never depends on a tool module, so the
  graph is acyclic and a second tool can consume the same bus with no changes
  to contributors.

## Options

| Option | Shape | Materialises as |
| --- | --- | --- |
| `ai.skills.<name>` | `{ enable, source \| text, description }` | `skills/<name>/` |
| `ai.agents.<name>` | same | `agents/<name>.md` |
| `ai.commands.<name>` | same | `commands/<name>.md` |
| `ai.rules.<name>` | same | `rules/<name>.md` |
| `ai.hooks.<name>` | `{ enable, event, matcher, script, timeout, description }` | `hooks/<name>` + hook wiring in tool settings |
| `ai.permissions` | `{ allow, ask, deny }` (lists of rule strings) | `permissions.allow/ask/deny` in tool settings; lists merge across modules |
| `ai.plugins.<name>` | `{ enable, source, description }` | personal plugin dir |
| `ai.context` | `lines` | user-level `CLAUDE.md` (unmanaged when empty) |
| `ai.mcpServers.<name>` | `{ enable, command, args, env, url, headers, description, …freeform }` | HM `programs.mcp.servers.<name>` |
| `ai.lspServers.<name>` | `{ enable, command, args, extensionToLanguage, description, …freeform }` | HM `programs.claude-code.lspServers.<name>` → plugin `.lsp.json` |

Secret resolution is not AI-specific and lives on its own bus:
`secrets.backend` / `secrets.readCommand`, documented in
[`modules/secrets/README.md`](../secrets/README.md).

Every named entry has `enable` defaulting to `true`. Entries are
`attrsOf submodule`, so one module can declare `source` and another (a host
config) can set only `enable = false` on the same name — the module system
merges them by attribute name with no glue code.

`ai.permissions` is the one non-named option: three plain lists that the
module system concatenates, deduplicated by the consumer. App modules publish
the read-only subcommands of the tool they install (`git status`, `gh pr view`,
…); hosts add to or override the result through the consuming tool's own
settings option.

## Adding shared content

Drop it into the sibling directories; `content.nix` registers it:

```
modules/ai/skills/<name>/SKILL.md   -> ai.skills.<name>
modules/ai/agents/<name>.md         -> ai.agents.<name>
modules/ai/commands/<name>.md       -> ai.commands.<name>
modules/ai/rules/<name>.md          -> ai.rules.<name>
```

Flakes only see git-tracked files, so `git add` new content before
building.

Rules may carry `paths:` frontmatter so they load only for matching files;
`rules/go-style.md` uses `paths: ["**/*.go", "**/go.mod"]`, while
`rules/code-comments.md` has none and applies everywhere.

**Framework-owned hooks** are not auto-registered: `hooks.nix` declares them
explicitly, with the scripts in `hooks/` using `@jq@`-style placeholders that
`pkgs.replaceVars` swaps for store paths. Hosts opt out with
`ai.hooks.<name>.enable = false`.

Shared content present today:

| Kind | Name | Purpose |
| --- | --- | --- |
| rule | `code-comments` | short, why-not-what comments; counterfactuals go in the commit/PR |
| rule | `go-style` | gofmt/vet, wrapped errors, `context.Context`, table-driven tests (Go files only) |
| agent | `go-tester` | runs Go tests and analyses failures without editing code |
| skill | `handle-change` | executes one `changes/m-NN-*` change set via fresh-context subagents |
| skill | `archive-change` | archives a finished change set and repairs references |
| skill | `test-quality` | inputs-and-observable-outputs discipline for UI tests |
| skill | `css-style-position` | style-vs-position CSS methodology for component stylesheets |
| hook | `validate-yaml` | PostToolUse: exit 2 with the parser error when an edited YAML file no longer parses |
| hook | `protect-ci-workflows` | PreToolUse: ask before editing `.github/workflows/*` or `action.yml` |

## Contributing from an app module

Inside the module's existing `mkIf enable` config block:

```nix
ai.skills.jj-gh-pr = {
  source = ./skills/jj-gh-pr;
  description = "opens GitHub PRs from jj bookmarks";
};

ai.hooks.jj-pre-edit-warning = {
  event = "PreToolUse";
  matcher = "Edit|Write|MultiEdit";
  script = preEditHookScript;
  description = "warns when @ sits at a pushed bookmark";
};
```

Prefix names with the owning app (`jj-…`) so the filesystem and the option
tree line up.

### App-contributed MCP servers

Apps with an official MCP server publish it on `ai.mcpServers` behind an
opt-in `mcp.enable` flag, mirroring how `bitwarden.browserExtension.enable`
feeds the `browser.*` bus. The app module keeps its normal config and adds
a `lib.mkIf cfg.mcp.enable` block via `lib.mkMerge`
(`modules/applications/slack/default.nix`):

```nix
extraOptions.mcp.enable = lib.mkEnableOption "the Slack MCP server …";

(lib.mkIf cfg.mcp.enable {
  ai.mcpServers.slack = {
    url = "https://mcp.slack.com/mcp";     # remote, OAuth in-app on first connect
    description = "Slack workspace: search messages, channels, threads";
  };
})
```

Host side:

```nix
applications.slack = {
  enable = true;
  mcp.enable = true;
};

ai.mcpServers.slack.enable = false;      # still overridable per host
```

This is the template for other apps with official servers (`github-cli` →
GitHub's remote MCP, and so on): one `mcp.enable` option, one bus entry,
no tool-specific wiring.

## Host overrides

A host module is a regular module and sets the same options as any other
contributor:

```nix
{...}: {
  ai.skills.jj-gh-pr.enable = false;      # opt out on this host
  ai.rules.personal-style.text = ''…'';   # host-only content
}
```

## MCP servers and secrets

```nix
secrets.backend = "op";                  # host-level, see modules/secrets

ai.mcpServers.my-server = {
  command = "/path/to/my-server";
  args = ["serve"];
  env = {
    MY_SERVER_CONFIG = "/path/to/config";                     # literal
    DATABASE_URL.secret = "op://Vault/my-server/database_url"; # resolved at start
    OTHER_TOKEN.file = "/run/secrets/other_token";            # read from file at start
  };
};

ai.mcpServers.signoz.url = "https://mcp.us.signoz.cloud/mcp";  # remote, OAuth
```

`mcp.nix` turns `{ secret }` refs into a wrapper script
(`utils.secrets.mkEnvWrapper`) that calls `secrets.readCommand` (default
per backend: `op read --no-newline`, `rbw get`, `bw get password`; see
[`modules/secrets/README.md`](../secrets/README.md)) and then `exec`s the
real server. A string secret is one trailing argument; a list is passed
verbatim. Remote servers
should prefer OAuth; header secrets would need the launching shell's
environment and are not handled here.

Disabled servers are dropped before they reach home-manager, because Claude
Code's `disabledMcpjsonServers` does not apply to plugin-provided servers.

## LSP servers

`ai.lspServers.<name>` describes a language server an AI tool may launch.
The neovim language modules (`modules/applications/neovim/configs/<lang>`)
contribute one entry each through `mkNeovimModule`'s `extraConfig`, reusing
the package neovim already installs, so Claude Code gets code intelligence
for exactly the languages a host enables. `modules/applications/claude-code`
consumes the bus into home-manager's `programs.claude-code.lspServers`, which
lands in the synthesized personal plugin's `.lsp.json`.

```nix
ai.lspServers.go = {
  command = "${pkgs.gopls}/bin/gopls";   # absolute store path
  args = ["serve"];
  extensionToLanguage = {".go" = "go";};
};

ai.lspServers.go.enable = false;                  # host opt-out
```

`command` must be an absolute store path: AI tools run from shells and GUIs
whose PATH does not include neovim's `extraPackages`. Claude Code starts only
the first server registered for a given extension, so supplementary servers
that share extensions with a primary one (htmx-lsp on `.html`, biome on
`.ts`) are deliberately not contributed.

## Sensitivity rules

* **This repository is public.** Work hostnames, repo paths, vault names
  and skills describing internal systems must not be committed here.
* **The Nix store is world-readable and `apps/switch` pushes the whole
  closure to Cachix.** A secret value that becomes a Nix string leaves the
  machine. Only references (`op://…`, file paths) may appear in Nix; values
  are resolved at runtime by the wrapper above.
* **Sensitive declarations live in the flake that consumes this one** and
  builds its hosts with `inputs.dotfiles.lib.mkDarwinHost`. Its host modules
  are evaluated inside the same module system as the public ones and simply
  set the same `ai.*` (and `secrets.*`, `identity.*`, …) options:

  ```nix
  # <consumer>/hosts/<host>/default.nix
  ai.mcpServers.internal.url = "https://mcp.example.internal/mcp";
  ai.mcpServers.my-server = {
    command = "/Users/${me.user}/code/my-server/my-server";
    args = ["serve"];
    env.DATABASE_URL.secret = "op://Private/my-server/DATABASE_URL";
  };
  ```

  Nothing in this repo needs to know which entries came from where. See the
  root README "Setting up your own machines".
