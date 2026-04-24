let
  shared = import ../shared-configs/aerospace.nix;
in
  shared
  // {
    on-window-detected = [
      {
        "if" = {app-id = "com.github.wez.wezterm";};
        run = "move-node-to-workspace 1";
      }
      {
        "if" = {app-id = "com.brave.Browser";};
        run = "move-node-to-workspace 2";
      }
      {
        "if" = {app-id = "com.spotify.client";};
        run = "move-node-to-workspace 4";
      }
    ];
  }
