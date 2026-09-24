{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.identity = {
    name = mkOption {
      type = types.str;
      default = "Grady Saccullo";
      example = "Jane Doe";
      description = ''
        Full name attached to work the user produces. Read by
        `applications.git` (`user.name`) and `applications.jj` (`user.name`);
        later by gh and the AI user-level context. Hosts override it in
        their host module.
      '';
    };

    email = mkOption {
      type = types.str;
      default = "gradys.dev@gmail.com";
      example = "jane@example.com";
      description = ''
        Email address attached to work the user produces. Read by
        `applications.git` (`user.email`) and `applications.jj`
        (`user.email`); later by gh and the AI user-level context. Hosts
        override it in their host module, e.g. a work host setting its work
        address.
      '';
    };
  };
}
