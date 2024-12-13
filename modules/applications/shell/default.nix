{
  inputs,
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.shell;
in {
  options = {
    applications.shell = {
      zsh.enable = (mkEnableOption "Shell / zsh") // {default = true;};
      fzf.enable = (mkEnableOption "Shell / fzf") // {default = true;};
      tmux.enable = (mkEnableOption "Shell / tmux") // {default = true;};
      direnv.enable = (mkEnableOption "Shell / direnv") // {default = true;};
    };
  };
  config = self.utils.mkHomeManagerUser {
    programs = {
      # TODO: figure out where i want to put these. here works for now
      bat.enable = true;
      btop.enable = true;
      jq.enable = true;

      fzf = lib.mkIf cfg.fzf.enable {
        enable = true;
        package = pkgs.unstable.fzf;
        enableZshIntegration = cfg.zsh.enable;
        tmux.enableShellIntegration = cfg.tmux.enable;
      };

      zsh = lib.mkIf cfg.zsh.enable {
        enable = true;
        shellAliases = {
          l = "ls -la";
          cl = "clear";
        };

        oh-my-zsh = {
          enable = true;
          plugins = [
            "git"
          ];
          theme = "robbyrussell";
        };
      };

      tmux = lib.mkIf cfg.tmux.enable {
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

      direnv = lib.mkIf cfg.direnv.enable {
        enable = true;
        nix-direnv = {
          enable = true;
        };
      };
    };
  };
}
