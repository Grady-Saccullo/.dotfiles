{
  pkgs,
  me,
  inputs,
  ...
}: let
  sed = "${pkgs.gnused}/bin/sed";
  inherit (inputs) self;
in {
  imports = [
    (inputs.nix-homebrew.darwinModules.nix-homebrew)
  ];

  users.users.${me.user} = {
    home = "/Users/${me.user}";
    shell = pkgs.zsh;
  };

  nix = {
    useDaemon = true;
    gc = {
      automatic = true;
      interval = [
        {
          Weekday = 7; # Sunday
          Hour = 22;
          Minute = 0;
        }
      ];
      options = "--delete-older-than 30d";
    };
    optimise = {
      automatic = true;
      interval = [
        {
          Weekday = 7; # Sunday
          Hour = 23;
          Minute = 0;
        }
      ];
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      extra-platforms = aarch64-darwin x86_64-darwin
    '';
  };

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "${me.user}";
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
    };

    mutableTaps = false;
  };

  environment.shells = with pkgs; [bashInteractive zsh];

  system = {
    stateVersion = self.constants.darwinStateVersion;

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

      hitoolbox = {
        AppleFnUsageType = "Do Nothing";
      };

      loginwindow = {
        GuestEnabled = false;
      };

      LaunchServices = {
        LSQuarantine = true;
      };

      NSGlobalDomain = {
        # Make function keys stay function keys
        "com.apple.keyboard.fnState" = true;
        # I am a weirdo and like the natural scroll direction... don't ask
        "com.apple.swipescrolldirection" = true;

        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
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
