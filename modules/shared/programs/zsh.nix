{pkgs, ...}: let
  isDarwin = pkgs.stdenv.isDarwin;
in {
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
        # // (
        #   if isDarwin
        #   then {
        #     # temporary until fully move homebrew casks to nix
        #     brew = "/opt/homebrew/bin/brew";
        #   }
        #   else {}
        # );

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
