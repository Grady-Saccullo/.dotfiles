# Cachix login and push for `nix run .#switch`. Hosts set vault references; apps/switch reads the
# tokens from the `cachix.backend` password manager at switch time, so no token ever enters Nix.
{
  config,
  lib,
  utils,
  ...
}: let
  cfg = config.cachix;
  secretRef = lib.types.either lib.types.str (lib.types.listOf lib.types.str);
  # Same backend as the host's other secrets: keep any custom `secrets.readCommand` it sets.
  readCommand =
    if cfg.backend == config.secrets.backend
    then config.secrets.readCommand
    else utils.secrets.readCommandFor.${cfg.backend} or [];
  readWith = ref:
    if ref == null
    then null
    else readCommand ++ lib.toList ref;
in {
  options.cachix = {
    cache = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "my-cache";
      description = ''
        Cachix cache that `nix run .#switch` logs in to and pushes the built system to. Downloading
        from it also needs the cache in the flake's `nixConfig`, which a module cannot set.
      '';
    };
    backend = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["op" "rbw" "bw"]);
      default = config.secrets.backend;
      defaultText = lib.literalExpression "config.secrets.backend";
      example = "bw";
      description = ''
        Password manager the tokens are read from. Set it when they live somewhere other than the
        host's other secrets, for example one personal vault shared by several machines.
      '';
    };
    readToken = lib.mkOption {
      type = lib.types.nullOr secretRef;
      default = null;
      example = "op://Private/Cachix/read-token";
      description = ''
        Vault reference for a read-only token. `nix run .#switch` writes it to the
        `machine <cache>.cachix.org` line of `nix.settings.netrc-file` before building.
      '';
    };
    pushToken = lib.mkOption {
      type = lib.types.nullOr secretRef;
      default = null;
      example = "op://Private/Cachix/push-token";
      description = ''
        Vault reference for a token with write access, used only for `cachix push` after a switch.
        When unset, the push uses `CACHIX_AUTH_TOKEN` from the environment if it is set.
      '';
    };
    switchCommands = lib.mkOption {
      type = lib.types.attrs;
      internal = true;
      readOnly = true;
      description = "What apps/switch reads through `nix eval`.";
    };
  };

  config = {
    cachix.switchCommands = {
      inherit (cfg) cache;
      netrcFile = config.nix.settings.netrc-file or "/etc/nix/netrc";
      readToken = readWith cfg.readToken;
      pushToken = readWith cfg.pushToken;
    };

    assertions = [
      {
        assertion = (cfg.readToken == null && cfg.pushToken == null) || cfg.cache != null;
        message = "cachix.readToken / cachix.pushToken are set but cachix.cache is not.";
      }
      {
        assertion = (cfg.readToken == null && cfg.pushToken == null) || readCommand != [];
        message = ''
          cachix.readToken / cachix.pushToken are vault references but no password manager is set.
          Set cachix.backend or secrets.backend on this host; see modules/secrets/README.md.
        '';
      }
    ];
  };
}
