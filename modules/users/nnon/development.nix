# User developer tools: VS Code, Git, GPG, SSH, MCP servers
{ pkgs, osConfig, ... }:

{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;
    argvSettings = {
      "password-store" = "gnome-libsecret";
    };
    profiles.default = {
      userSettings = {
        "files.autoSave" = "afterDelay";
        "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font Mono'";
        "terminal.integrated.cursorBlinking" = true;
        "terminal.integrated.enableImages" = true;
        "terminal.integrated.mouseWheelZoom" = true;
        "terminal.integrated.smoothScrolling" = true;
        "editor.mouseWheelZoom" = true;
        "workbench.iconTheme" = "vscode-icons";
        "terminal.integrated.gpuAcceleration" = "off";
        "redhat.telemetry.enabled" = false;
        "terminal.integrated.fontSize" = 13;
        "editor.formatOnSave" = true;
        "terminal.integrated.enableMultiLinePasteWarning" = "never";
        "chat.disableAIFeatures" = true;
        "workbench.settings.showAISearchToggle" = false;
        "godotTools.lsp.serverPort" = 6005;
        "godotTools.editorPath.godot4" = "${pkgs.godot_4}/bin/godot";
        "cedtGrader.baseUrl" = "https://cedt-grader.nattee.net";
        "cedtGrader.username" = "6933200721";
      };
      extensions = with pkgs.vscode-extensions; [
        mkhl.direnv
        divyanshuagrawal.competitive-programming-helper
        jnoortheen.nix-ide
        vscode-icons-team.vscode-icons
        usernamehw.errorlens
        llvm-vs-code-extensions.vscode-clangd
        tamasfe.even-better-toml
        fill-labs.dependi
        rust-lang.rust-analyzer
        myriad-dreamin.tinymist
        geequlim.godot-tools
        pkgs.vscode-marketplace.badvoic3.cedt-grader-submit
        pkgs.vscode-marketplace.anthropic.claude-code
      ];
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "~/.ssh/config.d/*"
    ];
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        IdentityFile = [
          "~/.ssh/id_ed25519_sk"
          "~/.ssh/id_ed25519"
        ];
      };
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    ignores = [
      ".direnv"
    ];
    signing = {
      format = "ssh";
      key = "~/.ssh/id_ed25519_sk.pub";
      signByDefault = true;
    };
    settings = {
      user = {
        name = "lithinnon";
        email = "49898465+lithinnon@users.noreply.github.com";
      };
      gpg.ssh = {
        allowedSignersFile = "~/.ssh/allowed_signers";
      };
      init.defaultBranch = "master";
      safe.directory = "*";
      lfs = {
        concurrenttransfers = 8;
      };
      "lfs \"customtransfer.xet\"" = {
        path = "git-xet";
        args = "transfer";
        concurrent = true;
      };
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  services.gpg-agent.enable = false;

  # Cross-harness agent-skills CLI (SKILL.md installer) — nixpkgs `skills`
  # (vercel-labs/skills): `skills add owner/repo`, `skills use`, `skills init`.
  home.packages = with pkgs; [
    git-xet
    skills
  ];

  # MCP server registry at ~/.config/mcp/mcp.json — the "generic global"
  # source read by pi's mcp-adapter (and other MCP-aware clients). The
  # `mcp-nixos` binary itself ships via suite-ai-antigravity (pkgs.mcp-nixos).
  # Declarative on purpose: the adapter's interactive setup panel resolves
  # symlinks before writing, so it cannot mutate this file — add servers here.
  home.file.".config/mcp/mcp.json".text = builtins.toJSON {
    mcpServers = {
      nixos.command = "mcp-nixos";
    };
  };
}
