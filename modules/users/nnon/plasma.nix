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
        rows = 1;
      };
    };

    shortcuts = {
      "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Alt+Shift";
      "com.dec05eba.gpu_screen_recorder" = {
        "gpu_screen_recorder_pause_unpause_recording" = "Alt+2";
        "gpu_screen_recorder_save_replay" = "Alt+3";
        "gpu_screen_recorder_start_stop_recording" = "Alt+1";
      };
      kaccess."Toggle Screen Reader On and Off" = "Meta+Alt+S";
      kmix = {
        "decrease_microphone_volume" = "Microphone Volume Down";
        "decrease_volume" = "Volume Down";
        "decrease_volume_small" = "Shift+Volume Down";
        "increase_microphone_volume" = "Microphone Volume Up";
        "increase_volume" = "Volume Up";
        "increase_volume_small" = "Shift+Volume Up";
        "mic_mute" = [
          "Microphone Mute"
          "Meta+Volume Mute"
        ];
        "mute" = "Volume Mute";
      };
      ksmserver = {
        "Lock Session" = [
          "Screensaver"
          "Meta+L"
        ];
        "Log Out" = "Ctrl+Alt+Del";
      };
      kwin = {
        "Activate Window Demanding Attention" = "Meta+Ctrl+A";
        "Edit Tiles" = "Meta+T";
        "Expose" = [
          "Ctrl+F9"
          "Meta+F9"
        ];
        "ExposeAll" = [
          "Launch (C)"
          "Ctrl+F10"
          "Meta+F10"
        ];
        "ExposeClass" = [
          "Ctrl+F7"
          "Meta+F7"
        ];
        "Grid View" = "Meta+G";
        "Kill Window" = "Meta+Ctrl+Esc";
        "MoveMouseToCenter" = "Meta+F6";
        "MoveMouseToFocus" = "Meta+F5";
        "Overview" = "Meta+W";
        "Show Desktop" = "Meta+D";
        "Switch One Desktop Down" = "Meta+Ctrl+Down";
        "Switch One Desktop Up" = "Meta+Ctrl+Up";
        "Switch One Desktop to the Left" = "Meta+Ctrl+Left";
        "Switch One Desktop to the Right" = "Meta+Ctrl+Right";
        "Switch Window Down" = "Meta+Alt+Down";
        "Switch Window Left" = "Meta+Alt+Left";
        "Switch Window Right" = "Meta+Alt+Right";
        "Switch Window Up" = "Meta+Alt+Up";
        "Switch to Desktop 1" = "Ctrl+F1";
        "Switch to Desktop 2" = "Ctrl+F2";
        "Switch to Desktop 3" = "Ctrl+F3";
        "Switch to Desktop 4" = "Ctrl+F4";
        "Walk Through Windows" = [
          "Alt+Tab"
          "Meta+Tab"
        ];
        "Walk Through Windows (Reverse)" = [
          "Alt+Shift+Tab"
          "Meta+Shift+Tab"
        ];
        "Walk Through Windows of Current Application" = [
          "Alt+`"
          "Meta+`"
        ];
        "Walk Through Windows of Current Application (Reverse)" = [
          "Alt+~"
          "Meta+~"
        ];
        "Window Close" = "Alt+F4";
        "Window Maximize" = "Meta+PgUp";
        "Window Minimize" = "Meta+PgDown";
        "Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
        "Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
        "Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
        "Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
        "Window Operations Menu" = "Alt+F3";
        "Window Quick Tile Bottom" = "Meta+Down";
        "Window Quick Tile Left" = "Meta+Left";
        "Window Quick Tile Right" = "Meta+Right";
        "Window Quick Tile Top" = "Meta+Up";
        "Window Restore" = "Meta+Backspace";
        "Window to Next Screen" = "Meta+Shift+Right";
        "Window to Previous Screen" = "Meta+Shift+Left";
        "disableInputCapture" = "Meta+Shift+Esc";
        "view_actual_size" = "Meta+0";
        "view_zoom_in" = [
          "Meta++"
          "Meta+="
        ];
        "view_zoom_out" = "Meta+-";
      };
      mediacontrol = {
        "nextmedia" = "Media Next";
        "pausemedia" = "Media Pause";
        "playpausemedia" = [
          "Media Play"
          "Launch (4)"
        ];
        "previousmedia" = "Media Previous";
        "seekbackwardmedia" = "Media Rewind";
        "seekforwardmedia" = "Media Fast Forward";
        "stopmedia" = "Media Stop";
      };
      org_kde_powerdevil = {
        "Decrease Keyboard Brightness" = "Keyboard Brightness Down";
        "Decrease Screen Brightness" = "Monitor Brightness Down";
        "Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
        "Hibernate" = "Hibernate";
        "Increase Keyboard Brightness" = "Keyboard Brightness Up";
        "Increase Screen Brightness" = "Monitor Brightness Up";
        "Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
        "PowerDown" = "Power Down";
        "PowerOff" = "Power Off";
        "Sleep" = "Sleep";
        "Toggle Keyboard Backlight" = "Keyboard Light On/Off";
        "powerProfile" = [
          "Battery"
          "Meta+B"
        ];
      };
      plasmashell = {
        "activate application launcher" = [
          "Meta"
          "Alt+F1"
        ];
        "activate task manager entry 1" = "Meta+1";
        "activate task manager entry 2" = "Meta+2";
        "activate task manager entry 3" = "Meta+3";
        "activate task manager entry 4" = "Meta+4";
        "activate task manager entry 5" = "Meta+5";
        "activate task manager entry 6" = "Meta+6";
        "activate task manager entry 7" = "Meta+7";
        "activate task manager entry 8" = "Meta+8";
        "activate task manager entry 9" = "Meta+9";
        "clipboard_action" = "Meta+Ctrl+X";
        "cycle-panels" = "Meta+Alt+P";
        "manage activities" = "Meta+Q";
        "next activity" = "Meta+A";
        "previous activity" = "Meta+Shift+A";
        "show dashboard" = "Ctrl+F12";
        "show-on-mouse-pos" = "Meta+V";
      };
      "services/org.kde.kate.desktop"._launch = "Meta+Shift+Q";
      "services/org.localsend.localsend_app.desktop"._launch = "Meta+Shift+L";
      "services/rog-control-center.desktop"._launch = "Launch (3)";
      "services/systemsettings.desktop"._launch = "Tools";
    };

    configFile = {
      "kcminputrc" = {
        "Libinput/10248/592/ASCF1206:00 2808:0250 Mouse" = {
          PointerAcceleration = "0.000";
          PointerAccelerationProfile = 2;
        };
        "Libinput/10248/592/ASCF1206:00 2808:0250 Touchpad" = {
          ClickMethod = 2;
          DisableEventsOnExternalMouse = false;
          DisableWhileTyping = false;
          Enabled = false;
          LmrTapButtonMap = false;
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
        Wayland = {
          VirtualKeyboardEnabled = true;
          VirtualKeyboardMode = 1;
        };
        Xwayland = {
          Scale = 1;
          XwaylandEisNoPrompt = true;
        };
      };
      "kdeglobals" = {
        General = {
          AccentColor = "132,250,216";
          BrowserApplication = "brave-browser.desktop";
          LastUsedCustomAccentColor = "132,250,216";
        };
      };
      "powerdevilrc" = {
        "AC/Performance".PowerProfile = "performance";
        "AC/RunScript".ProfileLoadCommand = "/run/current-system/sw/bin/sync-power-state ac";
        "AC/SuspendAndShutdown".LidAction = 0;
        "Battery/Performance".PowerProfile = "balanced";
        "Battery/RunScript".ProfileLoadCommand = "/run/current-system/sw/bin/sync-power-state battery";
        "Inhibitions".BlockedInhibitions = "/opt/brave.com/brave/brave:Video Wake Lock";
        "LowBattery/Performance".PowerProfile = "power-saver";
        "LowBattery/SuspendAndShutdown".InhibitLidActionWhenExternalMonitorPresent = false;
      };
    };
  };
}
