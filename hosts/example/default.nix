# A made-up MacBook: which apps it runs and how they are set up. ./flake.nix builds it the way a
# real flake would, and this repo's flake builds it as the framework's test (`nix run .#test example`).
{
  config,
  me,
  pkgs,
  ...
}: let
  apps = config.applications;
in {
  networking = {
    hostName = "example-mbp";
    computerName = "Example MacBook Pro";
  };

  identity = {
    name = "Example User";
    email = "example@example.com";
  };

  secrets.backend = "op";

  applications = {
    # zsh, starship, fzf, zoxide, tmux, git, jj and the other CLI basics are on by default.
    fzf.searchPaths = ["$HOME/code/" "$HOME/Documents/"];
    wezterm = {
      enable = true;
      # wezsesh loads from a local checkout of its repo, which this machine doesn't have.
      wezsesh.enable = false;
    };

    claude-code = {
      enable = true;
      managedSettings.permissions.allow = ["Bash(nix flake check:*)"];
    };
    devenv.enable = true;
    docker = {
      enable = true;
      # Stays on Docker 29 when nixpkgs-unstable moves `docker` to the next major version.
      package = pkgs.docker_29;
    };
    github-cli.enable = true;
    neovim = {
      enable = true;
      go.enable = true;
      python.enable = true;
      rust.enable = true;
      terraform.enable = true;
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

    _1password = {
      enable = true;
      browserExtension.enable = true;
    };
    brave.enable = true;
    discord.enable = true;
    raycast.enable = true;
    slack = {
      enable = true;
      mcp.enable = true;
    };
    spotify.enable = true;
    tailscale.enable = true;
    zoom.enable = true;

    aerospace = {
      enable = true;
      settings = {
        gaps = {
          inner.horizontal = 8;
          inner.vertical = 8;
          outer.left = 8;
          outer.right = 8;
          outer.top = 8;
          outer.bottom = 8;
        };
        mode.main.binding = {
          alt-h = "focus left";
          alt-j = "focus down";
          alt-k = "focus up";
          alt-l = "focus right";
          alt-shift-h = "move left";
          alt-shift-j = "move down";
          alt-shift-k = "move up";
          alt-shift-l = "move right";
          alt-slash = "layout tiles horizontal vertical";
          alt-comma = "layout accordion horizontal vertical";
          alt-f = "fullscreen";
          alt-tab = "workspace-back-and-forth";
          alt-1 = "workspace 1";
          alt-2 = "workspace 2";
          alt-3 = "workspace 3";
          alt-4 = "workspace 4";
          alt-shift-1 = "move-node-to-workspace 1";
          alt-shift-2 = "move-node-to-workspace 2";
          alt-shift-3 = "move-node-to-workspace 3";
          alt-shift-4 = "move-node-to-workspace 4";
        };
        # bundleId is set even for apps that are turned off, so rules never hardcode app ids.
        on-window-detected =
          map (rule: {
            "if".app-id = apps.${rule.app}.bundleId;
            run = "move-node-to-workspace ${rule.workspace}";
          }) [
            {
              app = "wezterm";
              workspace = "1";
            }
            {
              app = "brave";
              workspace = "2";
            }
            {
              app = "slack";
              workspace = "3";
            }
            {
              app = "discord";
              workspace = "3";
            }
            {
              app = "spotify";
              workspace = "4";
            }
          ];
      };
    };
  };

  ai = {
    # Becomes ~/.claude/CLAUDE.md on this machine.
    context = ''
      # Machine notes
      - Code lives in ~/code/<org>/<repo>.
      - Use `jj` in repositories that have a `.jj` directory.
    '';
    rules.small-commits.text = ''
      Keep each commit to one change, and write the subject line in the imperative mood.
    '';
    # A shared skill this machine doesn't need.
    skills.css-style-position.enable = false;
    mcpServers = {
      docs.url = "https://mcp.example.com/mcp";
      # Only the 1Password reference is stored; the token is read when the server starts.
      issue-tracker = {
        command = "/Users/${me.user}/.local/bin/issue-tracker-mcp";
        args = ["serve"];
        env.API_TOKEN.secret = "op://Work/issue-tracker/api-token";
        description = "Issue tracker: search and update tickets";
      };
    };
    hooks.notify-when-done = {
      event = "Stop";
      script = ''
        #!/usr/bin/env bash
        osascript -e 'display notification "Waiting for you" with title "Claude Code"'
      '';
      description = "macOS notification when Claude Code finishes a turn";
    };
  };

  system.defaults.dock.persistent-apps = [
    apps.wezterm.path
    apps.brave.path
    apps.slack.path
    apps.spotify.path
  ];
}
