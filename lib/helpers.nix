{nixpkgs}: let
  mkSystemConfig = {
    system,
    module,
    machine,
    user,
  }: {
    system = system;
    module = module;
    machine = machine;
    user = user;
  };

  configShortName = cfg: "${cfg.module}-${cfg.machine}";

  genSystemConfig = systems: make: let
    systemInfo =
      map (cfg: {
        shortName = configShortName cfg;
        config = cfg;
      })
      systems;

    systemByName = nixpkgs.lib.listToAttrs (map (
        item: {
          name = item.shortName;
          value = item.config;
        }
      )
      systemInfo);

    allNames = builtins.attrNames systemByName;

    findConfig = name: let
      matches = builtins.filter (s: s.shortName == name) systemInfo;
    in
      if builtins.length matches > 0
      then (builtins.head matches).config
      else throw "No configuration found for ${name}";
  in
    nixpkgs.lib.genAttrs allNames (
      name: let cfg = findConfig name; in make cfg
    );
in {
  inherit mkSystemConfig genSystemConfig;
}
