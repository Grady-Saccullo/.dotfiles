# Hosts

A host is one machine: a nix-darwin module that says which apps it runs and how they are set up.
`lib.mkDarwinHost` combines it with the framework's modules to build the whole system.

`example/` is a complete, made-up Mac in two files:

| File | What it is |
| --- | --- |
| [`example/flake.nix`](example/flake.nix) | A full flake that uses the framework the way your own would. It takes this repo as the input `dotfiles`, pins the framework's inputs in its own lock, adds extra package sources and builds the machine with `lib.mkDarwinHost`. |
| [`example/default.nix`](example/default.nix) | The machine itself: host name, your name and email, which apps are on, window manager layout, AI tool setup and Dock apps. |

`default.nix` is a separate file because this repo's own flake also builds it, as the test that
every module still builds (`nix run .#test example`). That test build gets no extra package
sources, so the package choices that need them live in `flake.nix`.

## Starting your own

You need Nix with flakes enabled.

```bash
mkdir ~/my-macs && cd ~/my-macs
curl -LO https://raw.githubusercontent.com/Grady-Saccullo/.dotfiles/main/hosts/example/flake.nix
curl -LO https://raw.githubusercontent.com/Grady-Saccullo/.dotfiles/main/hosts/example/default.nix
```

From a clone of this repo, `cp ~/.dotfiles/hosts/example/{flake.nix,default.nix} .` does the same.

1. In `flake.nix`, set `user` to your macOS user name and rename `example` to your machine's name.
2. In `default.nix`, set `networking`, `identity` and `secrets.backend`, then turn apps on or off.
   Replace the made-up MCP servers and rules under `ai`, or delete them.
3. Flakes only see files that git tracks: `git init && git add -A`.
4. Build and switch: `nix run .#switch <name>`. The first run creates `flake.lock`; commit it.

For more than one machine, move each machine's module to `hosts/<name>/default.nix` and add a
`darwinConfigurations.<name>` entry for it in `flake.nix` with `modules = [./hosts/<name>];`.

## How the flake is put together

- **`dotfiles.inputs.*.follows`**: the framework's own inputs (nixpkgs, home-manager, nix-darwin,
  Homebrew and flake-parts) are pinned by your `flake.lock`, so `nix run .#update` in your flake
  updates everything. If the framework adds an input, add it here too; until you do, it stays at
  the version in the framework's lock.
- **Extra package sources** (`llm-agents`, `nixpkgs-26_05`) are your inputs. `overlays` adds their
  packages to `pkgs` and `channels` makes a release available as `pkgs.channels.<name>`. The inline
  module in `modules` then points apps at them through their `package` option.
- **`inherit (inputs.dotfiles) apps devShells;`** gives your flake the framework's scripts:
  `nix run .#switch <host>`, `.#test <host>`, `.#update` and `.#format`, plus `nix develop`.
- **`nixConfig`** is commented out. Nix only reads it from the flake you run, so a binary cache
  you want to use has to be set in your flake, not the framework's.

## Good to know

- Some apps are on by default: bat, btop, direnv, eza, fzf, git, jj, jq, ripgrep, starship, tmux,
  yazi, zoxide and zsh. Turn one off with `applications.<name>.enable = false;`.
- `identity` defaults to the framework author's name and email, so set it on every machine.
- GUI apps have `applications.<name>.path` and `applications.<name>.bundleId`, which are set even
  when the app is off. Use them for Dock items and window rules instead of typing paths and ids.
- Secret values never go in these files. Write a reference such as
  `env.API_TOKEN.secret = "op://Vault/item/field";` and set `secrets.backend`; the value is read
  from your password manager when the program starts.
- Keep anything that should not be public in your own flake, not in this repo.
- The options are documented next to the modules: [ai](../modules/ai/README.md),
  [secrets](../modules/secrets/README.md), [identity](../modules/identity/README.md),
  [shell](../modules/shell/README.md), [browser](../modules/browser/README.md) and the app modules
  under [`modules/applications/`](../modules/applications/).
