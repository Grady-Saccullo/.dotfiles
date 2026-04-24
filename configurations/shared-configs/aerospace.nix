{
  automatically-unhide-macos-hidden-apps = true;
  default-root-container-layout = "tiles";
  default-root-container-orientation = "auto";

  gaps = {
    inner.horizontal = 4;
    inner.vertical = 4;
    outer.left = 4;
    outer.right = 4;
    outer.top = 4;
    outer.bottom = 4;
  };

  # 1-3 on landscape (main), 4-6 on portrait (secondary). Confirm monitor
  # identifiers with `aerospace list-monitors` and reorder if needed.
  workspace-to-monitor-force-assignment = {
    "1" = "main";
    "2" = "main";
    "3" = "main";
    "4" = "secondary";
    "5" = "secondary";
    "6" = "secondary";
  };

  mode.main.binding = {
    alt-h = "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors left";
    alt-j = "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors down";
    alt-k = "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors up";
    alt-l = "focus --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors right";

    alt-shift-h = "move left";
    alt-shift-j = "move down";
    alt-shift-k = "move up";
    alt-shift-l = "move right";

    cmd-alt-shift-h = "join-with left";
    cmd-alt-shift-j = "join-with down";
    cmd-alt-shift-k = "join-with up";
    cmd-alt-shift-l = "join-with right";

    alt-minus = "resize smart -250";
    alt-equal = "resize smart +250";

    alt-slash = "layout tiles horizontal vertical";
    alt-comma = "layout accordion horizontal vertical";
    alt-f = "fullscreen";
    alt-shift-space = "layout floating tiling";

    alt-1 = "workspace 1";
    alt-2 = "workspace 2";
    alt-3 = "workspace 3";
    alt-4 = "workspace 4";
    alt-5 = "workspace 5";
    alt-6 = "workspace 6";
    alt-tab = "workspace-back-and-forth";

    alt-shift-1 = "move-node-to-workspace 1";
    alt-shift-2 = "move-node-to-workspace 2";
    alt-shift-3 = "move-node-to-workspace 3";
    alt-shift-4 = "move-node-to-workspace 4";
    alt-shift-5 = "move-node-to-workspace 5";
    alt-shift-6 = "move-node-to-workspace 6";

    alt-leftSquareBracket = "focus-monitor prev";
    alt-rightSquareBracket = "focus-monitor next";

    alt-shift-leftSquareBracket = "move-node-to-monitor prev";
    alt-shift-rightSquareBracket = "move-node-to-monitor next";

    alt-r = "mode resize";
    alt-shift-c = "reload-config";
  };

  mode.resize.binding = {
    h = "resize width -250";
    j = "resize height +250";
    k = "resize height -250";
    l = "resize width +250";
    equal = "balance-sizes";
    enter = "mode main";
    esc = "mode main";
  };
}
