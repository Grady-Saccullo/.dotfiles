# nix-darwin base config for personal
{
  pkgs,
  systemConfig,
  inputs,
  ...
}: {
  nix.useDaemon = true;

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "${systemConfig.user}";
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
    };

    # Enable fully-declarative tap management
    mutableTaps = false;
  };

  users.users.${systemConfig.user} = {
    home = "/Users/${systemConfig.user}";
    shell = pkgs.zsh;
  };

  environment.shells = with pkgs; [bashInteractive zsh];

  system = {
    stateVersion = 4;

    activationScripts = {
      extraActivation.text = ''
        softwareupdate --install-rosetta --agree-to-license;
      '';
    };

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
