#!/usr/bin/env bash
# asus-power-sync: Unified ASUS laptop hardware state coordinator (Panel Overdrive & SD Card Reader PCIe PM)
set -euo pipefail

check_ac() {
    # Check all mains and USB-C PD power supplies
    for psy in /sys/class/power_supply/{ADP*,AC*,ACAD*,ucsi-source-psy*}/online; do
        if [ -f "$psy" ] && [ "$(cat "$psy" 2>/dev/null || echo 0)" -eq 1 ]; then
            return 0
        fi
    done
    return 1
}

safe_write() {
    local val="$1"
    local file="$2"
    if [ ! -f "$file" ]; then
        return 0
    fi
    local current
    current="$(cat "$file" 2>/dev/null || echo "")"
    if [ "$current" = "$val" ]; then
        return 0
    fi
    if [ -w "$file" ]; then
        echo "$val" > "$file" 2>/dev/null || true
    fi
}

ASUS_WMI_DIR="/sys/devices/platform/asus-nb-wmi"
PANEL_OD="$ASUS_WMI_DIR/panel_od"

apply_state() {
    local state="$1"
    case "$state" in
        battery)
            # Display: Disable panel overdrive on battery to conserve display power
            if [ -d "$ASUS_WMI_DIR" ]; then
                safe_write 0 "$PANEL_OD"
            fi

            # PCIe SD Card Reader: Enable runtime PM (auto) to permit D3hot and ASPM L1.2
            for ctrl in /sys/bus/pci/drivers/rtsx_pci/*/power/control; do
                safe_write "auto" "$ctrl"
            done
            ;;
        ac)
            # Display: Enable panel overdrive on AC for maximum pixel response time
            if [ -d "$ASUS_WMI_DIR" ]; then
                safe_write 1 "$PANEL_OD"
            fi

            # PCIe SD Card Reader: Disable runtime PM (on) to prevent resume timeout (-110)
            for ctrl in /sys/bus/pci/drivers/rtsx_pci/*/power/control; do
                safe_write "on" "$ctrl"
            done
            ;;
    esac
}

TARGET_STATE="${1:-auto}"

case "$TARGET_STATE" in
    auto)
        if check_ac; then
            apply_state "ac"
        else
            apply_state "battery"
        fi
        ;;
    battery|bat|discharge)
        apply_state "battery"
        ;;
    ac|plugged|performance)
        # Failsafe: Never force AC state if physically running on battery
        if ! check_ac; then
            apply_state "battery"
        else
            apply_state "ac"
        fi
        ;;
    status)
        echo "=== ASUS Hardware Power State ==="
        echo "AC Connected: $(check_ac && echo 'YES' || echo 'NO')"
        if [ -d "$ASUS_WMI_DIR" ]; then
            echo "ASUS Panel Overdrive: $(cat "$PANEL_OD" 2>/dev/null || echo 'unsupported')"
            echo "ASUS Thermal Policy: $(cat "$ASUS_WMI_DIR/throttle_thermal_policy" 2>/dev/null || echo 'unsupported')"
        else
            echo "ASUS Platform: Not detected"
        fi
        echo "ACPI Platform Profile: $(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo 'unsupported')"
        for ctrl in /sys/bus/pci/drivers/rtsx_pci/*/power/control; do
            if [ -f "$ctrl" ]; then
                dev_dir="$(dirname "$(dirname "$ctrl")")"
                dev_name="$(basename "$dev_dir")"
                pstate="$(cat "$dev_dir/power_state" 2>/dev/null || echo 'unknown')"
                rstatus="$(cat "$dev_dir/power/runtime_status" 2>/dev/null || echo 'unknown')"
                ctrl_val="$(cat "$ctrl" 2>/dev/null || echo 'unknown')"
                echo "Realtek Reader ($dev_name): control=$ctrl_val, state=$pstate, runtime=$rstatus"
            fi
        done
        ;;
    *)
        echo "Usage: $0 [auto | ac | battery | status]"
        exit 1
        ;;
esac
