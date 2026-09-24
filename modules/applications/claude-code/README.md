# claude-code module

Installs Claude Code and is the **sole consumer** of the tool-agnostic `ai.*`
bus declared in [`modules/ai/`](../../ai/README.md). Nothing outside this
module writes to home-manager's `programs.claude-code.*`.

## Architecture in one paragraph

App modules (`jj`, …), host configs (`hosts/<host>/ai.nix`)
and the private input all *contribute* skills, agents, commands, rules, hooks,
plugins and context to `ai.*`. This module *reads* the bus and fans it out to
home-manager, which materializes files under `~/.claude/`. MCP servers take a
parallel path: `modules/ai/mcp.nix` populates the shared `programs.mcp.servers`
registry and this module opts in with `enableMcpIntegration`. The graph is
one-directional — bus → this consumer → home-manager — so there is no
cross-module readback and no cycle risk.

```
ai.skills / agents / commands / rules ─┐
ai.hooks ───────────────────────────────┤
ai.permissions ─────────────────────────┤
ai.plugins ─────────────────────────────┼─▶ applications.claude-code ─▶ programs.claude-code.*
ai.context ─────────────────────────────┤            │                  + managed-settings.json
ai.lspServers ──────────────────────────┘            │
                                                     │
ai.mcpServers ─▶ modules/ai/mcp.nix ─▶ programs.mcp.servers ─(enableMcpIntegration)─┘
```

## Options this module reads (the bus)

| Bus option                         | Provisions to                                             |
| ---------------------------------- | --------------------------------------------------------- |
| `ai.skills.<name>`                 | `~/.claude/skills/<name>/`                                |
| `ai.agents.<name>`                 | `~/.claude/agents/<name>.md`                              |
| `ai.commands.<name>`               | `~/.claude/commands/<name>.md`                            |
| `ai.rules.<name>`                  | `~/.claude/rules/<name>.md`                               |
| `ai.hooks.<name>`                  | `~/.claude/hooks/<name>` **and** a `hooks.<event>` entry in managed-settings.json |
| `ai.permissions.{allow,ask,deny}` | `permissions.allow/ask/deny` in managed-settings.json, unioned with `managedSettings.permissions.*` |
| `ai.plugins.<name>`                | personal plugin at `~/.claude/skills/<name>/`             |
| `ai.context`                       | `~/.claude/CLAUDE.md` — only when non-empty               |
| `ai.lspServers.<name>`             | `.lsp.json` in the synthesized personal plugin (`~/.claude/skills/claude-code-home-manager/`) |
| `programs.mcp.servers` (via `modules/ai/mcp.nix`) | personal plugin `~/.claude/skills/claude-code-home-manager/.mcp.json` |

Every bus entry has an `enable` flag (default `true`). Disabling one anywhere
(`ai.skills.jj-gh-pr.enable = false;` in a host config) removes it from every
consumer.

## Options this module owns

| Option                                        | Default                                                       | Purpose |
| --------------------------------------------- | ------------------------------------------------------------- | ------- |
| `applications.claude-code.enable`             | `false`                                                       | turn the module on |
| `applications.claude-code.package`            | `pkgs.llm-agents.claude-code`                                 | package to install |
| `applications.claude-code.managedSettings`    | `{ skipAutoPermissionPrompt = true; permissions.defaultMode = "auto"; }` | enforced policy → managed-settings.json |
| `applications.claude-code.seedSettings`       | `{ model = "opus[1m]"; }`                                     | one-time defaults → `~/.claude/settings.json` |

The defaults are set with **leaf-level** `mkDefault`, so a host can add keys
(`managedSettings.permissions.allow = [ … ];`) or override a single leaf
(`managedSettings.permissions.defaultMode = "plan";`) without losing the rest.
A whole-attrset `mkDefault` would be dropped entirely the moment any key is
defined elsewhere.

## Why two settings files

