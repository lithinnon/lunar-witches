#!/usr/bin/env bash
# amdgpu-boost: Advanced AMD GPU Performance Boost, Dynamic Governor & Auto-Display Manager

CARD="${AMDGPU_BOOST_CARD:-card1}"
CONF_FILE="${AMDGPU_BOOST_CONF:-${XDG_CONFIG_HOME:-$HOME/.config}/amdgpu-boost.conf}"

set_sysfs_paths() {
    GPU_DPM="/sys/class/drm/$CARD/device/power_dpm_force_performance_level"
    SCLK_FILE="/sys/class/drm/$CARD/device/pp_dpm_sclk"
    BUSY_FILE="/sys/class/drm/$CARD/device/gpu_busy_percent"
    HWMON_DIR="$(ls -d /sys/class/drm/$CARD/device/hwmon/hwmon* 2>/dev/null | head -n 1)"
}
set_sysfs_paths

# Defaults
MODE="smart"
SMART_UP_THRESHOLD=20
SMART_DOWN_THRESHOLD=12
SMART_COOLDOWN_SECONDS=3.0
COOLDOWN_LIMIT=6
AUTO_REFRESH_RATE="true"

LAST_APPLIED=""
LAST_APPLIED_AC=""
COOLDOWN_TICKS=0

# Cached state for zero-overhead polling
CACHED_IS_AC=0
CACHED_IS_PERF=0

read_config() {
    # Default values
    MODE="smart"
    SMART_UP_THRESHOLD=20
    SMART_DOWN_THRESHOLD=12
    SMART_COOLDOWN_SECONDS=3.0
    AUTO_REFRESH_RATE="true"

    local active_conf=""
    if [ -n "$AMDGPU_BOOST_CONF" ] && [ -f "$AMDGPU_BOOST_CONF" ]; then
        active_conf="$AMDGPU_BOOST_CONF"
    elif [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/amdgpu-boost.conf" ]; then
        active_conf="${XDG_CONFIG_HOME:-$HOME/.config}/amdgpu-boost.conf"
    elif [ -f "/etc/amdgpu-boost.conf" ]; then
        active_conf="/etc/amdgpu-boost.conf"
    fi

    if [ -n "$active_conf" ]; then
        local first_line="$(head -n 1 "$active_conf" | tr -d '[:space:]')"
        if [[ "$first_line" =~ ^(smart|force|disabled|enabled)$ ]]; then
            if [ "$first_line" == "enabled" ]; then MODE="smart"; else MODE="$first_line"; fi
        fi

        while IFS='=' read -r key val || [ -n "$key" ]; do
            key="$(echo "$key" | sed 's/#.*//' | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')"
            val="$(echo "$val" | sed 's/#.*//' | tr -d '[:space:]')"
            case "$key" in
                CARD)
                    if [ -n "$val" ]; then
                        CARD="$val"
                        set_sysfs_paths
                    fi
                    ;;
                MODE)
                    case "$val" in
                        smart|force|disabled) MODE="$val" ;;
                        enabled) MODE="smart" ;;
                    esac
                    ;;
                SMART_UP_THRESHOLD|LOAD_THRESHOLD|THRESHOLD|UP_THRESHOLD)
                    if [[ "$val" =~ ^[0-9]+$ ]]; then
                        SMART_UP_THRESHOLD="$val"
                    fi
                    ;;
                SMART_DOWN_THRESHOLD|DOWN_THRESHOLD)
                    if [[ "$val" =~ ^[0-9]+$ ]]; then
                        SMART_DOWN_THRESHOLD="$val"
                    fi
                    ;;
                SMART_COOLDOWN_SECONDS|COOLDOWN_SECONDS|COOLDOWN)
                    if [[ "$val" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                        SMART_COOLDOWN_SECONDS="$val"
                    fi
                    ;;
                AUTO_REFRESH_RATE|AUTO_REFRESH)
                    case "$val" in
                        true|1|yes|on) AUTO_REFRESH_RATE="true" ;;
                        false|0|no|off) AUTO_REFRESH_RATE="false" ;;
                    esac
                    ;;
            esac
        done < "$active_conf"
    fi

    COOLDOWN_LIMIT=$(awk "BEGIN {limit = int(($SMART_COOLDOWN_SECONDS / 0.5) + 0.5); print (limit > 0 ? limit : 1)}")
}

