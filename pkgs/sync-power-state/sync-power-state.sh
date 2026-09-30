#!/usr/bin/env bash
# sync-power-state.sh: Seamless AC vs Battery display and platform state switcher
set -e

# Detect AC state if not explicitly passed as argument
check_ac() {
    for psy in /sys/class/power_supply/{ADP*,ucsi-source-psy*}/online; do
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

PANEL_OD="/sys/devices/platform/asus-nb-wmi/panel_od"
THROTTLE_POLICY="/sys/devices/platform/asus-nb-wmi/throttle_thermal_policy"
BOOST_FILE="/sys/devices/system/cpu/cpufreq/boost"

safe_write() {
    local val="$1"
    local file="$2"
    if [ -w "$file" ]; then
        echo "$val" > "$file" 2>/dev/null || true
    elif [ -f "$file" ]; then
        echo "$val" | sudo -A tee "$file" > /dev/null 2>&1 || true
    fi
}

case "$TARGET_STATE" in
    battery|bat|discharge)
        # 1. Switch display to 60Hz
        kscreen-doctor output.eDP-1.mode.2 >/dev/null 2>&1 || true
        # 2. Disable panel overdrive
        safe_write 0 "$PANEL_OD"
        # 3. Engage Silent thermal policy (0dB fan mode below ~55°C)
        safe_write 2 "$THROTTLE_POLICY"
        # 4. Ensure master CPU boost remains enabled so power-profiles-daemon can manage EPP / policies without kernel EINVAL
        safe_write 1 "$BOOST_FILE"
        ;;
    ac|plugged|performance)
        # 1. Switch display to 165Hz
        kscreen-doctor output.eDP-1.mode.1 >/dev/null 2>&1 || true
        # 2. Enable panel overdrive (3ms GtG)
        safe_write 1 "$PANEL_OD"
        # 3. Engage Turbo thermal policy (unlocked APU PPT)
        safe_write 1 "$THROTTLE_POLICY"
        # 4. Ensure master CPU Core Performance Boost is enabled
        safe_write 1 "$BOOST_FILE"
        ;;
    status)
        echo "AC Connected: $(check_ac && echo 'YES' || echo 'NO')"
        echo "Current Refresh Rate: $(kscreen-doctor -o 2>/dev/null | grep -o '2560x1600@[0-9.]\+\*' || echo 'unknown')"
        echo "Panel Overdrive: $(cat "$PANEL_OD" 2>/dev/null || echo 'unknown')"
        echo "Thermal Policy: $(cat "$THROTTLE_POLICY" 2>/dev/null || echo 'unknown')"
        echo "CPU Core Boost: $(cat "$BOOST_FILE" 2>/dev/null || echo 'unknown')"
        ;;
    *)
        echo "Usage: $0 [battery | ac | status]"
        exit 1
        ;;
esac
