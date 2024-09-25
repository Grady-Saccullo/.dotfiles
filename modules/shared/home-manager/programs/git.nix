{
  pkgs,
  ...
}: {
  programs = {
    git = {
      enable = true;
      package = pkgs.gitFull;

      lfs = {
        enable = true;
      };

      delta = {
        enable = true;
      };
    };
  };
}
