{pkgs, ...}: {
  programs = {
    tmux = {
      enable = true;
      extraConfig = builtins.readFile ./.tmux.conf;
      aggressiveResize = true;
      # need to disable sensible for now until i figure out what setting
      # is messing with the shell defaults
      sensibleOnTop = false;
      escapeTime = 100;
      resizeAmount = 100;
      plugins = with pkgs.tmuxPlugins; [
        continuum
        tmux-fzf
        {
          plugin = resurrect;
          extraConfig = "set -g @resurrect-strategy-nvim 'session'";
        }
      ];
    };
  };
}
