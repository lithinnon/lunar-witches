# User shell and CLI environment: fish, bash, aliases, btop, fastfetch
{ config, ... }:

{
  home.sessionPath = [
    "$HOME/.local/bin"
    "${config.xdg.dataHome}/cargo/bin"
  ];

  home.sessionVariables = {
    NH_SUDO_ASKPASS = "/run/current-system/sw/bin/ksshaskpass";
    SSH_ASKPASS = "/run/current-system/sw/bin/ksshaskpass";
    SSH_ASKPASS_REQUIRE = "prefer";

    # XDG Base Directory conformances
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    DOTNET_CLI_HOME = "${config.xdg.dataHome}/dotnet";
    CODEX_HOME = "${config.xdg.configHome}/codex";
    TRITON_HOME = "${config.xdg.cacheHome}/triton";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python_history";
    GTK2_RC_FILES = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";
  };

  home.shellAliases = {
    wget = "wget --hsts-file=${config.xdg.dataHome}/wget-hsts";
    mesa-vk-trace = "touch /tmp/mesa_vk_trace_trigger; sleep 0.5; rm -f /tmp/mesa_vk_trace_trigger";
    plasma-menu-restart = "systemctl --user restart plasma-plasmashell.service";
    ".." = "cd ..";
    "..." = "cd ...";
    cls = "clear";
    vi = "nvim";
    vim = "nvim";
    g = "git";
    cp = "cp -i";
    mv = "mv -i";
    gq = "ghq get --update -p --look --parallel";
    setup-optiscaler = "chmod +x ./setup_linux.sh && ./setup_linux.sh";
    nix-agent-pi = "cd ~/lunar-witches;pi --session 01a10a7f-7d9a-753c-9b68-372aa214bb10";
    nix-agent-agy = "cd ~/lunar-witches;agy --conversation=f73d4a6a-84c7-4614-9114-d72055951b42";
  };

  programs.fish = {
    enable = true;
    shellInit = ''
      # Load managed sops secrets
      if test -f /run/secrets/hf_token
        set -gx HF_TOKEN (cat /run/secrets/hf_token)
      end
    '';
    interactiveShellInit = ''
      set -g fish_greeting
    '';
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      # Load managed sops secrets
      if [ -f /run/secrets/hf_token ]; then
        export HF_TOKEN="$(cat /run/secrets/hf_token)"
      fi
    '';
  };

  programs.fastfetch = {
    enable = true;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json";
      logo = {
        type = "auto";
        source = "/home/nnon/Documents/Stella Glow/Marie-Eve Assets/LINE Stickers/Marie/4x/Neutral.png";
        width = 32;
      };
      modules = [
        "title"
        "separator"
        "os"
        "host"
        "kernel"
        "uptime"
        "packages"
        "shell"
        "display"
        "de"
        "wm"
        "wmtheme"
        "theme"
        "icons"
        "font"
        "cursor"
        "terminal"
        "terminalfont"
        "cpu"
        "gpu"
        "memory"
        "swap"
        "disk"
        "localip"
        "battery"
        "poweradapter"
        "locale"
        "break"
        "colors"
      ];
    };
  };

  programs.btop = {
    enable = true;
    settings = {
      update_ms = 2000;
      proc_sorting = "cpu lazy";
      proc_colors = true;
      proc_gradient = true;
      proc_mem_bytes = true;
      proc_cpu_graphs = true;
      show_uptime = true;
      show_cpu_watts = true;
      show_coretemp = true;
      show_cpu_freq = true;
      show_swap = true;
      swap_disk = true;
      show_battery = true;
      show_battery_watts = true;
      gpu_mirror_graph = true;
      rsmi_measure_pcie_speeds = true;
    };
  };
}
