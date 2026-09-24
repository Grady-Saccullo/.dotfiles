# Tool-agnostic AI configuration bus. See ./README.md.
#
# Declares `ai.*` (options.nix), auto-registers shared content
# (content.nix), declares framework-owned hooks (hooks.nix) and feeds MCP
# servers into home-manager's shared registry (mcp.nix). Tool modules (e.g.
# modules/applications/claude-code) consume `config.ai.*`; nothing here
# depends on any tool module.
{
  config,
  lib,
  utils,
  ...
}: let
  contentKinds = ["skills" "agents" "commands" "rules"];

  contentAssertions = lib.concatMap (kind:
    lib.mapAttrsToList (name: entry: {
      assertion = (entry.source != null) != (entry.text != null);
      message = "ai.${kind}.${name}: exactly one of `source` or `text` must be set.";
    })
    (utils.enabled config.ai.${kind}))
  contentKinds;
in {
  imports = [
    ./options.nix
    ./content.nix
    ./hooks.nix
    ./mcp.nix
  ];

  config.assertions = contentAssertions;
}
