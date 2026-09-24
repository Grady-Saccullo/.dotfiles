# `identity` — who the user is

One name/email pair, declared once under `identity.*`, read by every tool that
attributes work to the user. Hosts set it; tool modules read it. Nothing in
`modules/identity` depends on any application module.

## The dependency rule

```
hosts/<host>/default.nix ── SET ──▶ identity.name / identity.email
                                                │ READ
                                                ├──▶ applications.git ──▶ HM programs.git.settings.user
                                                ├──▶ applications.jj  ──▶ HM programs.jujutsu.settings.user
                                                └──▶ gh / AI user-level context later
```

* Only tool modules read `identity.*` and write the corresponding
  home-manager `programs.<tool>.*.user` settings.
* Host configs (and nothing else) write `identity.*`. A second consumer
  (gh, an `ai.context` line) needs no change to hosts.

## Options

| Option | Type | Default | Consumers |
| --- | --- | --- | --- |
| `identity.name` | `str` | `"Grady Saccullo"` | git, jj |
| `identity.email` | `str` | `"gradys.dev@gmail.com"` | git, jj |

The defaults are the values the git module's former per-app `username` /
`email` options carried (no host ever set those), so behaviour is unchanged:
today both hosts use the personal address.

## Host override

```nix
# hosts/<host>/default.nix
{...}: {
  identity.email = "grady@work.example";
}
```

The work host can set its address this way and every consumer follows; the
personal host keeps the defaults.

## Consuming from a tool module

```nix
programs.jujutsu.settings.user = {
  name = config.identity.name;
  email = config.identity.email;
};
```

Do not re-declare a per-app `username` / `email` option; read the bus.
