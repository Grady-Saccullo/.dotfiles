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
    # What each `secrets.backend` runs to print one secret, given the reference as the last argument.
    readCommandFor = {
      op = ["op" "read" "--no-newline"];
      rbw = ["rbw" "get"];
      bw = ["bw" "get" "password" "--nointeraction"];
    };

    # A secrets hook (modules/secrets/README.md) that runs `readCommand <ref>` once per reference.
    mkReadCommandHook = {
      pkgs,
      readCommand,
    }:
      pkgs.writeShellScriptBin "secrets-read-command-hook" ''
        PATH=${lib.makeBinPath [pkgs.jq]}:$PATH
        exec ${pkgs.bash}/bin/bash -e ${../secrets/read-command-hook.sh} ${lib.escapeShellArgs readCommand}
      '';

    # Wraps `command args...` in a script that asks `hook` for every `VAR = ref` in `secretEnv` in one
    # call when it RUNS, exports the values and execs the program. Only the references reach the store.
    # `readCommand` stands in for `hook` through mkReadCommandHook. See modules/secrets/README.md.
    mkEnvWrapper = {
      pkgs,
      name,
      hook ? null,
      readCommand ? [],
      secretEnv,
      command,
      args ? [],
    }: let
      hook' =
        if hook != null
        then hook
        else if readCommand != []
        then secrets.mkReadCommandHook {inherit pkgs readCommand;}
        else throw "utils.secrets.mkEnvWrapper (${name}): set `hook` or `readCommand`";
      jq = "${pkgs.jq}/bin/jq";
      request = builtins.toJSON {
        version = 1;
        purpose = "runtime:${name}";
        refs = secretEnv;
      };
    in
      pkgs.writeShellScript "secret-env-${name}" ''
        set -eu
        export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin:/run/current-system/sw/bin"
        interactive=false
        if [ -t 0 ] && [ -t 2 ]; then interactive=true; fi
        request=$(printf '%s' ${lib.escapeShellArg request} | ${jq} -c --argjson i "$interactive" '.interactive = $i')
        if ! response=$(printf '%s' "$request" | ${lib.getExe hook'}); then
          echo "${name}: the secrets hook failed" >&2
          exit 1
        fi
        ${lib.concatStrings (lib.mapAttrsToList (var: _: ''
            if ${var}=$(printf '%s' "$response" | ${jq} -je --arg k ${var} '.[$k] | strings'); then
              export ${var}
            else
              echo "${name}: failed to read secret for ${var}" >&2
              exit 1
            fi
          '')
          secretEnv)}
        unset response
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
