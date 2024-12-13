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
    _1password.enable = true;
    android-studio.enable = true;
    betterdisplay.enable = true;
    bettersnaptool.enable = true;
    bitwarden = {
      enable = true;
      browserExtension.enable = true;
    };
    brave.enable = true;
    github-cli.enable = true;
    neovim = {
      enable = true;
      angular.enable = true;
      typescript.enable = true;
      html = {
        enable = true;
        htmx.enable = true;
      };
    };
    raycast.enable = true;
    slack.enable = true;
    soundsource.enable = true;
    spotify.enable = true;
    todoist.enable = true;
    wezterm.enable = true;
    xcode.enable = true;
    zoom.enable = true;
  };

  system.defaults.dock.persistent-apps = [
    "${pkgs.wezterm-nightly.packages.${pkgs.system}.default}/Applications/WezTerm.app"
    "/Applications/Android\ Studio.app"
    "/Applications/Xcode.app"
    "${pkgs.unstable.slack}/Applications/Slack.app"
    "${pkgs.unstable.brave}/Applications/Brave\ Browser.app"
    "${pkgs.unstable.spotify}/Applications/Spotify.app"
    "/System/Applications/Messages.app"
  ];
}
