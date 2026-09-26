# Synthetic host: not a real machine. It exists so `nix run .#test example`
# type-checks the whole module set and so readers can see how a host is
# written. Real hosts live in flakes that consume this one; see README
# "Setting up your own machines".
#
# The framework (sensible, home-manager, applications and the option buses)
# is supplied by `lib.mkDarwinHost` in flake.nix; a host module holds only
# the machine's choices.
{
  config,
  pkgs,
  ...
}: {
  # Read by every tool that attributes work to the user (git, jj, ...).
  identity = {
    name = "Example User";
    email = "example@example.com";
  };

  # CLI that resolves `{ secret = ...; }` references when a program starts,
  # never at build time. `op` is the 1Password CLI; `rbw` / `bw` are the
  # Bitwarden ones. See modules/secrets/README.md.
  secrets.backend = "op";

  # A host can feed the ai.* bus directly: a rule and a remote MCP server.
  ai.rules.example.text = "Prefer small, reviewable commits.";
  ai.mcpServers.example = {url = "https://example.com/mcp";};

  applications = {
    aerospace = {
      enable = true;
      settings = {
        gaps = {
          inner.horizontal = 4;
          inner.vertical = 4;
          outer.left = 4;
          outer.right = 4;
          outer.top = 4;
          outer.bottom = 4;
        };
        mode.main.binding = {
          alt-h = "focus left";
          alt-j = "focus down";
          alt-k = "focus up";
          alt-l = "focus right";
          alt-1 = "workspace 1";
          alt-2 = "workspace 2";
          alt-3 = "workspace 3";
        };
        # Bundle ids come from each app module (declared regardless of
        # `enable`), so rules never hardcode them.
        on-window-detected = [
          {
            "if" = {app-id = config.applications.wezterm.bundleId;};
            run = "move-node-to-workspace 1";
          }
        ];
      };
    };
    bitwarden = {
      enable = true;
      # Registers on the browser.* bus; brave installs it.
      browserExtension.enable = true;
    };
    brave.enable = true;
    claude-code.enable = true;
    # Swapping an app's build; the source reaches `pkgs` through mkDarwinHost's `channels` or
    # `overlays` (README "Choosing an app's version"). Commented out to keep the fixture on unstable.
    # cursor-editor.package = pkgs.channels.v26_05.code-cursor;
    # claude-code.package = pkgs.llm-agents.claude-code;
    discord.enable = true;
    docker.enable = true;
    github-cli.enable = true;
    neovim = {
      enable = true;
      go.enable = true;
      python.enable = true;
      rust.enable = true;
      typescript = {
        enable = true;
        lsp = "vtsls";
        tsx.enable = true;
      };
      dap = {
        enable = true;
        go.enable = true;
      };
    };
    raycast.enable = true;
    # Opt-in: publishes Slack's official remote MCP server on the ai.* bus.
    slack = {
      enable = true;
      mcp.enable = true;
    };
    spotify.enable = true;
    wezterm.enable = true;
    fzf.searchPaths = ["$HOME/code/"];
  };

  system.defaults.dock.persistent-apps = [
    config.applications.wezterm.path
    config.applications.brave.path
  ];
}
