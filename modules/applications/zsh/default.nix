{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  inherit config;
  path = "zsh";
  default = true;
} (cfg:
    utils.mkHomeManagerUser {
      programs.zsh = {
        enable = true;
        shellAliases = {
          l = "ls -la";
          cl = "clear";
          "~" = "cd ~";
          "--" = "cd -";
          ".." = "cd ..";
          md = "mkdir -p";
          rd = "rmdir";
          d = "dirs -v | head -n 10";
          "1" = "cd -1";
          "2" = "cd -2";
          "3" = "cd -3";
          "4" = "cd -4";
          "5" = "cd -5";
          "6" = "cd -6";
          "7" = "cd -7";
          "8" = "cd -8";
          "9" = "cd -9";
        };
        history = {
          size = 50000;
          save = 10000;
          extended = true;
          expireDuplicatesFirst = true;
        };
        initContent = ''
          # inspiration taken from omz
          setopt auto_cd
          setopt auto_pushd
          setopt pushd_ignore_dups
          setopt pushdminus

          setopt auto_menu
          setopt complete_in_word
          setopt always_to_end
          unsetopt menu_complete
          unsetopt flowcontrol

          WORDCHARS=""

          zstyle ':completion:*:*:*:*:*' menu select
          zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
          zstyle ':completion:*' special-dirs true
          zstyle ':completion:*' use-cache yes
          zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

          setopt hist_verify

          bindkey "^[[A" history-search-backward
          bindkey "^[[B" history-search-forward
          bindkey "^[[H" beginning-of-line
          bindkey "^[[F" end-of-line
          bindkey "^[[1;5C" forward-word
          bindkey "^[[1;5D" backward-word
          bindkey "^[[Z" reverse-menu-complete
          bindkey "^[[3~" delete-char
          bindkey "^X^E" edit-command-line
          bindkey " " magic-space

          autoload -U edit-command-line
          zle -N edit-command-line

          # Expand ... to ../.. as you type (rationalise-dot)
          function rationalise-dot() {
            if [[ $LBUFFER = *.. ]]; then
              LBUFFER+=/..
            else
              LBUFFER+=.
            fi
          }
          zle -N rationalise-dot
          bindkey . rationalise-dot
          bindkey -M isearch . self-insert
        '';
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
      };
    })
