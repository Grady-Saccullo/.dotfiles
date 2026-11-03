{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "starship";
  inherit config;
  default = true;
  extraOptions = {
    package = lib.mkPackageOption pkgs "starship" {};
  };
} (cfg:
    utils.mkHomeManagerUser {
      programs.starship = {
        enable = true;
        package = cfg.package;
        enableZshIntegration = config.applications.zsh.enable;
        settings = {
          # Keeps the jj change next to the directory instead of at the tail where custom modules land.
          format = "$directory\${custom.jj}$all$character";
          # Colocated jj repos keep git HEAD detached, so the built-in branch module would print "HEAD".
          git_branch.ignore_branches = ["HEAD"];
          git_commit.disabled = true;
          custom.jj = {
            description = "current jj change";
            when = "jj root --ignore-working-copy";
            command = "jj log -r @ --no-graph --ignore-working-copy --color never -T 'separate(\" \", change_id.shortest(8), bookmarks.join(\",\"), if(empty, \"(empty)\"), if(conflict, \"(conflict)\"))'";
            format = "on [$symbol$output]($style) ";
            symbol = "jj ";
            style = "bold purple";
          };
        };
      };
    })
