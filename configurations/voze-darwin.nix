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
      profile = "work";
    };
    android-studio.enable = true;
    claude-code.enable = true;
    betterdisplay.enable = true;
    bettersnaptool.enable = true;
    bitwarden = {
      enable = true;
      browserExtension.enable = true;
    };
    brave.enable = true;
    cursor-editor.enable = true;
    charles-proxy.enable = true;
    discord.enable = true;
    docker.enable = true;
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
      http = {
        enable = true;
        rest.enable = true;
        kulala.enable = true;
      };
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
    raycast = {
      enable = true;
      browserExtension.enable = true;
    };
    fzf.searchPaths = [
      "$HOME/Desktop/"
      "$HOME/Documents/"
      "$HOME/Downloads/"
      "$HOME/code/"
    ];
    soundsource.enable = true;
    spotify.enable = true;
    wezterm.enable = true;
    xcode.enable = true;
  };

  system.defaults.dock.persistent-apps = [
    config.applications.wezterm.path
    "/Applications/Slack.app" # Not managed by nix
    config.applications.brave.path
    config.applications.spotify.path
    config.applications.discord.path
  ];
}
