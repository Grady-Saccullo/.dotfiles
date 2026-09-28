<p align="center">
  <img src="background.png" alt="dotfiles" />
</p>

# dotfiles

Nix configuration for my Macs, packaged as a reusable framework. It uses
[nix-darwin](https://github.com/LnL7/nix-darwin) and
[home-manager](https://github.com/nix-community/home-manager) to install apps and CLI tools, write
their config files and set macOS system preferences, so a machine can be rebuilt from scratch with
one command.

This repo is the shared, public part. It does not define any real machine. Real machines live in a
separate flake that imports this one, turns on the apps it wants and adds anything that should not
be public. The only machine defined here is `example`, a test host used to check that everything
still builds.

## What it provides

- **App modules** (`modules/applications/`). One module per app or tool: terminal, editor, shell,
  git, browsers, password managers, AI coding tools and more. A host turns one on with a single
  line such as `applications.wezterm.enable = true;`. The module installs the app (from nixpkgs, a
  Homebrew cask or the Mac App Store) and sets up its config.
- **macOS defaults** (`modules/darwin/sensible.nix`). Nix settings (flakes, weekly garbage
  collection), Homebrew managed through nix-homebrew with pinned taps, Touch ID for `sudo`, zsh as
  the login shell, and preferences for the Dock, Finder, trackpad and keyboard.
- **Shared settings between apps** (`modules/{ai,browser,identity,secrets,shell}/`). Values that
  several apps need are set once and picked up by the app that uses them: your name and email
  (git, jj), shell aliases (zsh), browser extensions (Brave), AI tool setup (Claude Code) and how
  secrets are fetched at runtime. See [Shared settings](#shared-settings).
- **`lib.mkDarwinHost`**, the function your own flake calls to build a Mac from all of the above.
- **Scripts** to build, test and update a machine: `nix run .#switch`, `test`, `update` and
  `format`. The switch also runs the [steps](#switch-steps) a host declares, before the build or
  after switching.

It targets macOS on Apple Silicon. The modules have Linux and NixOS branches, but there is no host
builder for those yet.

## Quick start

To work on the framework itself:

```bash
git clone https://github.com/Grady-Saccullo/.dotfiles ~/.dotfiles
cd ~/.dotfiles
nix run .#test example     # build the test host and run a darwin-rebuild check
nix run .#format           # format the Nix files with alejandra
```

To set up a real machine, create your own flake that uses this one (next section), then run
`nix run .#switch <host>` from that flake. You need Nix with flakes enabled.

## Setting up your own machines

Your flake takes this repo as the input `dotfiles`, defines each machine with `lib.mkDarwinHost`
and re-exports the scripts, so `nix run .#switch <host>` works from there:

```nix
{
  inputs = {
    dotfiles.url = "github:Grady-Saccullo/.dotfiles";

    # Pin the framework's inputs in your own lock: one `follows` line for every input in the
    # framework's flake.nix (also darwin, nix-homebrew, homebrew-core, homebrew-cask and
    # flake-parts), each declared below with the same URL.
    dotfiles.inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
    dotfiles.inputs.home-manager.follows = "home-manager";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # Extra package sources are your own inputs, not the framework's.
    llm-agents.url = "github:numtide/llm-agents.nix";
    nixpkgs-26_05.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = inputs: {
    apps = inputs.dotfiles.apps;
    darwinConfigurations.work = inputs.dotfiles.lib.mkDarwinHost {
      system = "aarch64-darwin";
      user = "me";
      modules = [./hosts/work];
      overlays = [inputs.llm-agents.overlays.shared-nixpkgs];
      channels.v26_05 = inputs.nixpkgs-26_05;
    };
  };
}
```

A host module is a normal nix-darwin module that turns apps on and sets options. For a complete
flake with every framework input and a realistic machine to start from, see
[`hosts/example`](hosts/README.md).

`mkDarwinHost` arguments:

| Argument | What it does |
| --- | --- |
| `system`, `user` | Platform and the main user account (`me.user` inside modules). |
| `modules` | Your host modules, loaded together with the framework's. |
| `overlays` | Extra nixpkgs overlays, applied after the framework's. Use this to add packages to `pkgs`. |
| `channels` | Other nixpkgs releases, available as `pkgs.channels.<name>`. See [Choosing an app's version](#choosing-an-apps-version). |
| `extraSpecialArgs` | Extra module arguments. They override the defaults (`inputs`, `me`, `machineType`, `utils`). |
| `framework` | Set to `false` to skip the framework's modules and use only your own. |

`inputs` inside modules is the framework's inputs, not yours. If your modules need your flake's
inputs, pass them through `extraSpecialArgs` under a different name.

Keep anything that should not be public (internal tools, MCP servers, password manager references)
in your own flake. Secret values do not go in any repo; see [Secrets](#secrets).

### Updating versions

With the `follows` lines above, your flake's `flake.lock` decides which nixpkgs, home-manager and
nix-darwin you get. To update, run `nix run .#update` in your flake and pick what to bump. Nothing
changes in this repo. This repo's own `flake.lock` is only used by the `example` test host.

If the framework adds an input that your flake does not follow, everything still works, but that
input stays at the version in the framework's lock and only moves when you bump `dotfiles`.

### Choosing an app's version

By default every app comes from nixpkgs-unstable. Each module that installs a Nix package has a
`package` option, so a host can use a different build without changing the module:

```nix
{pkgs, ...}: {
  # From an older, stable nixpkgs release passed in as `channels.v26_05`.
  applications.github-cli.package = pkgs.channels.v26_05.gh;
  # From a third-party package set added through `overlays`.
  applications.claude-code.package = pkgs.llm-agents.claude-code;
}
```

That is why the framework has no inputs for nightly builds or version pins: they are your flake's
choice and never need a change here.

When pinning, prefer a versioned package in nixpkgs-unstable (for example `go_1_23`) and only use a
release channel when none exists. Channels are only loaded when something uses them, and they do
not include your overlays. Keep language toolchains in each project's devenv or flake rather than
in the system.

### Changing the framework

```bash
cd ~/.dotfiles && git add -A && git commit -m "..."    # 1. change the framework
cd <your flake> && nix run .#switch <host> -- --local  # 2. test it against ~/.dotfiles
cd ~/.dotfiles && git push                             # 3. publish
cd <your flake> && nix run .#update                    # 4. pick `dotfiles`
nix run .#switch <host>                                # 5. switch as usual
```

`--local` (or `DOTFILES_LOCAL=<path>`) builds against your local checkout instead of the pushed
version, without touching `flake.lock`. Only files tracked by git are used, and the checkout is
copied into the Nix store first, so the part of the switch that runs as root never runs git inside
your home directory. The switch script itself then also comes from that copy, so it always matches
the modules it builds. The switch in your `flake.lock` does that hand-over, so a lock from before it
existed still runs its own older switch with `--local` until you update the `dotfiles` input.

## Shared settings

Some settings are needed by more than one app. Instead of apps writing into each other's config,
each of these option sets can be filled in by any module that has something to add, and is read by
the one module that turns it into real config files. Hosts can turn off a single entry
(`ai.skills.jj-gh-pr.enable = false;`) or replace one with `lib.mkForce`.

| Options | Filled in by | Read by | Holds |
| --- | --- | --- | --- |
| `ai.*` | app modules, files in `modules/ai/`, hosts | claude-code (MCP servers via `modules/ai/mcp.nix`) | skills, agents, commands, rules, hooks, plugins, `CLAUDE.md` context, MCP and LSP servers |
| `browser.*` | 1password, bitwarden, raycast | brave | browser extensions to install |
| `identity.*` | hosts | git, jj | your name and email (the defaults are the author's, so set these) |
| `secrets.*` | hosts | apps that need a token at startup, switch steps | the hook that reads secret values (any password manager, or none) |
| `shell.*` | git, jj | zsh | shell aliases and startup snippets |

Each one has a README with the full option list: [ai](modules/ai/README.md),
[browser](modules/browser/README.md), [identity](modules/identity/README.md),
[secrets](modules/secrets/README.md) and [shell](modules/shell/README.md).

### Secrets

This repo is public, everything in the Nix store is readable by every user on the machine, and a
switch step may upload the built system to a binary cache. So secret values never go into Nix.
Config holds a reference instead (for example `{ secret = "op://Vault/item/field"; }`), and the
host's **secrets hook** turns references into values when they are needed: a small program you
choose, which gets the references on stdin and prints the values on stdout. It can use any password
manager or none. There are presets for 1Password (`op`) and Bitwarden (`rbw`, `bw`), any command
that prints one secret works, and you can write your own, for example to unlock a vault once for
several reads. [modules/secrets/README.md](modules/secrets/README.md) has the contract and an
example that reads the macOS Keychain.

## Switch steps

`nix run .#switch <host>` can run programs the host declares, before the build (`preBuild`) or
after switching (`postSwitch`): logging in to a private binary cache and uploading the new system
to it, or a notification when the switch is done, for example. The framework ships no steps; they
are packages in your own flake:

```nix
switch.steps.upload = {
  phase = "postSwitch";
  package = pkgs.callPackage ./upload-system.nix {};
  settings.store = "s3://my-cache?region=eu-west-1";
  # References that the host's secrets hook turns into values at switch time.
  secrets = {
    keyId = "my-cache-access-key-id";
    secretKey = "my-cache-secret-access-key";
  };
};
```

Each step gets its settings, its secrets and the new system's store path as JSON on stdin. The
switch reads the secrets of every step with one call to the host's secrets hook before the build,
and a failing step only prints a warning. [modules/switch/README.md](modules/switch/README.md) has
the options, the input format and a complete example.

## Repository layout

| Path | Contents |
| --- | --- |
| `flake.nix` | Inputs, `lib.mkDarwinHost` and the `example` test host. |
| `apps/` | The `switch`, `test`, `update` and `format` scripts, run with `nix run .#<name>`. |
| `hosts/example/` | A complete example: `flake.nix` uses the framework the way your own flake would, and `default.nix` is the machine. This repo also builds `default.nix` as its test (`nix run .#test example`). See [hosts/README.md](hosts/README.md). |
| `modules/applications/` | One directory per app. See [App modules](#app-modules). |
| `modules/{ai,browser,identity,secrets,shell}/` | The [shared settings](#shared-settings). |
| `modules/switch/` | The `switch.*` options: the steps `nix run .#switch` runs (see [Switch steps](#switch-steps)). |
| `modules/darwin/sensible.nix` | macOS defaults and the Homebrew setup. |
| `modules/home-manager/darwin.nix` | home-manager setup for macOS. |
| `modules/shared/nix.nix` | Nix settings every machine gets. |
| `modules/flake-parts/` | Extra flake outputs, the dev shell, the script wiring, and `utils.nix` (helpers the modules use). |
| `overlays/` | Changes to the package set, currently `pkgs.channels`. |
| `templates/` | Project templates (a Zig flake). |
| `tests/` | Tests for `nix run .#switch` and the secrets hook plumbing, run with `/bin/bash -e tests/switch.sh` and `/bin/bash -e tests/secrets.sh`. |

### App modules

Each app lives in `modules/applications/<name>/default.nix` and is built with `utils.mkAppModule`,
which adds the `applications.<name>.enable` option and only applies the module's config when it
is on. `utils.mkPlatformConfig` lets one module hold separate macOS, Linux and NixOS config.

Conventions:

- Install the module's `package` option (declared with `lib.mkPackageOption`), never a hard-coded
  `pkgs.<name>`, so hosts can swap the build. Apps installed only as a Homebrew cask or from the
  Mac App Store have no `package` option.
- Never write to another app's config. Share values through the
  [shared settings](#shared-settings) instead.
- GUI apps expose read-only `applications.<name>.path` and `applications.<name>.bundleId`, so other
  modules and hosts can refer to them, for example in window manager rules.
- Neovim has its own sub-modules under `neovim/configs/`, one per language or plugin.

## Credits

A lot of the initial inspiration came from
[dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config/tree/main) and
[mitchellh/nixos-config](https://github.com/mitchellh/nixos-config/tree/main). Both are worth a
look if you are just getting into Nix.