write_config() {
    read_config
    if [ -n "$1" ]; then
        MODE="$1"
    fi
    
    local target_conf="${AMDGPU_BOOST_CONF:-${XDG_CONFIG_HOME:-$HOME/.config}/amdgpu-boost.conf}"
    mkdir -p "$(dirname "$target_conf")"
    cat << CFG > "$target_conf"
# AMD GPU Boost Configuration
CARD=$CARD
MODE=$MODE
SMART_UP_THRESHOLD=$SMART_UP_THRESHOLD
SMART_DOWN_THRESHOLD=$SMART_DOWN_THRESHOLD
SMART_COOLDOWN_SECONDS=$SMART_COOLDOWN_SECONDS
AUTO_REFRESH_RATE=$AUTO_REFRESH_RATE
CFG
}

check_ac() {
    for psy in /sys/class/power_supply/{ADP*,ucsi-source-psy*}/online; do
        if [ -f "$psy" ] && [ "$(cat "$psy" 2>/dev/null)" -eq 1 ]; then
            return 0
        fi
    done
    return 1
}

# Safe profile check without SIGPIPE / broken pipe on asusctl stdout
check_perf_profile() {
    # 1. Fast direct D-Bus check (0 subprocess overhead)
    local dbus_prof="$(busctl get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile 2>/dev/null)"
    if [[ "$dbus_prof" == *'"performance"'* ]]; then
        return 0
    fi
    
    # 2. Fallback to asusctl reading full output safely into variable (never pipe directly to grep -q)
    local asus_out="$(asusctl profile get 2>/dev/null)"
    if [[ "$asus_out" == *"Active profile: Performance"* ]]; then
        return 0
    fi
    return 1
}

apply_refresh_rate() {
    if [ "$AUTO_REFRESH_RATE" != "true" ]; then
        return
    fi
    # Require active Wayland or X11 graphical session to run kscreen-doctor
    if [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ]; then
        return
    fi
    if ! command -v kscreen-doctor >/dev/null 2>&1; then
        return
    fi
    if kscreen-doctor -o 2>/dev/null | grep -q "eDP-1"; then
        if [ "$CACHED_IS_AC" -eq 1 ]; then
            kscreen-doctor output.eDP-1.mode.2560x1600@165 >/dev/null 2>&1 || true
        else
            kscreen-doctor output.eDP-1.mode.2560x1600@60 >/dev/null 2>&1 || true
        fi
    fi
}

update_cached_system_state() {
    CACHED_IS_AC=0
    if check_ac; then CACHED_IS_AC=1; fi

    CACHED_IS_PERF=0
    if check_perf_profile; then CACHED_IS_PERF=1; fi
}

sync_display_refresh_on_ac_change() {
    # Trigger automatic display refresh rate switch on AC state transition
    if [ "$CACHED_IS_AC" != "$LAST_APPLIED_AC" ]; then
        apply_refresh_rate
        LAST_APPLIED_AC="$CACHED_IS_AC"
    fi
}

set_dpm_state() {
    local target="$1"
    if [ "$target" != "$LAST_APPLIED" ]; then
        echo "$target" > "$GPU_DPM" 2>/dev/null || echo "$target" | sudo -A tee "$GPU_DPM" > /dev/null
        LAST_APPLIED="$target"
    fi
}

set_mode() {
    local new_mode="$1"
    write_config "$new_mode"
    update_cached_system_state
    evaluate_and_apply
    
    case "$new_mode" in
        smart)
            notify-send -u normal -a "AMD GPU Boost" "🔹 Smart Mode Active" "Engages at >= ${SMART_UP_THRESHOLD}% load; releases at < ${SMART_DOWN_THRESHOLD}% load (${SMART_COOLDOWN_SECONDS}s cooldown)." 2>/dev/null || true
            echo "🔹 Mode set to SMART. (Up: ${SMART_UP_THRESHOLD}%, Down: ${SMART_DOWN_THRESHOLD}%, Cooldown: ${SMART_COOLDOWN_SECONDS}s)"
            ;;
        force)
            notify-send -u normal -a "AMD GPU Boost" "🚀 Force Mode Active" "Boosted to maximum available clock continuously." 2>/dev/null || true
            echo "🚀 Mode set to FORCE. (Locked to maximum clock continuously)"
            ;;
        disabled)
            notify-send -u normal -a "AMD GPU Boost" "🛡️ Boost Disabled" "GPU set to dynamic auto. Full package power reserved for CPU." 2>/dev/null || true
            echo "🛡️ Mode set to DISABLED. (GPU forced to dynamic auto mode)"
            ;;
    esac
}

