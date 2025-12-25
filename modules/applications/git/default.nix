{
  utils,
  config,
  lib,
  pkgs,
  ...
}: let
  gitAliases = import ./git-aliases.nix;
in
  utils.mkAppModule {
    path = "git";
    inherit config;
    default = true;
    extraOptions = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "Grady Saccullo";
      };
      email = lib.mkOption {
        type = lib.types.str;
        default = "gradys.dev@gmail.com";
      };
    };
  } (cfg:
    utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.git-filter-repo];
      programs = {
        git = {
          enable = true;
          package = pkgs.unstable.git;
          settings = {
            user = {
              email = cfg.email;
              name = cfg.username;
            };
          };
          lfs.enable = true;
        };
        delta = {
          enable = true;
          enableGitIntegration = true;
        };
        zsh = lib.mkIf config.applications.zsh.enable {
          shellAliases = gitAliases.aliases;
          initContent = gitAliases.initContent;
        };
      };
    })
