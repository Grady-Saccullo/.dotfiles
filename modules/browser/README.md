# `browser` — browser-agnostic extension bus

One bus, many browsers. An app that ships a browser extension declares it
once under `browser.extensions.*`; every browser module that understands
that extension format installs it. Adding a second Chromium-based browser
requires no change to contributors.

## The dependency rule

```
app modules (1password, bitwarden, raycast, …) ─┐
hosts/<host>/*.nix            ─┴─ SET ──▶ browser.extensions.*
                                                                │ READ
                                                                └──▶ applications.brave ──▶ HM programs.brave.extensions
                                                                └──▶ applications.<chromium browser> later
```

* Only browser modules read `browser.extensions.*` and write the
  corresponding home-manager `programs.<browser>.extensions`.
* Everyone else writes `browser.extensions.*`. The bus never depends on a
  browser module, so the graph is acyclic.

## Options

| Option | Shape | Materialises as |
| --- | --- | --- |
| `browser.extensions.chromium.<name>` | `{ enable, id, description }` | `{ id = …; }` in each Chromium browser's extension list |

* `enable` — defaults to `true`; set `false` on a host to drop the entry.
* `id` — Chrome Web Store extension id (required).
* `description` — one-line summary, informational only.

Entries are `attrsOf submodule`, so one module can declare `id` and another
(a host config) can set only `enable = false` on the same name; the module
system merges them by attribute name.

## Contributing from an app module

Inside the module's existing enable-gated config block:

```nix
(lib.mkIf cfg.browserExtension.enable {
  browser.extensions.chromium.bitwarden = {
    id = "nngceckbapebfimnlniiiahkandclblb";
    description = "Bitwarden";
  };
})
```

Name the entry after the owning app so the option tree reads naturally.

## Host opt-out

```nix
{...}: {
  browser.extensions.chromium.raycast.enable = false;
}
```

## Consuming from a browser module

```nix
extensions =
  [
    {id = "…";} # browser-specific extras
  ]
  ++ lib.mapAttrsToList (_: e: {inherit (e) id;})
  (utils.enabled config.browser.extensions.chromium);
```

## Open questions

* **Safari.** Safari extensions are distributed as Mac App Store apps and
  cannot be installed from a browser config, so there is no
  `browser.extensions.safari` yet. The previous `common.browserExtensions.safari`
  placeholder was never used and has been removed; revisit if a
  `homebrew.masApps`-based shape turns out to be useful.
