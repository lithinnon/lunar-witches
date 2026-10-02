# User shell and CLI environment: fish, bash, aliases, btop, fastfetch
{ ... }:

{
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
    NH_SUDO_ASKPASS = "/run/current-system/sw/bin/ksshaskpass";
    SSH_ASKPASS_REQUIRE = "prefer";
  };

  home.shellAliases = {
    amdgpu-reset = "sudo -A cat /sys/kernel/debug/dri/1/amdgpu_gpu_recover";
    mesa-vk-trace = "touch /tmp/mesa_vk_trace_trigger";
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
  };

  programs.fish = {
    enable = true;
    shellInit = ''
      # Load unmanaged user secrets if present (supports KEY=VALUE and export KEY=VALUE)
      if test -f "$HOME/.config/secrets.env"
        for line in (cat "$HOME/.config/secrets.env" | string match -r "^(export\\s+)?[^#\\s=]+=[^\\n]*")
          set -l clean (string replace -r "^export\\s+" "" $line)
          set -l kv (string split -m 1 = $clean)
          if test (count $kv) -eq 2
            set -l val (string trim -c "\"'" "$kv[2]")
            set -gx $kv[1] $val
          end
        end
      end
    '';
    interactiveShellInit = ''
      set -g fish_greeting
    '';
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      # Load unmanaged user secrets if present
      if [ -f "$HOME/.config/secrets.env" ]; then
        set -a
        source "$HOME/.config/secrets.env"
        set +a
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
      color_theme = "Default";
      theme_background = true;
      update_ms = 2000;
      shown_boxes = "cpu mem net proc";
      proc_sorting = "cpu lazy";
      proc_colors = true;
      proc_gradient = true;
      proc_mem_bytes = true;
      proc_cpu_graphs = true;
      show_uptime = true;
      show_cpu_watts = true;
      check_temp = true;
      show_coretemp = true;
      show_cpu_freq = true;
      show_swap = true;
      swap_disk = true;
      show_battery = true;
      show_battery_watts = true;
      gpu_mirror_graph = true;
      rsmi_measure_pcie_speeds = true;
      shown_gpus = "nvidia amd intel apple";
    };
  };
}
