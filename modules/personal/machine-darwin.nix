{...}: {
  imports = [
    ./machine-base.nix
    ../../machines/darwin.nix
  ];

  homebrew = {
    enable = true;

    onActivation.cleanup = "uninstall";

    brews = [
      "carthage"
      "neofetch"
    ];

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
      "utm"
      "vmware-fusion"
      "wezterm"
      "zoom"
    ];
  };
}
