# nix-darwin base config for personal
{
  pkgs,
  systemConfig,
  ...
}: {

  nix.useDaemon = true;

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  users.users.${systemConfig.user} = {
    home = "/Users/${systemConfig.user}";
  };

  environment.shells = with pkgs; [bashInteractive zsh];

  system = {
    stateVersion = 4;

    defaults = {
      dock = {
        autohide = true;
      };

      finder = {
        AppleShowAllFiles = true;
        QuitMenuItem = true;
        _FXShowPosixPathInTitle = true;
      };

      LaunchServices = {
        LSQuarantine = true;
      };

      NSGlobalDomain = {
        # Make function keys stay function keys
        "com.apple.keyboard.fnState" = true;
        # I am a weirdo and like the natural scroll direction... don't ask
        "com.apple.swipescrolldirection" = true;
      };

      trackpad = {
        TrackpadThreeFingerDrag = true;
      };
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
  };

  security = {
    pam = {
      enableSudoTouchIdAuth = true;
    };
  };
}
