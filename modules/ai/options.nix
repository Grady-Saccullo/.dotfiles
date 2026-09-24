{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkEnableOption types;

  jsonFormat = pkgs.formats.json {};

  # Shared shape for file-like content (skills, agents, commands, rules).
  # Exactly one of `source` / `text` must be set on an enabled entry; the
  # assertion lives in ./default.nix. A skill `source` is a directory holding
  # SKILL.md (or a SKILL.md file); the others are single markdown files.
  mkContentType = kind:
    types.attrsOf (types.submodule ({name, ...}: {
      options = {
        enable =
          mkEnableOption "the ${name} ${kind}"
          // {default = true;};

        source = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = ''
            Path to the ${kind} content. Mutually exclusive with `text`.
          '';
        };

        text = mkOption {
          type = types.nullOr types.lines;
          default = null;
          description = ''
            Inline ${kind} content. Mutually exclusive with `source`.
          '';
        };

        description = mkOption {
          type = types.str;
          default = "";
          description = "One-line summary of what this ${kind} does.";
        };
      };
    }));

  # Env value for an MCP server: a literal string, a file reference read at
  # server start, or a secret reference resolved through
  # `secrets.readCommand` (modules/secrets) at server start. Exactly one of
  # `file` / `secret` must be set when the attrset form is used (asserted in
  # ./mcp.nix).
  envValueType = types.either types.str (types.submodule {
    options = {
      file = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Path to a file whose contents become the variable's value. Read
          when the server starts, so the value never enters the Nix store.
        '';
      };

      secret = mkOption {
        type = types.nullOr (types.either types.str (types.listOf types.str));
        default = null;
        example = "op://Vault/item/field";
        description = ''
          Reference passed to `secrets.readCommand` (see modules/secrets)
          when the server starts. A string is a single argument; a list is
          passed verbatim as arguments. Only the reference is stored in the
          Nix store, never the resolved value.
        '';
      };
    };
  });

  mcpServerType = types.attrsOf (types.submodule ({name, ...}: {
    freeformType = jsonFormat.type;

    options = {
      enable =
        mkEnableOption "the ${name} MCP server"
        // {default = true;};

      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "npx";
        description = ''
          Executable for a local (stdio) MCP server. Mutually exclusive
          with `url`.
        '';
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Arguments passed to `command`. Local servers only.";
      };

      env = mkOption {
        type = types.attrsOf envValueType;
        default = {};
        example = lib.literalExpression ''
          {
            API_BASE_URL = "https://api.example.com";
            DATABASE_URL.secret = "op://Vault/item/database_url";
            TOKEN.file = "/run/secrets/token";
          }
        '';
        description = ''
          Environment for the server process. Each value is a literal
          string, a `{ file = ...; }` reference, or a `{ secret = ...; }`
          reference. Local servers only.
        '';
      };

      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "https://mcp.example.com/mcp";
        description = ''
          Endpoint for a remote (HTTP/SSE) MCP server. Mutually exclusive
          with `command`.
        '';
      };

      headers = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "HTTP headers sent to a remote server. Remote servers only.";
      };

      description = mkOption {
        type = types.str;
        default = "";
        description = "One-line summary of what this server provides.";
      };
    };
  }));

  # An LSP server exposed to AI tools. `command` must be an absolute store
  # path (e.g. "${pkgs.gopls}/bin/gopls"): the consuming tool is
  # launched from shells and GUIs whose PATH does not include neovim's
  # `extraPackages`. Extra keys (settings, initializationOptions, env, ...)
  # pass through to the tool untouched.
  lspServerType = types.attrsOf (types.submodule ({name, ...}: {
    freeformType = jsonFormat.type;

    options = {
      enable =
        mkEnableOption "the ${name} LSP server"
        // {default = true;};

      command = mkOption {
        type = types.str;
        example = lib.literalExpression ''"''${pkgs.gopls}/bin/gopls"'';
        description = ''
          Language server executable. Use an absolute store path such as
          `"''${pkgs.gopls}/bin/gopls"` so the tool finds it
          regardless of PATH; a bare binary name is not reliably resolved.
        '';
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["--stdio"];
        description = "Arguments passed to `command`.";
      };

      extensionToLanguage = mkOption {
        type = types.attrsOf types.str;
        default = {};
        example = {".go" = "go";};
        description = ''
          File extension (with leading dot) to LSP language identifier. The
          tool starts this server for files with these extensions. Only the
          first enabled server that claims an extension is started.
        '';
      };

      description = mkOption {
        type = types.str;
        default = "";
        description = "One-line summary of what this server provides.";
      };
    };
  }));
