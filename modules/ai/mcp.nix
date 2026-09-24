# Adapter: ai.mcpServers -> home-manager's shared MCP registry
# (programs.mcp.servers). Tools opt in via their own enableMcpIntegration.
#
# Disabled servers are filtered out HERE on purpose. Claude Code's
# `disabledMcpjsonServers` only applies to project .mcp.json files, not to the
# plugin-provided servers home-manager generates, so passing a disabled server
# through would still load it.
#
# Secret handling: `{ secret = ...; }` env refs are resolved when the server
# process starts, by a wrapper script (utils.secrets.mkEnvWrapper) that calls
# `secrets.readCommand` from the secrets bus (modules/secrets). Only the
# REFERENCE (e.g. an op:// URI) enters the Nix store; the resolved value never
# does. The store is world-readable and `apps/switch` pushes the closure to
# Cachix, so this distinction matters.
{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  cfg = config.ai;
  readCommand = config.secrets.readCommand;

  enabledServers = utils.enabled cfg.mcpServers;

  isFileRef = v: lib.isAttrs v && v.file != null;
  isSecretRef = v: lib.isAttrs v && v.secret != null;

  literalEnv = env: lib.filterAttrs (_: v: !lib.isAttrs v) env;
  fileEnv = env: lib.mapAttrs (_: v: {file = v.file;}) (lib.filterAttrs (_: isFileRef) env);
  secretEnv = env: lib.mapAttrs (_: v: v.secret) (lib.filterAttrs (_: isSecretRef) env);

  usesSecrets = server: secretEnv server.env != {};

  mkSecretWrapper = name: server:
    utils.secrets.mkEnvWrapper {
      inherit pkgs readCommand;
      name = "ai-mcp-${name}";
      secretEnv = secretEnv server.env;
      command = server.command;
      args = server.args;
    };

  toHomeManagerServer = name: server: let
    wrap = server.command != null && usesSecrets server;
    base = removeAttrs server ["enable" "description" "command" "args" "env"];
  in
    base
    // {
      command =
        if wrap
        then "${mkSecretWrapper name server}"
        else server.command;
      args =
        if wrap
        then []
        else server.args;
      env = literalEnv server.env // fileEnv server.env;
    };

  envAssertions = lib.concatLists (lib.mapAttrsToList (name: server:
    lib.mapAttrsToList (var: v: {
      assertion = !lib.isAttrs v || ((v.file != null) != (v.secret != null));
      message = "ai.mcpServers.${name}.env.${var}: exactly one of `file` or `secret` must be set.";
    })
    server.env)
  enabledServers);
in {
  config = lib.mkMerge [
    {
      assertions =
        envAssertions
        ++ [
          {
            assertion = !(lib.any usesSecrets (lib.attrValues enabledServers)) || readCommand != [];
            message = ''
              ai.mcpServers: a server uses a `{ secret = ...; }` env reference but
              `secrets.readCommand` is empty. Set secrets.backend (or secrets.readCommand)
              on this host; see modules/secrets/README.md.
            '';
          }
        ];
    }
    (lib.mkIf (enabledServers != {}) (utils.mkHomeManagerUser {
      programs.mcp = {
        enable = true;
        servers = lib.mapAttrs toHomeManagerServer enabledServers;
      };
    }))
  ];
}
