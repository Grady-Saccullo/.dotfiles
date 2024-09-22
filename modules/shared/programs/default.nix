# pull in all configs
{...}: {
  # TODO: create helper func to just map over folder and get all files expect for default.nix
  imports = [
    ./direnv.nix
    ./git.nix
    ./neovim
    ./tmux
    ./wezterm
    ./zsh.nix
  ];
}
