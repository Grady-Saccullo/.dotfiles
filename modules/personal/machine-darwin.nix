{...}: {
  imports = [
    ./machine-base.nix
    ../../machines/darwin.nix
  ];

  homebrew = {
    enable = true;

    casks = [
      "betterdisplay"
      "brave-browser"
      "discord"
      "docker"
      "slack"
      "soundsource"
      "spotify"
      "utm"
      "vmware-fusion"
    ];
  };
}
