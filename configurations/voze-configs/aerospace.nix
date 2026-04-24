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
        "if" = {app-id = "com.jetbrains.intellij";};
        run = "move-node-to-workspace 1";
      }
      {
        "if" = {app-id = "com.apple.dt.Xcode";};
        run = "move-node-to-workspace 1";
      }
      {
        "if" = {app-id = "com.brave.Browser";};
        run = "move-node-to-workspace 2";
      }
      {
        "if" = {app-id = "us.zoom.xos";};
        run = ["move-node-to-workspace 3" "layout floating"];
      }
      {
        "if" = {app-id = "com.tinyspeck.slackmacgap";};
        run = "move-node-to-workspace 4";
      }
      {
        "if" = {app-id = "com.hnc.Discord";};
        run = "move-node-to-workspace 4";
      }
      {
        "if" = {app-id = "com.spotify.client";};
        run = "move-node-to-workspace 6";
      }
    ];
  }
