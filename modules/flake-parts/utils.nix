{
  lib,
  me,
  machineType,
  ...
}: {
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
}