evaluate_and_apply() {
    read_config

    local current_busy=0
    if [ -f "$BUSY_FILE" ]; then
        current_busy=$(cat "$BUSY_FILE" 2>/dev/null || echo 0)
    fi

    # Condition 1: Must be on AC power and Performance mode
    if [ "$CACHED_IS_AC" -ne 1 ] || [ "$CACHED_IS_PERF" -ne 1 ] || [ "$MODE" == "disabled" ]; then
        set_dpm_state "auto"
        COOLDOWN_TICKS=0
        return
    fi

    # Condition 2: Force Mode
    if [ "$MODE" == "force" ]; then
        set_dpm_state "high"
        COOLDOWN_TICKS=0
        return
    fi

    # Condition 3: Smart Mode (Dual-Threshold Schmitt Trigger)
    if [ "$LAST_APPLIED" == "high" ]; then
        # When currently BOOSTED, only release if load drops below SMART_DOWN_THRESHOLD
        if [ "$current_busy" -lt "$SMART_DOWN_THRESHOLD" ]; then
            COOLDOWN_TICKS=$((COOLDOWN_TICKS + 1))
            if [ "$COOLDOWN_TICKS" -ge "$COOLDOWN_LIMIT" ]; then
                set_dpm_state "auto"
                COOLDOWN_TICKS=0
            fi
        else
            COOLDOWN_TICKS=0
        fi
    else
        # When currently IDLE/AUTO, only engage if load exceeds SMART_UP_THRESHOLD
        if [ "$current_busy" -ge "$SMART_UP_THRESHOLD" ]; then
            set_dpm_state "high"
            COOLDOWN_TICKS=0
        else
            set_dpm_state "auto"
            COOLDOWN_TICKS=0
        fi
    fi
}

show_status() {
    read_config
    update_cached_system_state
    local current_dpm="$(cat "$GPU_DPM" 2>/dev/null || echo "unknown")"
    local live_sclk="$(grep '\*' "$SCLK_FILE" 2>/dev/null || cat "$SCLK_FILE" 2>/dev/null | tail -n 1)"
    
    local asus_out="$(asusctl profile get 2>/dev/null)"
    local prof="$(echo "$asus_out" | grep 'Active profile' || echo 'Unknown')"
    local current_busy="$(cat "$BUSY_FILE" 2>/dev/null || echo 0)%"
    
    local is_ac="NO"
    if [ "$CACHED_IS_AC" -eq 1 ]; then is_ac="YES"; fi

    echo "========================================"
    echo "  AMD GPU Boost Status"
    echo "========================================"
    echo "  • DRM Card Device:        $CARD"
    echo "  • Operating Mode:         $MODE"
    if [ "$MODE" == "smart" ]; then
        echo "  • Smart Up Threshold:     ${SMART_UP_THRESHOLD}%"
        echo "  • Smart Down Threshold:   ${SMART_DOWN_THRESHOLD}%"
        echo "  • Smart Cooldown Window:  ${SMART_COOLDOWN_SECONDS}s"
    fi
    if [ "$AUTO_REFRESH_RATE" == "true" ]; then
        echo "  • Auto Screen Refresh:    Enabled (60Hz Battery / 165Hz AC)"
    else
        echo "  • Auto Screen Refresh:    Disabled"
    fi
    echo "  • AC Power Connected:     $is_ac"
    echo "  • Current Profile:        $prof"
    echo "  • Current GPU Load:       $current_busy"
    echo "  • Active DPM Mode:        $current_dpm"
    echo "  • Active GPU Clock:       $live_sclk"
    echo "========================================"
}

