{
  pkgs,
  me,
  inputs,
  ...
}: let
  inherit (inputs) self;
in {
  users.users.${me.user} = {
    home = "/home/${me.user}";
    shell = pkgs.zsh;
    extraGroups = ["wheel"];
  };

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
    };
  };

  environment.shells = with pkgs; [bashInteractive zsh];

  system = {
    stateVersion = self.constants.darwinStateVersion;
  };
}
