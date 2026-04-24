let
  shared = import ../shared-configs/aerospace.nix;
in
  shared
  // {
    on-window-detected = [
      {
        "if" = {app-id = "com.spotify.client";};
        run = "move-node-to-workspace 3";
      }
    ];
  }
