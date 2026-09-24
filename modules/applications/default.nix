{...}: {
  imports = [
    # Cross-cutting buses (`ai.*`, `browser.*`, `identity.*`, `secrets.*`,
    # `shell.*`) must exist whenever application modules exist: they contribute
    # to and read from them.
    ../ai
    ../browser
    ../identity
    ../secrets
    ../shell
    ./1password
    ./aerospace
    ./android-studio
    ./bat
    ./betterdisplay
    ./bettersnaptool
    ./bitwarden
    ./brave
    ./btop
    ./charles-proxy
    ./claude-code
    ./cursor-editor
    ./devenv
    ./direnv
    ./discord
    ./docker
    ./eza
    ./fzf
    ./git
    ./github-cli
    ./halloy
    ./hoppscotch
    ./jetbrains
    ./jj
    ./jq
    ./neovim
    ./podman
    ./raycast
    ./ripgrep
    ./slack
    ./soundsource
    ./spotify
    ./starship
    ./steam
    ./tailscale
    ./tmux
    ./todoist
    ./utm
    ./wezterm
    ./xcode
    ./yazi
    ./zoom
    ./zoxide
    ./zsh
  ];
}