home-manager renders `programs.claude-code.settings` to a read-only store
symlink, but Claude Code rewrites `~/.claude/settings.json` at runtime
(`/model`, effort, theme, …) and fails with EACCES against it (upstream
claude-code#55485 "not planned"; `mkOutOfStoreSymlink` is broken by
claude-code#15786). So:

- **`managed-settings.json`** — highest precedence, never written by the app.
  Nix owns it: `/Library/Application Support/ClaudeCode/` on darwin (root
  activation script), `/etc/claude-code/` on NixOS (`environment.etc`), and on
  generic linux the same policy is merged into the user file on every switch
  (every `hooks.<event>` array is unioned, other keys overwritten). All of
  `managedSettings` plus the hook wiring below lands here.
- **`~/.claude/settings.json`** — a real writable file owned by Claude Code.
  It is *seeded* from `seedSettings` only when absent, a stale store symlink,
  or not a JSON object. Runtime state is otherwise never touched. `model`
  lives here on purpose: in the managed file it would pin the startup model
  every launch; as a seed the `/model` choice persists.

`programs.claude-code.settings` is left empty so home-manager never renders
its own settings.json. The `home.file…enable = mkForce false` guard remains as
belt-and-braces.

## How hooks become settings entries

For every enabled `ai.hooks.<name>`:

1. The `script` is written to `~/.claude/hooks/<name>` (executable).
2. An entry is appended to `managedSettings.hooks.<event>`:

   ```json
   { "matcher": "<matcher, if set>",
     "hooks": [ { "type": "command",
                  "command": "bash \"$HOME/.claude/hooks/<name>\"",
                  "timeout": <timeout, if set> } ] }
   ```

Entries are sorted by hook name for a stable managed file. Raw `hooks` a host
puts directly in `managedSettings` are unioned with the bus-derived ones per
event. `$HOME/.claude` is assumed; repointing `configDir` is not supported.

## How permission rules become settings entries

Each `ai.permissions.<kind>` list (`allow`, `ask`, `deny`) is appended to the
host's `managedSettings.permissions.<kind>` and deduplicated; other keys under
`permissions` (`defaultMode`, …) pass through untouched. App modules
contribute the read-only subcommands of what they install (`git` → `git
status/log/diff/show/branch`, `github-cli` → `gh pr/issue/run view|list|…`).

## MCP servers

Declare servers in `ai.mcpServers.<name>` (see `modules/ai/README.md` for the
secret-reference syntax). `modules/ai/mcp.nix` renders them into
`programs.mcp.servers`; this module's `enableMcpIntegration = true` pulls that
registry in as a synthesized personal plugin. Consequences worth knowing:

- Tools are namespaced `mcp__plugin_hm_<server>__<tool>` — write permission
  rules against that prefix, not `mcp__<server>__*`.
- Plugin-provided servers are **auto-trusted**; the per-project approval
  prompt and `enabledMcpjsonServers` / `disabledMcpjsonServers` /
  `enableAllProjectMcpServers` do not apply to them. Disabled servers are
  therefore filtered out at the bus rather than passed through.
- User-scope servers still live in the mutable `~/.claude.json`; there is no
  declarative file for that scope, which is why the plugin route is used.
  `managed-mcp.json` was rejected because it is exclusive and would block
  project `.mcp.json` servers.

## LSP servers

Enabled `ai.lspServers.<name>` entries are handed to home-manager's
`programs.claude-code.lspServers` minus the bus-only `enable` / `description`
keys, and land in the same synthesized personal plugin as the MCP registry, as
`.lsp.json`. The neovim language modules populate them (one server per enabled
language, absolute store-path `command`); see `modules/ai/README.md`.

## Plugins and context

- `ai.plugins.<name>` installs a *local or fetched* plugin directory. Plugins
  from the official marketplace are **not** installed by listing them in
  `enabledPlugins` — that key only toggles already-installed plugins, so
  marketplace installation stays runtime state (`claude plugin install …`).
  You may still enforce `enabledPlugins` through `managedSettings`.
- `~/.claude/CLAUDE.md` becomes a nix-managed (read-only) file only when
  `ai.context` is non-empty. Leave it empty to keep editing it by hand.

## Migration notes

- `applications.claude-code.skills.<n>.enable` and the per-app
  `applications.<app>.ai.skills.<n>.enable` / `applications.<app>.ai.hooks.<n>.enable`
  paths are gone. Use `ai.<kind>.<name>.enable` (e.g.
  `ai.skills.jj-gh-pr.enable = false;`).
- The jj hook file was renamed from `pre-edit-jj-warn` to
  `jj-pre-edit-warning`; home-manager swaps the symlink on switch.
- Once `my-server` and `signoz` are declared through `ai.mcpServers`, remove the
  hand-added user-scope copies so they are not loaded twice:

  ```sh
  claude mcp remove -s user my-server
  claude mcp remove -s user signoz
  ```
