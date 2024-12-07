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
      // mas.todoist
      // mas.betterSnapTool;

    # forcing greedy bc too lazy to go figure out if packages are correctly versioned or not
    casks = [
      (brew.greedy "betterdisplay")
      # TODO: port this possibly to nix packages...
      (brew.greedy "soundsource")
      (brew.greedy "steam")
    ];
  };
}
