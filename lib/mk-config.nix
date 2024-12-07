{
  nixpkgs,
  overlays,
  inputs,
  ...
}: systemConfig:
# TODO refactor this. much of this can be reused/simplified, but it works for now while figuring out multiple systems
let
  mkSystemModules = import ./mk-system-modules.nix {inherit nixpkgs overlays inputs;};
  machine-module = import ../modules/${systemConfig.module}/machine-${systemConfig.machine}.nix;

  isPlatform = p: nixpkgs.lib.strings.hasInfix p systemConfig.machine;

  buildSystem = hm-modules:
    mkSystemModules {
      inherit systemConfig;
      extra-modules =
        [
          machine-module
        ]
        ++ hm-modules;
    };

  hm-extras = {
    imports =
      if isPlatform "darwin"
      then [
        inputs.mac-app-util.homeManagerModules.default
      ]
      else [];
  };

  hm-module-config = import ../modules/${systemConfig.module}/home-manager.nix hm-extras;
  hm-config = {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${systemConfig.user} = hm-module-config;
  };

  built-config =
    if isPlatform "darwin"
    then let
      system = buildSystem [
        (inputs.mac-app-util.darwinModules.default)
        (inputs.nix-homebrew.darwinModules.nix-homebrew)
        (inputs.mac-app-util.darwinModules.default)
        (inputs.home-manager.darwinModules.home-manager)
        hm-config
      ];
    in
      inputs.darwin.lib.darwinSystem system
    else if isPlatform "nixos"
    then let
      system = buildSystem [
        (inputs.home-manager.nixosModules.home-manager)
        hm-config
      ];
    in
      nixpkgs.lib.nixosSystem system
    else buildSystem [hm-module-config];
in
  built-config
