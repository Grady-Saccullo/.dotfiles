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
      starship.enable = (mkEnableOption "Shell / starship") // {default = true;};
      tmux.enable = (mkEnableOption "Shell / tmux") // {default = true;};
      direnv.enable = (mkEnableOption "Shell / direnv") // {default = true;};
      fzf = {
        enable = (mkEnableOption "Shell / fzf") // {default = true;};
        searchPaths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = ["$HOME"];
          description = "Directories for fd/fzf to search";
        };
      };
    };
  };
  config = utils.mkHomeManagerUser {
    programs = {
      bat.enable = true;
      btop.enable = true;
      jq.enable = true;
      ripgrep.enable = true;

      eza = {
        enable = true;
        git = true;
        enableZshIntegration = cfg.zsh.enable;
        extraOptions = [
          "--group-directories-first"
          "--header"
        ];
      };

      fzf = lib.mkIf cfg.fzf.enable (let
        searchPaths = lib.concatStringsSep " " (
          cfg.fzf.searchPaths
          ++ [
            "$HOME/.dotfiles"
            "$HOME/.config"
          ]
        );
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
        defaultCommand = "fd -t f -H . ${searchPaths}";
        fileWidgetCommand = "fd -t f -H . ${searchPaths}";
        fileWidgetOptions = fileOptions;
        # append root search paths so they're also selectable
        changeDirWidgetCommand = "{ fd -t d -H . ${searchPaths}; echo ${searchPaths} | tr ' ' '\\n'; } | sort -u";
        changeDirWidgetOptions = baseOptions;
        tmux.enableShellIntegration = cfg.tmux.enable;
      });

      fd = lib.mkIf cfg.fzf.enable {
        enable = true;
        ignores = [
          ".git/"
          ".gradle/"
          ".terraform/"
          ".elixir_ls/"
          ".lsp/"
          "_build/"
          "build/"
          "deps/"
          "dist/"
          "node_modules/"
          "out/"
          "target/"
          "vendor/"
          "zig-cache/"
          "zig-out/"
        ];
      };

      zsh = lib.mkIf cfg.zsh.enable {
        enable = true;
        shellAliases = {
          l = "ls -la";
          cl = "clear";
        };
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
      };

      starship = lib.mkIf cfg.starship.enable {
        enable = true;
        enableZshIntegration = cfg.zsh.enable;
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

    home.sessionVariables = {
      EZA_CONFIG_DIR = "${pkgs.runCommand "eza-config" {} ''
        mkdir -p $out
        cp ${./eza-theme.yaml} $out/theme.yml
      ''}";
    };
  };
}
