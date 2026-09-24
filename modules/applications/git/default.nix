{
  utils,
  config,
  pkgs,
  ...
}: let
  gitAliases = import ./git-aliases.nix;
in
  utils.mkAppModule {
    path = "git";
    inherit config;
    default = true;
  } (cfg:
    (utils.mkHomeManagerUser {
      home.packages = [pkgs.git-filter-repo];
      programs = {
        git = {
          enable = true;
          package = pkgs.git;
          settings = {
            user = {
              email = config.identity.email;
              name = config.identity.name;
            };
          };
          lfs.enable = true;
        };
        delta = {
          enable = true;
          enableGitIntegration = true;
          options.pager = "less -R --mouse";
        };
      };
    })
    // {
      # Aliases and the branch-detection functions go to the shell-agnostic
      # `shell.*` bus (see modules/shell/README.md); whichever shell module is
      # enabled (zsh today) installs them, so nothing here gates on zsh.
      shell.aliases = gitAliases.aliases;
      shell.init.git = gitAliases.initContent;

      # Read-only git subcommands AI tools may run without a prompt (the
      # `ai.*` bus, see modules/ai/README.md).
      ai.permissions.allow = [
        "Bash(git status:*)"
        "Bash(git log:*)"
        "Bash(git diff:*)"
        "Bash(git show:*)"
        "Bash(git branch:*)"
      ];
    })
