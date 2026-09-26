{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "github-cli";
  inherit config;
  extraOptions = {
    package = lib.mkPackageOption pkgs "gh" {};
  };
} (cfg:
    (utils.mkHomeManagerUser {
      programs.gh = {
        enable = true;
        package = cfg.package;
        settings = {
          git_protocol = "ssh";
        };
      };
    })
    // {
      # Read-only gh subcommands AI tools may run without a prompt. Published on
      # the `ai.*` bus (modules/ai/README.md); hosts extend or override through
      # `applications.claude-code.managedSettings.permissions`.
      ai.permissions.allow = [
        "Bash(gh pr view:*)"
        "Bash(gh pr diff:*)"
        "Bash(gh pr list:*)"
        "Bash(gh pr checks:*)"
        "Bash(gh issue view:*)"
        "Bash(gh issue list:*)"
        "Bash(gh run view:*)"
        "Bash(gh run list:*)"
      ];
    })
