{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  inherit config;
  path = "zsh";
  default = true;
} (cfg:
    utils.mkHomeManagerUser {
      programs.zsh = {
        enable = true;
        shellAliases = {
          l = "ls -la";
          cl = "clear";
          "~" = "cd ~";
          "--" = "cd -";
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
        };
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
      };
    })