in {
  options.ai = {
    skills = mkOption {
      type = mkContentType "skill";
      default = {};
      description = ''
        Agent skills shared across AI tools. Each entry materialises as
        `skills/<name>/` in every consuming tool's config directory.
      '';
    };

    agents = mkOption {
      type = mkContentType "agent";
      default = {};
      description = ''
        Subagent definitions (markdown with frontmatter). Each entry
        materialises as `agents/<name>.md` in consuming tools.
      '';
    };

    commands = mkOption {
      type = mkContentType "command";
      default = {};
      description = ''
        Slash commands (markdown). Each entry materialises as
        `commands/<name>.md` in consuming tools.
      '';
    };

    rules = mkOption {
      type = mkContentType "rule";
      default = {};
      description = ''
        Rule files loaded as user-level memory. Each entry materialises as
        `rules/<name>.md` in consuming tools.
      '';
    };

    hooks = mkOption {
      type = types.attrsOf (types.submodule ({name, ...}: {
        options = {
          enable =
            mkEnableOption "the ${name} hook"
            // {default = true;};

          event = mkOption {
            type = types.str;
            example = "PreToolUse";
            description = ''
              Lifecycle event that triggers the hook (e.g. `PreToolUse`,
              `PostToolUse`, `SessionStart`). Kept as a plain string since
              the upstream event list changes often.
            '';
          };

          matcher = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "Edit|Write|MultiEdit";
            description = ''
              Tool-name pattern the hook applies to. `null` means every
              occurrence of `event`.
            '';
          };

          script = mkOption {
            type = types.either types.lines types.path;
            description = ''
              Hook body, inline or as a path. Installed executable as
              `hooks/<name>` in consuming tools.
            '';
          };

          timeout = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Seconds before the hook is killed. `null` uses the tool default.";
          };

          description = mkOption {
            type = types.str;
            default = "";
            description = "One-line summary of what this hook does.";
          };
        };
      }));
      default = {};
      description = ''
        Lifecycle hooks. Consuming tools install the script and wire it to
        `event` (optionally filtered by `matcher`).
      '';
    };

    # Plain attrset of list options (not attrsOf submodule): there is nothing
    # to name or disable per entry, and listOf already merges across modules.
    permissions = let
      ruleList = kind:
        mkOption {
          type = types.listOf types.str;
          default = [];
          example = ["Bash(git status:*)"];
          description = ''
            Claude Code permission rules contributed by modules for the
            `${kind}` list. Rendered into managed-settings.json
            `permissions.${kind}`; lists merge across modules.
          '';
        };
    in {
      allow = ruleList "allow";
      ask = ruleList "ask";
      deny = ruleList "deny";
    };

    plugins = mkOption {
      type = types.attrsOf (types.submodule ({name, ...}: {
        options = {
          enable =
            mkEnableOption "the ${name} plugin"
            // {default = true;};

          source = mkOption {
            type = types.either types.package types.path;
            description = ''
              Plugin directory (a path or a package/fetcher output). The
              attribute name becomes the plugin directory name.
            '';
          };

          description = mkOption {
            type = types.str;
            default = "";
            description = "One-line summary of what this plugin provides.";
          };
        };
      }));
      default = {};
      description = "Locally sourced plugins for consuming tools.";
    };

    context = mkOption {
      type = types.lines;
      default = "";
      description = ''
        User-level context (e.g. `~/.claude/CLAUDE.md`). Definitions from
        multiple modules are concatenated; use `lib.mkOrder` to control
        ordering. Empty means the file is left unmanaged.
      '';
    };

    mcpServers = mkOption {
      type = mcpServerType;
      default = {};
      description = ''
        MCP servers shared across AI tools. Fed into home-manager's
        `programs.mcp.servers` by ./mcp.nix; tools opt in with their own
        `enableMcpIntegration` flag.
      '';
    };

    lspServers = mkOption {
      type = lspServerType;
      default = {};
      description = ''
        LSP servers exposed to AI tools. The neovim language modules
        contribute one per enabled language, so Claude Code gets code
        intelligence for exactly the languages a host enables. Consumed by
        modules/applications/claude-code into home-manager's
        `programs.claude-code.lspServers`.
      '';
    };
  };
}
