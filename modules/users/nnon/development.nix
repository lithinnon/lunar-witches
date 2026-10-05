# User developer tools: VS Code, Git, GPG, SSH
{ pkgs, osConfig, ... }:

{
  programs.vscode = {
    enable = true;
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
      };
      extensions = with pkgs.vscode-extensions; [
        arrterian.nix-env-selector
        divyanshuagrawal.competitive-programming-helper
        jnoortheen.nix-ide
        vscode-icons-team.vscode-icons
        usernamehw.errorlens
      ];
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
      };
      "white" = {
        HostName = "10.10.0.7";
        IdentityFile = "~/.ssh/other-keys/DESKTOP-E3G9LEN/id_ed25519";
      };
      "i2cedt-2" = {
        HostName = "ec2-3-94-117-168.compute-1.amazonaws.com";
        User = "ubuntu";
      };
    };
  };

  programs.git = {
    enable = true;
    signing = {
      key = osConfig.users.nnon.gitSigningKey;
      signByDefault = true;
    };
    settings = {
      user = {
        name = "lithinnon";
        email = "49898465+lithinnon@users.noreply.github.com";
      };
      init.defaultBranch = "master";
      safe.directory = "*";
    };
  };

  programs.gpg = {
    enable = true;
    mutableKeys = true;
    mutableTrust = true;
    settings = {
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      cert-digest-algo = "SHA512";
      s2k-digest-algo = "SHA512";
      s2k-cipher-algo = "AES256";
      charset = "utf-8";
      no-comments = true;
      no-emit-version = true;
      no-greeting = true;
      keyid-format = "0xlong";
      with-fingerprint = true;
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      use-agent = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableScDaemon = true;
    pinentry.package = pkgs.pinentry-qt;
    defaultCacheTtl = 3600;
    maxCacheTtl = 86400;
  };

  programs.pi-coding-agent.enable = true;
  programs.pi-coding-agent.extraPackages = [
    pkgs.nodejs
    pkgs.bun
  ];
}
