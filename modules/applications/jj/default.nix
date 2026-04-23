{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "jj";
  inherit config;
  default = true;
} (cfg:
    utils.mkHomeManagerUser {
      programs.jujutsu = {
        enable = true;
        package = pkgs.unstable.jujutsu;
        settings = {
          user = {
            name = config.applications.git.username;
            email = config.applications.git.email;
          };
          ui = {
            default-command = "log";
            diff-formatter = ":git";
            pager = "delta";
            diff-editor = ":builtin";
            merge-editor = ":builtin";
          };
          git = {
            push-bookmark-prefix = "gs/";
          };
        };
      };

      programs.zsh = lib.mkIf config.applications.zsh.enable {
        shellAliases = {
          j = "jj";
        };
      };
    })
