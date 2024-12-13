{
  lib,
  flake-parts-lib,
  moduleLocation,
  config,
  ...
}: let
  inherit (lib) mapAttrs mkOption types;
  inherit (flake-parts-lib) mkSubmoduleOptions;
in {
  options = {
    flake = mkSubmoduleOptions {
      homeManagerModules = mkOption {
        type = types.lazyAttrsOf types.deferredModule;
        default = {};
        apply = mapAttrs (k: v: {
          _file = "${toString moduleLocation}#homeManagerModules.${k}";
          imports = [v];
        });
        description = ''
          Home Manager modules.

          You may use this for reusable pieces of configuration, service modules, etc.
        '';
      };

      darwinModules = mkOption {
        type = types.lazyAttrsOf types.deferredModule;
        default = {};
        apply = mapAttrs (k: v: {
          _file = "${toString moduleLocation}#darwinModules.${k}";
          imports = [v];
        });
        description = ''
          Darwin modules.

          You may use this for reusable pieces of configuration, service modules, etc.
        '';
      };

      constants = mkOption {
        description = ''
          Shared constants

          Reusable constants to be used in configuration, service modules, etc.
        '';
        type = types.submodule {
          options = {
            stateVersion = mkOption {
              description = ''
                Current version of nix (eg 24.11)
              '';
              type = types.str;
            };
            darwinStateVersion = mkOption {
              description = ''
                Darwin state version to use across all configurations
              '';
              type = types.int;
            };
          };
        };
      };

      applications = mkOption {
        type = types.deferredModule;
      };

      utils = mkOption {
        type = types.attrs;
        default = {
          mkHomeManagerUser = mod: {
            home-manager.users.${config.me.user} = mod;
          };
          isMachine = machine: config.configuration.machine == machine;
          isNotMachine = machine: config.configuration.machine != machine;
        };
      };
    };
  };
}
