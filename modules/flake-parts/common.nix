{lib, ...}: {
  options = {
    # TODO: pull in type from chromium
    common.browserExtensions.chromium = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
    };
    # figure out how to add safari extensions
    common.browserExtensions.safari = lib.mkOption {
      type = lib.types.attrset;
      default = [];
    };
  };
}
