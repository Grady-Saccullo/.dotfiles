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
    _1password = {
      enable = true;
      browserExtension.enable = true;
    };
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
    "${config.applications.wezterm.package}/Applications/WezTerm.app"
    "/Applications/Android\ Studio.app"
    "/Applications/Xcode.app"
    "${config.applications.slack.package}/Applications/Slack.app"
    "${config.applications.brave.package}/Applications/Brave\ Browser.app"
    "${config.applications.spotify.package}/Applications/Spotify.app"
    "/System/Applications/Messages.app"
  ];
}
