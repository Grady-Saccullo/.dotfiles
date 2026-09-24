{
  lib,
  me,
  machineType,
  ...
}: rec {
  mkHomeManagerUser = mod: {
    home-manager.users.${me.user} = mod;
  };

  # Helpers for `attrsOf submodule` buses such as `ai.*` (see
  # modules/ai/README.md):
  #   enabled  — keep only entries with `enable = true`
  #   content  — pick whichever of `source` / `text` an entry set
  enabled = attrs: lib.filterAttrs (_: v: v.enable) attrs;
  content = entry:
    if entry.source != null
    then entry.source
    else entry.text;

  # Helpers for consumers of the `secrets.*` bus (see modules/secrets/README.md).
  secrets = {
    # Wraps `command args...` in a script that resolves each `VAR = ref` in
    # `secretEnv` through `readCommand` when the script RUNS, exports the
    # results, then execs the real program with any extra arguments appended.
    # `ref` is a string (one trailing argument) or a list of strings (passed
    # verbatim). Only the references reach the Nix store, never the values.
    #
    #   utils.secrets.mkEnvWrapper {
    #     inherit pkgs;
    #     name = "ai-mcp-my-server";              # -> secret-env-ai-mcp-my-server
    #     readCommand = config.secrets.readCommand;
    #     secretEnv.DATABASE_URL = "op://Vault/item/field";
    #     command = "/path/to/my-server";
    #     args = ["serve"];
    #   }
    mkEnvWrapper = {
      pkgs,
      name,
      readCommand,
      secretEnv,
      command,
      args ? [],
    }:
      pkgs.writeShellScript "secret-env-${name}" ''
        set -eu
        export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin:/run/current-system/sw/bin"
        ${lib.concatStrings (lib.mapAttrsToList (var: ref: ''
            if ${var}=$(${lib.escapeShellArgs (readCommand ++ lib.toList ref)}); then
              export ${var}
            else
              echo "${name}: failed to read secret for ${var}" >&2
              exit 1
            fi
          '')
          secretEnv)}
        exec ${lib.escapeShellArgs ([command] ++ args)} "$@"
      '';
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

  # Like mkAppModule, but the config function only returns `programs.neovim`
  # for the home-manager user. `extraConfig` (cfg -> darwin-level attrset)
  # lets a language module set options outside programs.neovim as well, e.g.
  # contribute `ai.lspServers.<lang>` to the AI bus; it is merged alongside
  # the home-manager block and defaults to nothing.
  mkNeovimModule = {
    path,
    config,
    pkgs,
    extraOptions ? {},
    default ? false,
    imports ? [],
    extraConfig ? (_: {}),
  }: neovimConfigFn:
    mkAppModule {
      inherit config extraOptions default imports;
      path = ["neovim"] ++ (pathList path);
    } (cfg:
      lib.mkMerge [
        (mkHomeManagerUser {
          programs.neovim = neovimConfigFn {
            inherit cfg;
            vimPlugins = pkgs.vimPlugins;
          };
        })
        (extraConfig cfg)
      ]);
}
