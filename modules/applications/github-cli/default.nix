{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  path = "github-cli";
  inherit config;
} (cfg:
    utils.mkHomeManagerUser {
      programs.gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
        };
      };
    })
