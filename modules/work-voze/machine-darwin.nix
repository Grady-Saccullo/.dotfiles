_: let
  mas = import ../shared/darwin/homebrew-mas.nix;
in {
  imports = [
    ../../machines/darwin.nix
    ../shared/darwin/programs
  ];

  homebrew = {
    enable = true;

    onActivation.cleanup = "uninstall";

    masApps =
      mas.bitwarden
      // mas.todoist;

    casks = [
      "1password"
      "android-studio"
      "betterdisplay"
      "brave-browser"
      "discord"
      "docker"
      "google-chrome"
      "postman"
      "slack"
      "soundsource"
      "spotify"
      "wezterm"
      "zoom"
    ];
  };
}
