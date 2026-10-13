# User shell and CLI environment: fish, bash, aliases, btop, fastfetch
{ ... }:

{
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
    NH_SUDO_ASKPASS = "/run/current-system/sw/bin/ksshaskpass";
    SSH_ASKPASS = "/run/current-system/sw/bin/ksshaskpass";
    SSH_ASKPASS_REQUIRE = "prefer";
  };

  home.shellAliases = {
    amdgpu-reset = "sudo -A cat /sys/kernel/debug/dri/1/amdgpu_gpu_recover";
    mesa-vk-trace = "touch /tmp/mesa_vk_trace_trigger";
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
      # Load unmanaged user secrets if present (supports KEY=VALUE and export KEY=VALUE)
      set -l secrets_file "$HOME/.config/secrets.env"
      if set -q XDG_CONFIG_HOME; and test -n "$XDG_CONFIG_HOME"
        set secrets_file "$XDG_CONFIG_HOME/secrets.env"
      end
      if test -f "$secrets_file"
        for line in (cat "$secrets_file" | string match -r "^(export\\s+)?[^#\\s=]+=[^\\n]*")
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
      secrets_file="''${XDG_CONFIG_HOME:-$HOME/.config}/secrets.env"
      if [ -f "$secrets_file" ]; then
        set -a
        source "$secrets_file"
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
