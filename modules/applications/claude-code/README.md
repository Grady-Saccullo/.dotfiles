# claude-code module

Installs Claude Code and acts as the sink for every module that contributes
skills, hooks, commands, or agents. Itself owns only tool-agnostic skills.

## Architecture in one paragraph

Home-manager's `programs.claude-code` is the single place that materializes
files under `~/.claude/`. This module enables it and seeds its own
tool-agnostic skills. App modules (e.g. `jj`) contribute their own skills and
hooks by writing directly to `programs.claude-code.*` — no registry in this
module. Separation of concerns: each app owns its Claude Code contributions
end-to-end; this module only owns tool-agnostic ones.

## Namespaces

| User-facing option                                  | Owned by              | Provisions to                                |
| --------------------------------------------------- | --------------------- | -------------------------------------------- |
| `applications.claude-code.enable`                   | this module           | home-manager's `programs.claude-code.enable` |
| `applications.claude-code.skills.<name>.enable`     | this module           | `~/.claude/skills/<name>/`                   |
| `applications.<app>.ai.skills.<name>.enable`        | the `<app>` module    | `~/.claude/skills/<name>/`                   |
| `applications.<app>.ai.hooks.<name>.enable`         | the `<app>` module    | `~/.claude/hooks/<name>` + `settings.json`   |

By convention, skill directory names and option keys include the owning
app's prefix (e.g. `jj-gh-pr`) so the filesystem and config line up.

## Adding a new skill

### 1. Tool-agnostic (owned by claude-code)

Place the skill at `modules/applications/claude-code/skills/<name>/SKILL.md`
and add one entry to `ownedSkills` in this module:

```nix
ownedSkills = {
  my-skill = {
    source = ./skills/my-skill;
    description = "what it does";
  };
};
```

The option `applications.claude-code.skills.my-skill.enable` (default true)
is generated automatically. Rebuild to materialize.

### 2. App-specific (owned by another module)

Place the skill under that module's own `skills/` dir, e.g.
`modules/applications/jj/skills/jj-something/SKILL.md`, and add an entry to
that module's `ownedSkills`. See `modules/applications/jj/default.nix` for a
worked example. The user-facing toggle is
`applications.jj.ai.skills.jj-something.enable`.

## Adding a hook

Hooks run at specific Claude Code lifecycle points (PreToolUse, PostToolUse,
etc.). There's no shared abstraction yet — the `jj` module wires one hook
directly (see `preEditHookScript` + `programs.claude-code.settings.hooks`
block). If a second module adds a hook, factor out a pattern matching
`ownedSkills`.

To add a jj-style hook today:

1. Write the script string in the app module's `let` block.
2. Register a toggle under `extraOptions.ai.hooks.<name>.enable`.
3. Contribute to `programs.claude-code.hooks.<file-name>` (creates the
   script file) AND to `programs.claude-code.settings.hooks.<EventName>`
   (wires it to the trigger) — both gated on the toggle.

## Profile-specific overrides

Any of the above toggles can be set per-profile in `voze-darwin.nix` or
`personal-darwin.nix`:

```nix
applications.jj.ai.skills.jj-gh-pr.enable = false;    # disable on this host
applications.jj.ai.hooks.pre-edit-warning.enable = false;
programs.claude-code.settings.model = "haiku-4-5";    # diverge from default
```

## Settings migration (one-time)

This module sets `programs.claude-code.settings` to mirror the previously
hand-maintained `~/.claude/settings.json`. Home-manager writes the generated
file on `darwin-rebuild switch`; it will rename any pre-existing file to
`.backup` (see `home-manager.backupFileExtension` in
`modules/home-manager/darwin.nix`). After a successful first rebuild, verify
and remove the `.backup`.
