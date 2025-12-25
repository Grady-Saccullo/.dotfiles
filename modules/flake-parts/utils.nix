{
  lib,
  me,
  machineType,
  ...
}: rec {
  mkHomeManagerUser = mod: {
    home-manager.users.${me.user} = mod;
  };

  mkPlatformConfig = {
    base ? {},
    nixos ? {},
    darwin ? {},
    linux ? {},
  }: let
    isDarwin = machineType == "darwin";
    isLinux = machineType == "linux";
    isNixOS = machineType == "nixos";

    evalConfig = platform: cfg:
      if platform
      then
        if builtins.isAttrs cfg
        then cfg
        else if builtins.isString cfg
        then throw cfg
        else throw "must be of type attr or error string"
      else {};
  in
    lib.mkMerge [
      base
      (evalConfig isDarwin darwin)
      (evalConfig isNixOS nixos)
      (evalConfig isLinux linux)
    ];

  allEnable = root: checks: let
    checkEnabled = path: let
      getPath = lib.attrByPath (lib.splitString "." path) false root;
    in
      getPath;
  in
    lib.all checkEnabled checks;

  pathList = path:
    if builtins.isString path
    then lib.splitString "." path
    else path;

  # Creates an application module with consistent structure
  # Handles both top-level and nested modules
  #
  # Usage:
  #   { utils, config, ... }: utils.mkAppModule {
  #     # path as string or list: "zsh" or ["neovim" "go" "templ"]
  #     path = "zsh";
  #     inherit config;
  #     # optional extra options (in addition to enable)
  #     extraOptions = { package = lib.mkOption {...}; };
  #     # set to true to enable by default (only for top-level apps)
  #     default = false;
  #     # config function receives cfg (this module's config)
  #     configFn = cfg: utils.mkHomeManagerUser { ... };
  #   }
  #
  # For nested paths like ["neovim", "go", "templ"], this will:
  #   - Create options at applications.neovim.go.templ.enable
  #   - Check all parent enables: neovim.enable, neovim.go.enable, neovim.go.templ.enable
  mkAppModule = {
    path,
    config,
    extraOptions ? {},
    default ? false,
    imports ? [],
  }: configFn: let
    # Convert string path to list if needed
    paths = pathList path;

    # Build the enable checks for allEnable
    # ["neovim", "go", "templ"] -> ["enable", "go.enable", "go.templ.enable"]
    buildEnableChecks = parts: let
      indices = lib.range 0 (builtins.length parts - 1);
      makePath = idx:
        if idx == 0
        then "enable"
        else lib.concatStringsSep "." (lib.sublist 1 idx parts) + ".enable";
    in
      map makePath indices;

    enableChecks = buildEnableChecks paths;

    # Get the root config for allEnable (e.g., config.applications.neovim)
    rootName = builtins.head paths;
    rootConfig = config.applications.${rootName};

    # Get this module's config
    cfg = lib.attrByPath paths {} config.applications;

    # Check all enables
    enable = allEnable rootConfig enableChecks;

    # Build nested options structure
    buildNestedOptions = parts: opts:
      lib.setAttrByPath parts opts;

    # Enable option with optional default
    enableOption =
      (lib.mkEnableOption (lib.concatStringsSep " / " paths))
      // lib.optionalAttrs default {default = true;};
  in {
    inherit imports;
    options.applications = buildNestedOptions paths (
      {enable = enableOption;} // extraOptions
    );

    config = lib.mkIf enable (configFn cfg);
  };

  mkNeovimModule = {
    path,
    config,
    pkgs,
    extraOptions ? {},
    default ? false,
    imports ? [],
  }: neovimConfigFn:
    mkAppModule {
      inherit config extraOptions default imports;
      path = ["neovim"] ++ (pathList path);
    } (cfg:
      mkHomeManagerUser {
        programs.neovim = neovimConfigFn {
          inherit cfg;
          vimPlugins = pkgs.unstable.vimPlugins;
        };
      });
}
