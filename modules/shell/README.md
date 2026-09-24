# `shell` — shell-agnostic alias and init bus

One bus, many shells. An app that wants an alias or an init snippet
(functions, completions, environment) declares it once under `shell.*`;
every enabled shell module (zsh today) materialises it. Adding fish later
requires no change to contributors.

## The dependency rule

```
app modules (git, jj, …)             ─┐
hosts/<host>/*.nix  ─┴─ SET ──▶ shell.aliases / shell.init
                                                     │ READ
                                                     ├──▶ applications.zsh  ──▶ HM programs.zsh.{shellAliases,initContent}
                                                     └──▶ applications.fish later
```

* Only shell modules read `shell.*` and write the corresponding
  home-manager `programs.<shell>.*`.
* Everyone else writes `shell.*`. The bus never depends on a shell module,
  so the graph is acyclic, and app modules no longer gate on
  `applications.zsh.enable`: if no shell module is enabled the bus is
  simply never read.

## Options

| Option | Type | Materialises as |
| --- | --- | --- |
| `shell.aliases.<name>` | `str` | `alias <name>=…` in every enabled shell |
| `shell.init.<name>` | `lines` | appended to every enabled shell's init, in attribute-name order |

Both default to `{}`. Alias bodies and snippets must be sh/zsh-compatible.

There is deliberately no per-entry `enable`: an alias is a plain string, and a
`{ enable, value }` submodule would be heavier than the thing it wraps. Opting
out uses the module system directly:

```nix
shell.init.git = lib.mkForce "";                        # drop a snippet on this host
shell.aliases.gst = lib.mkForce "git status --short";   # override an alias
```

Snippets and aliases can depend on each other: the `git` snippet defines shell
functions (e.g. `git_main_branch`) that several `g*` aliases call, so forcing
`shell.init.git = ""` leaves those aliases broken unless you override them too.
Prefer disabling the contributing app, or overriding the specific aliases.

A plain-string entry can be overridden but not removed, so a contributor that
expects hosts to want an alias gone should gate it itself (behind its app's
`enable`, which `utils.mkAppModule` already does, or a dedicated option).

`shell.init` snippets are concatenated with `lib.attrValues`, which is
attribute-name-sorted, so the generated file is deterministic. A snippet that
must run before another can be named accordingly (`00-…`).

## Contributing from an app module

Inside `mkAppModule`'s enable-gated config, merged next to the
`utils.mkHomeManagerUser { … }` block:

```nix
(utils.mkHomeManagerUser {
  programs.jujutsu = { … };
})
// {
  shell.aliases.j = "jj";
  shell.init.jj = ''
    function jjm() { jj bookmark move "$@"; }
  '';
}
```

Name `shell.init` entries after the owning app (`git`, `jj`) so the option
tree and the generated file line up.

## Consuming from a shell module

```nix
programs.zsh = {
  # local zsh aliases first; bus entries win on a name clash
  shellAliases = {l = "ls -la";} // config.shell.aliases;
  initContent =
    ''…zsh-only setup…''
    + "\n"
    + lib.concatStringsSep "\n" (lib.attrValues config.shell.init);
};
```

A future fish module would read the same two options and translate each
snippet (or skip the zsh-flavoured ones); today's contributors are written
for zsh.
