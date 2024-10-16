# nix-darwin base config for personal
{
  pkgs,
  systemConfig,
  inputs,
  ...
}: let
  sed = "${pkgs.gnused}/bin/sed";
in {
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
        echo >&2 "setting up rosetta..."
        softwareupdate --install-rosetta --agree-to-license >/dev/null 2>&1

        # look into maybe an overlay or even custom package for this so we can
        # symlink to pam_reattach.so and correctly remove when uninstalled
        echo >&2 "setting up reattach for pam..."
        if ! grep 'pam_reattach.so' /etc/pam.d/sudo > /dev/null; then
          ${sed} -i '2i\
        auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so # set from extraActivation script within nix-darwin config
          ' /etc/pam.d/sudo
        fi
      '';
    };

    defaults = {
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        orientation = "bottom";
        persistent-apps = [
          "/Applications/WezTerm.app"
          "/Applications/Spotify.app"
          "/Applications/Safari.app"
          "/System/Applications/Messages.app"
        ];
        show-recents = false;
        showhidden = true;
        static-only = false;
        tilesize = 48;
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

        InitialKeyRepeat = 15;
        KeyRepeat = 2;
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
