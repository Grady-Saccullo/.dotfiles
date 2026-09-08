{
  inputs,
  config,
  ...
}: let
  inherit (inputs) self;
in {
  imports = [
    self.darwinModules.sensible
    self.homeManagerModules.darwinModule
    self.applications
  ];

  applications = {
    aerospace = {
      enable = true;
      settings = import ./personal-configs/aerospace.nix;
    };
    claude-code.enable = true;
    android-studio.enable = true;
    betterdisplay.enable = true;
    bettersnaptool.enable = false;
    bitwarden = {
      enable = true;
      browserExtension.enable = true;
    };
    brave.enable = true;
    devenv.enable = true;
    discord.enable = true;
    docker.enable = true;
    github-cli.enable = true;
    halloy.enable = true;
    hoppscotch.enable = true;
    neovim = {
      enable = true;
      elixir.enable = true;
      dap = {
        enable = true;
        go.enable = true;
      };
      db = {
        enable = true;
        sql.enable = true;
      };
      go = {
        enable = true;
        templ.enable = true;
      };
      docker.enable = true;
      python.enable = true;
      protobuf.enable = true;
      html = {
        enable = true;
        htmx.enable = true;
      };
      terraform.enable = true;
      typescript = {
        enable = true;
        lsp = "vtsls";
        tsx.enable = true;
        biome.enable = true;
      };
      ocaml.enable = true;
      rust.enable = true;
      zig.enable = true;
    };
    podman.enable = true;
    raycast.enable = true;
    soundsource.enable = true;
    fzf.searchPaths = [
      "$HOME/Desktop/"
      "$HOME/Documents/"
      "$HOME/Downloads/"
      "$HOME/code/"
      "$HOME/personal/"
    ];
    spotify.enable = true;
    steam.enable = true;
    tailscale.enable = true;
    utm.enable = true;
    wezterm = {
      enable = true;
      wezsesh.enable = false;
    };
    xcode.enable = true;
  };

  # Linux VM builder so `nix run .#deploy hackerpi` can build aarch64-linux
  # closures locally before pushing them to the Pi (building on the Pi
  # itself is slow and memory-starved). First switch downloads the VM image.
  nix.linux-builder = {
    enable = true;
    ephemeral = true;
    maxJobs = 4;
    config = {
      virtualisation = {
        cores = 6;
        darwin-builder = {
          diskSize = 40 * 1024;
          memorySize = 8 * 1024;
        };
      };
    };
  };

  system.defaults.dock.persistent-apps = [
    config.applications.wezterm.path
    config.applications.brave.path
    config.applications.spotify.path
  ];
}
