<p align="center">
  <img src="background.png" alt="dotfiles" />
</p>

## Getting Started
- Have a valid nix installation (nix/nixos)
- Create a nix shell with necessary tooling for initial setup: `nix-shell -p gnumake git`.
- Clone repo
- [Set up Cachix](#cachix) (required for private cache access)
- Real machines are switched from the private dotfiles repo, which consumes this one — see
  [Private dotfiles](#private-dotfiles). This repo alone builds only the synthetic `example` host,
  a fixture that type-checks the module set (`nix run .#test example`); it is not a machine.
- From the private repo, run `nix run .#switch <host>`

## Cachix

A private [Cachix](https://cachix.org) binary cache (`grady-saccullo.cachix.org`) is used to
avoid redundant builds across machines. When you run `nix run .#switch`, Nix checks this cache
(along with the public `nix-community` and `numtide` caches) for pre-built derivations before
building from source. After a successful switch, the build output is pushed back to the cache
so other machines can pull it.

This cache is configured in `flake.nix`'s `nixConfig`, scoped to this flake — **not** in the
machine-wide `nix.settings` (`modules/shared/nix.nix`, which keeps only the public caches). As
a global substituter it leaked into every unrelated `devenv` project, whose cache probe hits
this private cache unauthenticated and emits `HTTP error 401` warnings. Flake-scoping confines
it to operations on this flake.

Because the cache is private, Nix needs credentials to fetch from it. Nix supports
this through a [netrc](https://everything.curl.dev/usingcurl/netrc) file — the same format
`curl` uses for HTTP authentication. Nix reads this file and attaches the credentials
when making requests to the cache.

### Setup

Create the netrc file with your Cachix auth token (found on the
[Cachix dashboard](https://app.cachix.org)):

```bash
sudo sh -c 'umask 022; cat > /etc/nix/netrc << EOF
machine grady-saccullo.cachix.org password <CACHIX_AUTH_TOKEN>
EOF'
sudo chmod 0644 /etc/nix/netrc
```

This tells Nix: when connecting to `grady-saccullo.cachix.org`, authenticate with the given
token. The file lives at `/etc/nix/netrc` so it works on both macOS and Linux without any
path differences.

The mode is `0644` (not `0600`) on purpose: during `nix run .#switch`, Nix queries this cache
both as root (the `nix-darwin` daemon) and as your user (flake evaluation / substituter
probing). If the file is only root-readable, the user-side queries can't authenticate and the
private cache returns `HTTP 401` warnings. A read-only token for a personal cache at `0644` on
a single-user machine is a negligible exposure — do not "harden" this back to `0600`.

## Private dotfiles

This repo is the *framework*: the application module set, the option buses, `lib.mkDarwinHost`
and the `apps/*` scripts. It ships no real host; its only `darwinConfiguration` is the synthetic
`example` fixture (`hosts/example/default.nix`). Every machine that is actually switched,
work and personal alike, is defined in a second, private flake,
[`Grady-Saccullo/.dotfiles-private`](https://github.com/Grady-Saccullo/.dotfiles-private), cloned
to `~/.dotfiles-private`. The dependency points *that* way: the private repo consumes this one as
input `dotfiles` and

- defines every real `darwinConfiguration`, each as a host module handed to
  `inputs.dotfiles.lib.mkDarwinHost` exactly like the `example` fixture here;
- re-exports the apps, so `nix run .#switch <host>` is run from the private repo;
- may ship its own application modules (built with the same `utils.mkAppModule`) and nixpkgs
  overlays for software that cannot be public, passed in through `modules` / `overlays`.

Sensitive-but-not-secret config (work MCP server definitions, internal skills and rules,
1Password/Bitwarden *references*) lives there. Secret *values* live in neither repo; they are read
at runtime through the [`secrets.*` bus](#modulessecrets).

```nix
inputs.dotfiles.url = "github:Grady-Saccullo/.dotfiles";
darwinConfigurations.work = inputs.dotfiles.lib.mkDarwinHost {
  system = "aarch64-darwin";
  user = "me";
  modules = [ ./hosts/work ./modules/applications ];
  overlays = [ (import ./overlays) ];
};
```

`mkDarwinHost` imports `darwinModules.default` (sensible + home-manager + applications) unless
called with `framework = false`, applies the given `overlays` after this repo's own, and merges
`extraSpecialArgs` into the module `specialArgs` (e.g. `{ privateInputs = inputs; }`) so private
modules get `config`, `pkgs`, `utils` and `me` exactly like the public ones.

Workflow for a framework change:

```bash
cd ~/.dotfiles && git add -A && git commit -m "..."          # 1. change the framework here
cd ~/.dotfiles-private && nix run .#switch <host> -- --local # 2. test against ~/.dotfiles
cd ~/.dotfiles && git push                                   # 3. publish
cd ~/.dotfiles-private && nix run .#update                   # 4. pick `dotfiles`
nix run .#switch <host>                                      # 5. switch normally
```

`--local` (or `DOTFILES_LOCAL=<path>`) makes `apps/switch` and `apps/test` resolve the local
checkout to a store path once, as your user, and point both the user-side build and the root-side
`darwin-rebuild` at it with `--override-input dotfiles`; `flake.lock` is left untouched. Only
tracked files are seen (`git+file:`), and root never runs git in a user-owned repo. Since this repo
is public and the private one is evaluated from its own working tree, root needs no SSH access
anywhere anymore.

## Project Structure

### `/apps`
Contains scripts available within a nix develop shell.

Run with `nix run .#<command>`.

- `switch`: build and switch configuration, outputs package changes, and pushes to cachix
- `test`: test the current configuration without switching
- `format`: format the repo with [alejandra](https://github.com/kamadorueda/alejandra)
- `update`: interactively select flake inputs to update via fzf

### `/hosts`
One directory per host, `hosts/<name>/default.nix`, mirroring the private repo's layout. This
public repo ships only `hosts/example`, a synthetic host that is not a real machine: it enables a
representative set of modules so `nix run .#test example` type-checks the whole module set, and it
shows how a host is written. Real hosts (work and personal machines) live in the private repo under the same
`hosts/<name>/` convention, with per-host `aerospace.nix` / `ai.nix` siblings imported by `default.nix`.

### `/modules/applications`
Contains all of the shared "applications" which can be turned on through `.enable`. The reasoning
for this style was so that I could easily share a given "application" between multiple machine
types (`darwin`, `nixos`, or `linux` which is just any other distro not nixos). I wasn't a fan of
how many configs spread applications to be shared across multiple files and felt this made
upkeep more painful so this was my solution. Even though this is called application it contains
anything from gui apps to cli tooling.

Application modules never write to another application's home-manager options; anything one app
wants to hand to another goes through the option buses described next, and GUI apps expose
read-only `applications.<app>.path` and `applications.<app>.bundleId` for other modules and host
configs to reference.

Neovim has its own sub-module system under `configs/` for per-language/plugin support.

**Option buses.** The five `/modules/{ai,browser,identity,secrets,shell}` directories below are
not applications but cross-cutting nix-darwin option sets, each a small module (`options.nix`,
`default.nix`, `README.md`) that declares tool-agnostic options and nothing else. The rule is
write-many/read-one: any number of modules may *set* a bus's options, but exactly one kind of
consumer *reads* it and only that consumer writes to home-manager for that concern (claude-code
for `ai.*`, brave for `browser.*`, the VCS tools for `identity.*`, secret-wrapping launchers for
`secrets.*`, zsh for `shell.*`). The graph stays acyclic and a second consumer can be added
without touching any contributor. All five are imported once from
`modules/applications/default.nix`, so they exist whenever application modules do. Named bus
entries default to `enable = true` and hosts opt out per entry (`ai.skills.jj-gh-pr.enable =
false;`); plain-string entries are overridden with `lib.mkForce`.

### `/modules/ai`
The tool-agnostic `ai.*` option bus for AI tooling:
`ai.{skills,agents,commands,rules,hooks,plugins,context,mcpServers,lspServers}` — skills, agents,
commands, rules, hooks, plugins, user-level `CLAUDE.md` context, MCP servers, and LSP servers.

Writers (they only set `ai.*` options):
- application modules that own an AI contribution: `jj` registers its `jj-gh-pr` skill and
  `jj-pre-edit-warning` hook; each neovim language module registers an `ai.lspServers` entry
  through `mkNeovimModule`'s `extraConfig`, reusing the language server neovim already installs
- shared content under `modules/ai/{skills,agents,commands,rules}/`, auto-registered by
  `content.nix`
- host modules (in the private repo, or the `example` fixture here) — per-host overrides and,
  on the private side, sensitive content (work MCP servers, internal skills, vault references);
  see [Private dotfiles](#private-dotfiles)

Consumers (the only modules that write to home-manager's AI options):
- the `claude-code` application module — materializes the bus into `~/.claude/` and
  `managed-settings.json`
- other tools (codex, opencode, …) later, reading the same bus

Secret env values on MCP servers are written as `{ secret = "op://…"; }` references and resolved
at runtime through the [`secrets`](#modulessecrets) bus when the server is spawned; no value ever
enters Nix. Full option reference and how-tos in [`modules/ai/README.md`](modules/ai/README.md).

### `/modules/browser`
The `browser.*` extension bus. An application that ships a browser extension declares it once as
`browser.extensions.chromium.<name> = { enable, id, description }` (writers today: `1password`,
`bitwarden`, `raycast`); the `brave` module reads the bus and installs every enabled entry, and a
future Chromium-based browser would consume it unchanged. It replaces the `common.browserExtensions`
set that lived in the now-deleted `modules/flake-parts/common.nix`. Safari has no equivalent yet
(its extensions are App Store apps). Details in [`modules/browser/README.md`](modules/browser/README.md).

### `/modules/identity`
The `identity.*` bus: `identity.name` and `identity.email`, declared once per host and read by
every tool that attributes work to the user — `git` and `jj` today, `gh` and AI context later.
The defaults are the personal name and address, which both hosts currently use; the work host can
override `identity.email` in one line and every consumer follows. Details in
[`modules/identity/README.md`](modules/identity/README.md).

### `/modules/secrets`
The `secrets.*` bus: `secrets.backend` (`op`, `rbw`, or `bw`) and the derived `secrets.readCommand`,
which any module that needs a token at launch reads instead of hard-coding a CLI. The rule it
enforces: this repo is public, the Nix store is world-readable and `apps/switch` pushes the whole
closure to Cachix, so secret *values* are only ever read at runtime and Nix holds references
(`op://…`) alone. Consumers wrap their program with `utils.secrets.mkEnvWrapper`, which resolves
the references and `exec`s the real binary. the work host uses `op` (the 1Password desktop app CLI);
`personal` is undecided between `rbw` and `bw`. Details in [`modules/secrets/README.md`](modules/secrets/README.md).

### `/modules/shell`
The `shell.*` bus: `shell.aliases.<name>` and `shell.init.<name>` (functions, completions,
environment), set by app modules (`git`, `jj`) and read by whichever shell modules are enabled —
`zsh` today, where bus aliases win over zsh's own on a name clash and init snippets are appended
in attribute-name order; a future `fish` module would consume the same two options. There is no
per-entry `enable`; hosts drop a snippet with `lib.mkForce ""`. Details in
[`modules/shell/README.md`](modules/shell/README.md).

### `/modules/darwin`
Contains shared darwin configurations to be pulled into host modules through the `darwinModules`
set in the root flake.nix. Currently only contains `sensible`.

### `/modules/shared`
Contains shared configurations across all platforms. Currently holds shared nix settings.

### `/modules/flake-parts`
Contains shared options/imports for the root flake.nix to be used with flake-parts (`flake.nix`,
`apps.nix`, `devshells.nix`). `flake.nix` declares the extra flake outputs — `homeManagerModules`,
`darwinModules`, `constants`, `applications` and `lib` (functions for downstream flakes); the
root `flake.nix` fills `lib.mkDarwinHost` for the [private repo](#private-dotfiles). `utils.nix`
is not really flake-parts specific and probably needs to be refactored out; it holds the module helpers: `mkAppModule`, `mkNeovimModule` (whose
`extraConfig` parameter lets language modules contribute darwin-level options such as
`ai.lspServers`), the bus helpers `enabled` / `content`, and `secrets.mkEnvWrapper`.

### `/modules/home-manager`
Contains shared per platform home-manager configurations to be pulled into host modules
through the `homeManagerModules` set in the root flake.nix. Currently only contains `darwin`.

### `/overlays`
Overlays applied to the base package set. `pkgs` is nixpkgs-unstable (darwin needs the moving
channel) plus the framework overlays: `wezterm-nightly` (the wezterm flake) and the `llm-agents`
package set from numtide/llm-agents.nix. Modules reference packages as plain `pkgs.<attr>`.

`pkgs.channels.v<major>_<minor>` (`overlays/channels.nix`) exposes one full nixpkgs per flake input
named `nixpkgs-<major>_<minor>`, for pinning a single package to a release while everything
else follows unstable, e.g. `pkgs.channels.v26_05.go`. To add a channel, add the input; it
shows up under its release name:

```nix
nixpkgs-25_11.url = "github:NixOS/nixpkgs/nixos-25.11";   # -> pkgs.channels.v25_11
```

Rule of thumb: prefer a versioned attribute in base `pkgs` (`go_1_23`), fall back to a channel
pin only when none exists, and keep language toolchains in project devenv files rather than in
the system. Channel sets are lazy (imported only when referenced) and do not carry the
framework overlays, so `pkgs.channels.v26_05.wezterm-nightly` does not exist.

---
##### Notes

A lot of initial inspiration for my config came
from [dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config/tree/main)
and [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config/tree/main).
Highly recommend looking into these repos if you are just getting into nix.
