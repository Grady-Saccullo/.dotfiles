{lib, ...}: {
  imports = [./azure-vpn.nix];
  options = {
    applications.azure = {
      enable = lib.mkEnableOption "Azure";
    };
  };
}
