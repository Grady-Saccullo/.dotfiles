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
        zsh.initContent = lib.mkIf (config.applications.zsh.enable && config.applications.ripgrep.enable) ''
          # ripgrep->fzf->vim [QUERY]
          rfv() (
            RELOAD='reload:rg --column --color=always --smart-case {q} || :'
            OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
                      vim {1} +{2}
                    else
                      vim +cw -q {+f}
                    fi'
            fzf --disabled --ansi --multi \
                --bind "start:$RELOAD" --bind "change:$RELOAD" \
                --bind "enter:become:$OPENER" \
                --bind "ctrl-o:execute:$OPENER" \
                --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
                --delimiter : \
                --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
                --preview-window '~4,+{2}+4/3,<120(up)' \
                --query "$*"
          )
        '';

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
