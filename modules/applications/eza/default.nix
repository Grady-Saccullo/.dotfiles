{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "eza";
  inherit config;
  default = true;
} (cfg:
    utils.mkHomeManagerUser {
      programs.eza = {
        enable = true;
        git = true;
        enableZshIntegration = config.applications.zsh.enable;
        extraOptions = [
          "--group-directories-first"
          "--header"
        ];
      };

      home.sessionVariables = {
        EZA_CONFIG_DIR = "${pkgs.runCommand "eza-config" {} ''
          mkdir -p $out
          cp ${./eza-theme.yaml} $out/theme.yml
        ''}";
      };
    })
