{
  pkgs,
  inputs,
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
    betterdisplay.enable = true;
    bettersnaptool.enable = true;
    bitwarden = {
      enable = true;
      browserExtension.enable = true;
    };
    discord.enable = true;
    brave.enable = true;
    github-cli.enable = true;
    podman.enable = true;
    neovim = {
      enable = true;
      dap = {
        enable = true;
        go.enable = true;
      };
      go = {
        enable = true;
        templ.enable = true;
      };
      docker.enable = true;
      html = {
        enable = true;
        htmx.enable = true;
      };
      ocaml.enable = true;
      rust.enable = true;
      zig.enable = true;
    };
    raycast.enable = true;
    spotify.enable = true;
    todoist.enable = true;
    soundsource.enable = true;
    wezterm.enable = true;
  };

  system.defaults.dock.persistent-apps = [
    "${pkgs.wezterm-nightly.packages.${pkgs.system}.default}/Applications/WezTerm.app"
    "${pkgs.unstable.spotify}/Applications/Spotify.app"
    "${pkgs.unstable.brave}/Applications/Brave\ Browser.app"
    "/System/Applications/Messages.app"
  ];
}
