{
  utils,
  config,
  lib,
  pkgs,
  me,
  ...
}:
utils.mkAppModule {
  path = "slack";
  inherit config;
  extraOptions = {
    package = lib.mkPackageOption pkgs "slack" {};
    path = lib.mkOption {
      type = lib.types.str;
      default = "/Users/${me.user}/Applications/Home Manager Apps/Slack.app";
      description = "Path to the Slack application";
    };
    bundleId = lib.mkOption {
      type = lib.types.str;
      default = "com.tinyspeck.slackmacgap";
      readOnly = true;
      description = "macOS bundle identifier, for window-manager rules and the like";
    };
    mcp.enable = lib.mkEnableOption "the Slack MCP server (mcp.slack.com, OAuth in-app) for AI tools via ai.mcpServers";
  };
} (cfg:
    lib.mkMerge [
      (utils.mkHomeManagerUser {
        home.packages = [cfg.package];
      })
      # Apps that have an official MCP server contribute it to the
      # `ai.mcpServers` bus behind an opt-in, like browser extensions
      # (bitwarden's `browserExtension.enable`); hosts can still flip
      # `ai.mcpServers.slack.enable = false`.
      (lib.mkIf cfg.mcp.enable {
        ai.mcpServers.slack = {
          url = "https://mcp.slack.com/mcp";
          description = "Slack workspace: search messages, channels, threads (OAuth on first connect)";
        };
      })
    ])
