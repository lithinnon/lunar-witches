# User KDE Plasma configuration (via plasma-manager): shortcuts, input, kwin, powerdevil
{ osConfig, ... }:

{
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
      "services/org.kde.kate.desktop"._launch = "Meta+Shift+Q";
      "services/org.kde.kcalc.desktop"._launch = "Meta+Shift+D";
      "services/rog-control-center.desktop"._launch = "Launch (3)";
      "services/systemsettings.desktop"._launch = "Tools";
    };

    configFile = {
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
