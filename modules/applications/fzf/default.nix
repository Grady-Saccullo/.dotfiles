{
  utils,
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.applications.fzf;
  searchPaths = lib.concatStringsSep " " (
    cfg.searchPaths
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
in
  utils.mkAppModule {
    path = "fzf";
    inherit config;
    default = true;
    extraOptions = {
      searchPaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["$HOME"];
        description = "Directories for fd/fzf to search";
      };
    };
  } (cfg:
    utils.mkHomeManagerUser {
      programs = {
        fzf = {
          enable = true;
          package = pkgs.unstable.fzf;
          enableZshIntegration = config.applications.zsh.enable;
          defaultCommand = "fd -t f -H . ${searchPaths}";
          fileWidgetCommand = "fd -t f -H . ${searchPaths}";
          fileWidgetOptions = fileOptions;
          changeDirWidgetCommand = "{ fd -t d -H . ${searchPaths}; echo ${searchPaths} | tr ' ' '\\n'; } | sort -u";
          changeDirWidgetOptions = baseOptions;
          tmux.enableShellIntegration = config.applications.tmux.enable;
        };

        fd = {
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
      };
    })
