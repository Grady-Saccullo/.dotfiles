{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "claude-code";
  inherit config;
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [pkgs.llm-agents.claude-code];
    })
