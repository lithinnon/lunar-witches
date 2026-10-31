# User KDE Plasma configuration (via plasma-manager): shortcuts, input, kwin, powerdevil
{
  lib,
  pkgs,
  osConfig,
  ...
}:

{
  # Rebuild KSycoca application cache on home-manager activation so Kickoff and KRunner
  # immediately detect newly added/removed .desktop files across NixOS symlink swaps without restarting plasmashell.
  home.activation.kbuildsycoca = lib.mkIf osConfig.services.desktopManager.plasma6.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export LOCALE_ARCHIVE=/run/current-system/sw/lib/locale/locale-archive
      export LANG="en_US.UTF-8"
      export LC_ALL="en_US.UTF-8"
      export XDG_MENU_PREFIX="plasma-"
      export XDG_DATA_DIRS="''${XDG_DATA_DIRS:-$HOME/.local/share:$HOME/.nix-profile/share:/etc/profiles/per-user/$USER/share:/run/current-system/sw/share}"
      case ":$XDG_DATA_DIRS:" in
        *:/run/current-system/sw/share:*) ;;
        *) export XDG_DATA_DIRS="$XDG_DATA_DIRS:/run/current-system/sw/share" ;;
      esac
      ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
    ''
  );

  programs.plasma = {
    enable = osConfig.services.desktopManager.plasma6.enable;
    overrideConfig = false;

    input.keyboard = {
      numlockOnStartup = "off";
      repeatDelay = 288;
      repeatRate = 40.0;
    };

    kwin = {
      virtualDesktops = {
        number = 2;
      };
    };

    shortcuts = {
      "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Alt+Shift";
      "com.dec05eba.gpu_screen_recorder" = {
        "gpu_screen_recorder_pause_unpause_recording" = "Alt+2";
        "gpu_screen_recorder_save_replay" = "Alt+3";
        "gpu_screen_recorder_start_stop_recording" = "Alt+1";
      };
      "services/LocalSend.desktop"._launch = "Meta+Shift+L";
      "services/google-calendar.desktop"._launch = "Meta+Shift+C";
      "services/org.kde.kate.desktop"._launch = "Meta+Shift+Q";
      "services/org.kde.kcalc.desktop"._launch = "Meta+Shift+D";
      "services/rog-control-center.desktop"._launch = "Launch (3)";
      "services/systemsettings.desktop"._launch = "Tools";
    };

    configFile = {
      "baloofilerc" = {
        "Basic Settings" = {
          "Indexing-Enabled" = false;
        };
      };
      "kcminputrc" = {
        "Libinput/10248/592/ASCF1206:00 2808:0250 Touchpad" = {
          ClickMethod = 2;
          NaturalScroll = true;
          PointerAcceleration = "0.400";
          PointerAccelerationProfile = 2;
          ScrollFactor = "0.5";
        };
        "Libinput/13364/53348/Keychron Keychron M6" = {
          PointerAcceleration = "0.200";
          PointerAccelerationProfile = 1;
        };
        "Libinput/5426/152/Razer Razer DeathAdder Essential" = {
          PointerAcceleration = "-0.100";
          PointerAccelerationProfile = 1;
        };
      };
      "kwinrc" = {
        Xwayland = {
          XwaylandEisNoPrompt = true;
        };
      };
      "kdeglobals" = {
        General = {
          AccentColor = "132,250,216";
        };
      };
      "powerdevilrc" = {
        "AC/Performance".PowerProfile = "performance";
        "AC/RunScript".ProfileLoadCommand = "/run/current-system/sw/bin/sync-power-state ac";
        "AC/SuspendAndShutdown".LidAction = 0;
        "Battery/Performance".PowerProfile = "balanced";
        "Battery/RunScript".ProfileLoadCommand = "/run/current-system/sw/bin/sync-power-state battery";
        "LowBattery/Performance".PowerProfile = "power-saver";
        "LowBattery/SuspendAndShutdown".InhibitLidActionWhenExternalMonitorPresent = false;
      };
    };
  };
}
