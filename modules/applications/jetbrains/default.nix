{lib, ...}: {
  imports = [
    ./data-grip.nix
    ./idea.nix
    ./rider.nix
  ];
  options = {
    applications.jetbrains = {
      enable = lib.mkEnableOption "JetBrains";
    };
  };
}
