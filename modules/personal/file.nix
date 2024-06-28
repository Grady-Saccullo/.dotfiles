{config, ...}: let
  mkSource = p: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/${p}";
in {
  "work-tmp".source = mkSource "repos/work";
  "personal-tmp".source = mkSource "repos/personal";
}
