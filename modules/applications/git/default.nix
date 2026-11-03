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
      package = lib.mkPackageOption pkgs "git" {};
    };
  } (cfg:
    (utils.mkHomeManagerUser {
      home.packages = [pkgs.git-filter-repo];
      programs = {
        git = {
          enable = true;
          package = cfg.package;
          settings = {
            user = {
              email = config.identity.email;
              name = config.identity.name;
            };
            init.defaultBranch = "main";
            push = {
              autoSetupRemote = true;
              default = "simple";
            };
            pull.rebase = true;
            rebase = {
              autostash = true;
              autosquash = true;
              updateRefs = true;
            };
            rerere = {
              enabled = true;
              autoupdate = true;
            };
            diff = {
              algorithm = "histogram";
              colorMoved = "plain";
              mnemonicPrefix = true;
              renames = true;
            };
            merge.conflictStyle = "zdiff3";
            commit.verbose = true;
            fetch = {
              prune = true;
              prunetags = true;
            };
            branch.sort = "-committerdate";
            tag.sort = "version:refname";
            column.ui = "auto";
            help.autocorrect = "prompt";
            # mergiraf resolves syntax-aware merges before git falls back to textual conflict markers.
            merge.mergiraf = {
              name = "mergiraf";
              driver = "${pkgs.mergiraf}/bin/mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
            };
          };
          attributes = ["* merge=mergiraf"];
          lfs.enable = true;
        };
        delta = {
          enable = true;
          enableGitIntegration = true;
          options = {
            pager = "less -R --mouse";
            navigate = true;
            line-numbers = true;
          };
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
