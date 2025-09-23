{lib, ...}: {
  imports = [./claude-code.nix];
  options = {
    applications.ai = {
      enable = lib.mkEnableOption "ai";
    };
  };
}
