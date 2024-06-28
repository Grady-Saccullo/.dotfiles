{...}: {
  xdg.configFile."wezterm" = {
    source = ../../../configs/wezterm/.config/wezterm;
    recursive = true;
  };

  programs = {
    wezterm = {
      enable = true;
    };
  };
}
