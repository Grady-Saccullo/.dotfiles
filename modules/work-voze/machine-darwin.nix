_: let
  mas = import ../shared/darwin/homebrew-mas.nix;
  brew = import ../../lib/brew.nix;
in {
  imports = [
    ../../machines/darwin.nix
    ../shared/darwin/programs
  ];

  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };

    masApps =
      mas.bitwarden
      // mas.todoist;

    casks = [
      (brew.greedy "1password")
      (brew.greedy "android-studio")
      (brew.greedy "betterdisplay")
      (brew.greedy "discord")
      (brew.greedy "docker")
      (brew.greedy "google-chrome")
      (brew.greedy "slack")
      (brew.greedy "soundsource")
      (brew.greedy "spotify")
      (brew.greedy "wezterm")
      (brew.greedy "zoom")
    ];
  };
}
