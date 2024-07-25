{config, ...}: let
  mkSource = p: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/${p}";
in {
  "work".source = mkSource "repos/work";
  "personal".source = mkSource "repos/personal";
  "krinkle".source = mkSource "repos/krinkle";
}