get_json() {
    read_config
    update_cached_system_state
    local current_dpm="$(cat "$GPU_DPM" 2>/dev/null || echo "unknown")"
    local live_sclk="$(grep '\*' "$SCLK_FILE" 2>/dev/null | grep -o '[0-9]\+Mhz' | head -n 1 || echo "0Mhz")"
    
    local asus_out="$(asusctl profile get 2>/dev/null)"
    local prof="$(echo "$asus_out" | grep -o 'Active profile: [A-Za-z]\+' | awk '{print $3}' || echo 'Unknown')"
    local busy=$(cat "$BUSY_FILE" 2>/dev/null || echo 0)
    
    local is_ac=false
    if [ "$CACHED_IS_AC" -eq 1 ]; then is_ac=true; fi

    local freq_mhz=0
    if [ -f "$HWMON_DIR/freq1_input" ]; then
        freq_mhz=$(( $(cat "$HWMON_DIR/freq1_input" 2>/dev/null || echo 0) / 1000000 ))
    fi

    local power_w="0.0"
    if [ -f "$HWMON_DIR/power1_input" ]; then
        power_w=$(awk "BEGIN {printf \"%.1f\", $(cat "$HWMON_DIR/power1_input" 2>/dev/null || echo 0) / 1000000}")
    fi

    local temp_c="0"
    if [ -f "$HWMON_DIR/temp1_input" ]; then
        temp_c=$(( $(cat "$HWMON_DIR/temp1_input" 2>/dev/null || echo 0) / 1000 ))
    fi

    cat << JSON
{
  "card": "$CARD",
  "mode": "$MODE",
  "smart_up_threshold": $SMART_UP_THRESHOLD,
  "smart_down_threshold": $SMART_DOWN_THRESHOLD,
  "smart_cooldown_sec": $SMART_COOLDOWN_SECONDS,
  "auto_refresh_rate": $AUTO_REFRESH_RATE,
  "dpm": "$current_dpm",
  "clock": "$live_sclk",
  "freq_mhz": $freq_mhz,
  "busy_pct": $busy,
  "power_w": $power_w,
  "temp_c": $temp_c,
  "is_ac": $is_ac,
  "profile": "$prof"
}
JSON
}

run_daemon() {
    echo "[amdgpu-boost] Advanced Smart Dual-Threshold & Auto-Display Daemon started."
    update_cached_system_state
    sync_display_refresh_on_ac_change
    evaluate_and_apply

    # Background D-Bus signal listener (only update AC/Profile state when D-Bus broadcasts)
    (
        dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties'" 2>/dev/null | \
        while read -r line; do
            if [[ "$line" == *"member=PropertiesChanged"* ]]; then
                update_cached_system_state
                sync_display_refresh_on_ac_change
                evaluate_and_apply
            fi
        done
    ) &
    local dbus_pid=$!

    trap "kill $dbus_pid 2>/dev/null; exit 0" SIGINT SIGTERM EXIT

    # Low-overhead 0.5s polling loop: ONLY reads gpu_busy_percent from sysfs!
    while true; do
        evaluate_and_apply
        sleep 0.5
    done
}

case "$1" in
    smart|auto|on|1)
        set_mode "smart"
        ;;
    force|max|high|f)
        set_mode "force"
        ;;
    off|disable|disabled|0)
        set_mode "disabled"
        ;;
    toggle|t)
        read_config
        case "$MODE" in
            smart) set_mode "force" ;;
            force) set_mode "disabled" ;;
            disabled) set_mode "smart" ;;
            *) set_mode "smart" ;;
        esac
        ;;
    refresh|display)
        read_config
        update_cached_system_state
        apply_refresh_rate
        LAST_APPLIED_AC="$CACHED_IS_AC"
        echo "Display refresh rate applied according to power state."
        ;;
    json|-j)
        get_json
        ;;
    --daemon|-d)
        run_daemon
        ;;
    status|"")
        show_status
        ;;
    *)
        echo "Usage: amdgpu-boost [smart | force | off | toggle | refresh | status | json | --daemon]"
        exit 1
        ;;
esac
