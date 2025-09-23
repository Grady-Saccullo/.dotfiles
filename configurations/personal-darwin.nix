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
    ai = {
      enable = true;
      claude-code.enable = true;
    };
    betterdisplay.enable = true;
    bettersnaptool.enable = true;
    bitwarden = {
      enable = true;
      browserExtension.enable = true;
    };
    brave.enable = true;
    discord.enable = true;
    docker.enable = true;
    github-cli.enable = true;
    hoppscotch.enable = true;
    neovim = {
      enable = true;
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
    spotify.enable = true;
    utm.enable = true;
    wezterm.enable = true;
  };

  system.defaults.dock.persistent-apps = [
    "${config.applications.wezterm.package}/Applications/WezTerm.app"
    "${config.applications.brave.package}/Applications/Brave\ Browser.app"
    config.applications.spotify.path
    "/System/Applications/Messages.app"
  ];
}
