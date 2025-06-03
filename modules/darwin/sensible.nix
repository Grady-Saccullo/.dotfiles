{
  pkgs,
  me,
  inputs,
  ...
}: let
  inherit (inputs) self;
in rec {
  imports = [
    (inputs.nix-homebrew.darwinModules.nix-homebrew)
  ];

  users.users.${me.user} = {
    home = "/Users/${me.user}";
    shell = pkgs.zsh;
  };

  nix = {
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

    taps = builtins.attrNames nix-homebrew.taps;
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
    primaryUser = me.user;

    activationScripts = {
      extraActivation.text = ''
        echo >&2 "setting up rosetta..."
        softwareupdate --install-rosetta --agree-to-license >/dev/null 2>&1
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
      services = {
        sudo_local = {
          enable = true;
          reattach = true;
          touchIdAuth = true;
        };
      };
    };
  };
}
