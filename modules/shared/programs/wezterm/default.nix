{...}: {
  programs = {
    wezterm = {
      enable = true;
      extraConfig = builtins.readFile ./config.lua;
    };
  };

  home.file."./.config/wezterm/colors" = {
    source = ./colors;
    recursive = true;
  };
}
