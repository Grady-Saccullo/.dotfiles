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
      # NOTE: 1pass updates are killin me... and causing havoc... might just be worth manually installing for darwin
    # _1password = {
    #   enable = true;
    #   browserExtension.enable = true;
    # };
    android-studio.enable = true;
    betterdisplay.enable = true;
    bettersnaptool.enable = true;
    bitwarden = {
      enable = true;
      browserExtension.enable = true;
    };
    brave.enable = true;
    cursor-editor.enable = true;
    github-cli.enable = true;
    jetbrains = {
      enable = true;
      datagrip.enable = true;
      idea.enable = true;
      rider.enable = true;
    };
    neovim = {
      enable = true;
      angular.enable = true;
      dap = {
        enable = true;
        go.enable = true;
      };
      db = {
        enable = true;
        sql.enable = true;
      };
      go.enable = true;
      docker.enable = true;
      python.enable = true;
      protobuf.enable = true;
      html.enable = true;
      terraform.enable = true;
      typescript = {
        enable = true;
        lsp = "vtsls";
        tsx.enable = true;
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
    "${config.applications.slack.package}/Applications/Slack.app"
    "${config.applications.brave.package}/Applications/Brave\ Browser.app"
    "${config.applications.spotify.package}/Applications/Spotify.app"
    "/System/Applications/Messages.app"
  ];
}
