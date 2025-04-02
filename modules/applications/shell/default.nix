{
  utils,
  lib,
  pkgs,
  config,
  ...
}: let
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
  config = utils.mkHomeManagerUser {
    programs = {
      # TODO: figure out where i want to put these. here works for now
      bat.enable = true;
      btop.enable = true;
      jq.enable = true;

      fzf = lib.mkIf cfg.fzf.enable (let
        baseOptions = [
          "--height 100%"
          "--layout default"
          "--border"
        ];
        fileOptions =
          baseOptions
          ++ [
            "--preview 'bat --color=always {}'"
            "--bind 'enter:become(vim {} < /dev/tty > /dev/tty)'"
          ];
      in {
        enable = true;
        package = pkgs.unstable.fzf;
        enableZshIntegration = cfg.zsh.enable;
        defaultCommand = "fd -t f -H . $HOME";
        fileWidgetCommand = "fd -t f -H . $HOME";
        fileWidgetOptions = fileOptions;
        changeDirWidgetCommand = "fd -t d -H . $HOME";
        changeDirWidgetOptions = baseOptions;
        tmux.enableShellIntegration = cfg.tmux.enable;
      });

      fd = lib.mkIf cfg.fzf.enable {
        enable = true;
        ignores = [
          ".aws/"
          ".bash_sessions/"
          ".cache/"
          ".cargo/"
          ".config/"
          ".gem/"
          ".git/"
          ".local/"
          ".matplotlib/"
          ".nix-defexpr/"
          ".nix-profile/"
          ".npm/"
          ".rustup/"
          ".ssh/"
          ".tmux/"
          ".Trash/"
          ".vim/"
          ".zsh_sessions/"
          "Applications/"
          "bin/"
          "build/"
          "dist/"
          "go/"
          "Library/"
          "Movies/"
          "Music/"
          "node_modules/"
          "out/"
          "Pictures/"
          "Public/"
          "target/"
          "vendor/"
        ];
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
