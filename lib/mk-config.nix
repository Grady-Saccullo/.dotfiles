{
  nixpkgs,
  overlays,
  inputs,
  ...
}: systemConfig:
# TODO refactor this. much of this can be reused/simplified, but it works for now while figuring out multiple systems
let
  mkSystemModules = import ./mk-system-modules.nix {inherit nixpkgs overlays inputs;};
  machine-module = import ../modules/${systemConfig.configType}/machine-${systemConfig.configName}.nix;

  home-manager-config = import ../modules/${systemConfig.configType}/home-manager.nix;

  isPlatform = p: nixpkgs.lib.strings.hasInfix p systemConfig.configName;

  buildSystem = hm-modules:
    mkSystemModules {
      inherit systemConfig;
      extra-modules =
        [
          machine-module
        ]
        ++ hm-modules;
    };

  built-config =
    if isPlatform "darwin"
    then let
      system = buildSystem [
        (inputs.home-manager.darwinModules.home-manager)
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${systemConfig.user} = home-manager-config;
        }
      ];
    in
      inputs.darwin.lib.darwinSystem system
    else if isPlatform "nixos"
    then let
      system = buildSystem [
        (inputs.home-manager.nixosModules.home-manager)
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${systemConfig.user} = home-manager-config;
        }
      ];
    in
      nixpkgs.lib.nixosSystem system
    else buildSystem [home-manager-config];
in
  built-config
