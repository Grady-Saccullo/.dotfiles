{lib, ...}: let
  inherit (lib) mkOption mkEnableOption types;
in {
  options.browser.extensions.chromium = mkOption {
    type = types.attrsOf (types.submodule ({name, ...}: {
      options = {
        enable =
          mkEnableOption "the ${name} Chromium extension"
          // {default = true;};

        id = mkOption {
          type = types.str;
          description = "Chrome Web Store extension id";
        };

        description = mkOption {
          type = types.str;
          default = "";
          description = "One-line summary of what this extension does.";
        };
      };
    }));
    default = {};
    description = ''
      Chromium extensions shared across Chromium-based browser modules
      (brave today). Every enabled entry is installed by each consuming
      browser; hosts opt out of one with
      `browser.extensions.chromium.<name>.enable = false`.
    '';
  };
}
