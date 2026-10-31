#!/usr/bin/env bash
# sync-power-state.sh: Seamless AC vs Battery display and platform state switcher
set -e

# Detect AC state if not explicitly passed as argument
check_ac() {
    for psy in /sys/class/power_supply/{ADP*,AC*,ACAD*,ucsi-source-psy*}/online; do
        if [ -f "$psy" ] && [ "$(cat "$psy" 2>/dev/null)" -eq 1 ]; then
            return 0
        fi
    done
    return 1
}

TARGET_STATE="$1"
if [ -z "$TARGET_STATE" ]; then
    if check_ac; then
        TARGET_STATE="ac"
    else
        TARGET_STATE="battery"
    fi
elif [ "$TARGET_STATE" = "ac" ] || [ "$TARGET_STATE" = "plugged" ] || [ "$TARGET_STATE" = "performance" ]; then
    # Failsafe: Never allow AC high-power mode if physically unplugged
    if ! check_ac; then
        TARGET_STATE="battery"
    fi
fi

# Sysfs paths: Universal Linux ACPI platform profile
PLATFORM_PROFILE="/sys/firmware/acpi/platform_profile"
PLATFORM_PROFILE_CHOICES="/sys/firmware/acpi/platform_profile_choices"

# Sysfs paths: ASUS ROG/TUF specific WMI platform
ASUS_WMI_DIR="/sys/devices/platform/asus-nb-wmi"
PANEL_OD="$ASUS_WMI_DIR/panel_od"
THROTTLE_POLICY="$ASUS_WMI_DIR/throttle_thermal_policy"

# CPU Boost files (AMD cpufreq vs Intel intel_pstate)
AMD_BOOST="/sys/devices/system/cpu/cpufreq/boost"
INTEL_NO_TURBO="/sys/devices/system/cpu/intel_pstate/no_turbo"

safe_write() {
    local val="$1"
    local file="$2"
    if [ -w "$file" ]; then
        echo "$val" > "$file" 2>/dev/null || true
    elif [ -f "$file" ]; then
        echo "$val" | sudo -A tee "$file" > /dev/null 2>&1 || true
    fi
}

set_platform_profile() {
    local pref="$1" # "quiet" or "performance"
    if [ -f "$PLATFORM_PROFILE" ]; then
        local choices="$(cat "$PLATFORM_PROFILE_CHOICES" 2>/dev/null || echo "")"
        if [[ " $choices " =~ " $pref " ]]; then
            safe_write "$pref" "$PLATFORM_PROFILE"
        elif [ "$pref" = "quiet" ] && [[ " $choices " =~ " low-power " ]]; then
            safe_write "low-power" "$PLATFORM_PROFILE"
        elif [ "$pref" = "performance" ] && [[ " $choices " =~ " balanced " ]]; then
            safe_write "balanced" "$PLATFORM_PROFILE"
        fi
    fi
}

set_cpu_boost() {
    local enable="$1" # 1 = enable boost, 0 = disable boost
    # 1. AMD CPU boost (/sys/devices/system/cpu/cpufreq/boost: 1 = enable, 0 = disable)
    if [ -f "$AMD_BOOST" ]; then
        safe_write "$enable" "$AMD_BOOST"
    fi

    # 2. Intel CPU turbo boost (/sys/devices/system/cpu/intel_pstate/no_turbo: 0 = enable turbo, 1 = disable turbo)
    if [ -f "$INTEL_NO_TURBO" ]; then
        local intel_val=$(( 1 - enable ))
        safe_write "$intel_val" "$INTEL_NO_TURBO"
    fi
}

case "$TARGET_STATE" in
    battery|bat|discharge)
        # 1. Display: switch internal panel to 60Hz (if in graphical session)
        if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
            kscreen-doctor output.eDP-1.mode.2560x1600@60 >/dev/null 2>&1 \
                || kscreen-doctor output.eDP-1.mode.2 >/dev/null 2>&1 || true
        fi

        # 2. Universal Linux ACPI platform profile: quiet / low-power
        set_platform_profile "quiet"

        # 3. ASUS-specific WMI controls (safely guarded)
        if [ -d "$ASUS_WMI_DIR" ]; then
            safe_write 0 "$PANEL_OD"
            safe_write 2 "$THROTTLE_POLICY"
        fi

        # 4. CPU Boost: Ensure master boost remains enabled so power-profiles-daemon can manage EPP
        set_cpu_boost 1
        ;;
    ac|plugged|performance)
        # 1. Display: switch internal panel to high refresh rate (165Hz) (if in graphical session)
        if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
            kscreen-doctor output.eDP-1.mode.2560x1600@165 >/dev/null 2>&1 \
                || kscreen-doctor output.eDP-1.mode.1 >/dev/null 2>&1 || true
        fi

        # 2. Universal Linux ACPI platform profile: performance
        set_platform_profile "performance"

        # 3. ASUS-specific WMI controls (safely guarded)
        if [ -d "$ASUS_WMI_DIR" ]; then
            safe_write 1 "$PANEL_OD"
            safe_write 1 "$THROTTLE_POLICY"
        fi

        # 4. CPU Boost: Ensure master boost is enabled
        set_cpu_boost 1
        ;;
    status)
        echo "AC Connected: $(check_ac && echo 'YES' || echo 'NO')"
        echo "Current Refresh Rate: $(kscreen-doctor -o 2>/dev/null | grep -o '[0-9x]\+@[0-9.]\+\*' || echo 'unknown')"
        echo "ACPI Platform Profile: $(cat "$PLATFORM_PROFILE" 2>/dev/null || echo 'unsupported')"
        if [ -d "$ASUS_WMI_DIR" ]; then
            echo "ASUS Panel Overdrive: $(cat "$PANEL_OD" 2>/dev/null || echo 'unknown')"
            echo "ASUS Thermal Policy: $(cat "$THROTTLE_POLICY" 2>/dev/null || echo 'unknown')"
        else
            echo "ASUS Platform: Not detected"
        fi
        if [ -f "$AMD_BOOST" ]; then
            echo "CPU Boost (AMD): $(cat "$AMD_BOOST" 2>/dev/null || echo 'unknown')"
        elif [ -f "$INTEL_NO_TURBO" ]; then
            local no_turbo=$(cat "$INTEL_NO_TURBO" 2>/dev/null || echo 'unknown')
            echo "CPU Boost (Intel): $([ "$no_turbo" = "0" ] && echo "enabled" || echo "disabled")"
        else
            echo "CPU Boost: managed by governor/EPP"
        fi
        ;;
    *)
        echo "Usage: $0 [battery | ac | status]"
        exit 1
        ;;
esac
