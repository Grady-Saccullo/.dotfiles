{
  pkgs,
  ...
}: {
  programs = {
    tmux = {
      enable = true;
      extraConfig = builtins.readFile ./.tmux.conf;
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
