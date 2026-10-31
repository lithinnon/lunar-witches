#!/usr/bin/env bash
# sync-power-state.sh: Seamless ASUS hardware state helper (Panel Overdrive) on AC/Battery transition
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

# Sysfs paths: ASUS ROG/TUF specific WMI platform
ASUS_WMI_DIR="/sys/devices/platform/asus-nb-wmi"
PANEL_OD="$ASUS_WMI_DIR/panel_od"
PLATFORM_PROFILE="/sys/firmware/acpi/platform_profile"

safe_write() {
    local val="$1"
    local file="$2"
    if [ ! -f "$file" ]; then
        return
    fi
    local current="$(cat "$file" 2>/dev/null || echo "")"
    if [ "$current" = "$val" ]; then
        return
    fi
    if [ -w "$file" ]; then
        echo "$val" > "$file" 2>/dev/null || true
    fi
}

case "$TARGET_STATE" in
    battery|bat|discharge)
        # Disable panel overdrive on battery to conserve display power
        if [ -d "$ASUS_WMI_DIR" ]; then
            safe_write 0 "$PANEL_OD"
        fi
        ;;
    ac|plugged|performance)
        # Enable panel overdrive on AC for maximum pixel response time
        if [ -d "$ASUS_WMI_DIR" ]; then
            safe_write 1 "$PANEL_OD"
        fi
        ;;
    status)
        echo "AC Connected: $(check_ac && echo 'YES' || echo 'NO')"
        echo "ACPI Platform Profile: $(cat "$PLATFORM_PROFILE" 2>/dev/null || echo 'unsupported')"
        if [ -d "$ASUS_WMI_DIR" ]; then
            echo "ASUS Panel Overdrive: $(cat "$PANEL_OD" 2>/dev/null || echo 'unknown')"
            echo "ASUS Thermal Policy: $(cat "$ASUS_WMI_DIR/throttle_thermal_policy" 2>/dev/null || echo 'unknown')"
        else
            echo "ASUS Platform: Not detected"
        fi
        ;;
    *)
        echo "Usage: $0 [battery | ac | status]"
        exit 1
        ;;
esac
