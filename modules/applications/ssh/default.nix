# ~/.ssh/config generated from hosts/default.nix: `ssh homelab` works from
# every machine with no per-box setup. On macOS the 1Password agent is used
# when that application is enabled, so private keys never live on disk.
{
  utils,
  config,
  lib,
  hosts,
  ...
}:
utils.mkAppModule {
  inherit config;
  path = "ssh";
} (cfg: let
  onePasswordAgent = "~/Library/Group Containers/2BUA8C4S2C.group.com.1password/t/agent.sock";
  hostBlocks =
    lib.mapAttrs (name: h: {
      hostname = h.address;
      user = h.user;
    })
    hosts;
in
  utils.mkHomeManagerUser {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks =
        hostBlocks
        // {
          "*" = utils.mkPlatformConfig {
            base = {
              addKeysToAgent = "yes";
              serverAliveInterval = 30;
              compression = false;
              hashKnownHosts = false;
            };
            darwin = lib.optionalAttrs (config.applications."1password".enable or false) {
              extraOptions.IdentityAgent = ''"${onePasswordAgent}"'';
            };
          };
        };
    };
  })
