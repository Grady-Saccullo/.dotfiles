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
      options = "--delete-older-than 7d";
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

    settings = {
      trusted-users = ["root" "${me.user}"];
      extra-substituters = ["https://cache.numtide.com"];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
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

  # Disable nix-darwin's default zshrc additions as home-manager handles these.
  # This avoids double compinit and a useless promptinit scan.
  programs.zsh.enableCompletion = false;
  programs.zsh.promptInit = "";

  system = {
    stateVersion = self.constants.darwinStateVersion;
    primaryUser = me.user;

    activationScripts = {
      extraActivation.text = ''
        echo >&2 "setting up rosetta..."
        softwareupdate --install-rosetta --agree-to-license >/dev/null 2>&1
      '';

      # Reload user preferences so changes (e.g. CustomUserPreferences) take
      # effect immediately without requiring a logout.
      # See: https://github.com/LnL7/nix-darwin/issues/518
      postActivation.text = ''
        sudo -u ${me.user} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
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

      menuExtraClock = {
        ShowSeconds = true;
      };

      NSGlobalDomain = {
        # Make function keys stay function keys
        "com.apple.keyboard.fnState" = true;
        # I am a weirdo and like the natural scroll direction... don't ask
        "com.apple.swipescrolldirection" = true;
        "com.apple.mouse.tapBehavior" = 1;

        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };

      trackpad = {
        TrackpadThreeFingerDrag = true;
      };

      # Override macOS symbolic hotkeys (System Settings > Keyboard > Keyboard Shortcuts).
      #
      # Each entry maps a hotkey ID to its configuration. You can find IDs by running:
      #   defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys
      #
      # To disable a shortcut: { enabled = false; }
      # To remap a shortcut:   { enabled = true; value = { parameters = [ascii keycode modifiers]; type = "standard"; }; }
      #
      # Modifier flags (combine with addition):
      #   Shift   = 131072    Option  = 524288
      #   Control = 262144    Command = 1048576
      #
      # Reference: https://github.com/LnL7/nix-darwin/issues/518
      CustomUserPreferences = {
        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            # Disable Ctrl+Arrow Mission Control shortcuts so they can be used
            # for wezterm/neovim pane navigation (smart-splits).
            "32" = {enabled = false;}; # Mission Control (Ctrl+Up)
            "33" = {enabled = false;}; # Application Windows (Ctrl+Down)
            "79" = {enabled = false;}; # Move left a space (Ctrl+Left)
            "80" = {enabled = false;}; # Move right a space (Ctrl+Right)

            # Remap Spotlight to Opt+Space so Cmd+Space is free for Raycast.
            # parameters: [ascii=32 (space), keycode=49 (space), modifiers=524288 (Option)]
            "64" = {
              enabled = true;
              value = {
                parameters = [32 49 524288];
                type = "standard";
              };
            };
          };
        };
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
          # watchIdAuth = true;
        };
      };
    };
  };
}
