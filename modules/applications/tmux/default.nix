{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "tmux";
  inherit config;
  default = true;
} (cfg:
    utils.mkHomeManagerUser {
      programs.tmux = {
        enable = true;
        extraConfig = builtins.readFile ./.tmux.conf;
        aggressiveResize = true;
        sensibleOnTop = false;
        escapeTime = 100;
        resizeAmount = 100;
        plugins = with pkgs.tmuxPlugins;
          [
            continuum
            {
              plugin = resurrect;
              extraConfig = "set -g @resurrect-strategy-nvim 'session'";
            }
          ]
          ++ lib.optionals config.applications.fzf.enable [
            tmux-fzf
          ];
      };
    })
