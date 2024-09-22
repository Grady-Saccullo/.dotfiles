_: {
  programs = {
    zsh = {
      enable = true;

      # TODO: make darwin specific
      initExtra = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
      '';

      shellAliases = {
        l = "ls -la";
      };

      oh-my-zsh = {
        enable = true;

        plugins = [
          "git"
        ];
        theme = "robbyrussell";
      };
    };
  };
}
