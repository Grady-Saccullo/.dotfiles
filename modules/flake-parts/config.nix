{lib, ...}: {
  imports = [../../config.nix];
  options = {
    configuration = lib.mkOption {
      type = lib.types.submodule {
        options = {
          machine = lib.mkOption {
            type = lib.types.str;
          };
          name = lib.mkOption {
            type = lib.types.str;
          };
        };
      };
    };
    me = lib.mkOption {
      type = lib.types.submodule {
        options = {
          user = lib.mkOption {
            type = lib.types.str;
          };
        };
      };
    };
  };
}
