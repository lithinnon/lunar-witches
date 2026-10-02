#!/usr/bin/env python3
"""
service-deck-helper: High-speed backend helper for KDE Plasma Service Deck Widget
Supports querying real-time systemd service states, batched toggles, and alphabetical sorting.
"""

import sys
import os
import json
import subprocess

CONFIG_PATH = os.path.expanduser("~/.config/plasma-service-deck.json")

def load_config():
    default_config = {
        "groups": [
            {
                "id": "hardware",
                "name": "Hardware",
                "icon": "preferences-system-hardware",
                "services": [
                    {"id": "amdgpu-boost.service", "name": "AMD GPU Boost", "scope": "user"},
                    {"id": "asusd.service", "name": "ASUS Notebook Control", "scope": "system"}
                ]
            },
            {
                "id": "network",
                "name": "Network",
                "icon": "network-workgroup",
                "services": [
                    {
                        "id": "app-org.kde.kdeconnect.daemon@autostart.service",
                        "display_id": "kdeconnect.service",
                        "name": "KDE Connect",
                        "scope": "user"
                    },
                    {"id": "syncthing.service", "name": "Syncthing File Sync", "scope": "system"}
                ]
            }
        ],
        "ungrouped": {
            "name": "Ungrouped",
            "icon": "package-x-generic",
            "services": [
                {"id": "kde-baloo.service", "name": "Baloo File Indexer", "scope": "user"}
            ]
        }
    }
    if not os.path.exists(CONFIG_PATH):
        os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
        with open(CONFIG_PATH, "w") as f:
            json.dump(default_config, f, indent=2)
        return default_config
    try:
        with open(CONFIG_PATH, "r") as f:
            return json.load(f)
    except Exception:
        return default_config

def get_systemd_batch_status(services, is_user=True):
    """Query multiple services in a single systemctl show call for sub-millisecond execution"""
    if not services:
        return {}
    
    cmd = ["systemctl"]
    if is_user:
        cmd.append("--user")
    cmd.extend(["show", "-p", "Id", "-p", "Names", "-p", "ActiveState", "-p", "SubState", "-p", "UnitFileState", "-p", "LoadState"])
    cmd.extend(services)
    
    status_map = {}
    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=3)
        current_unit = {}
        for line in res.stdout.splitlines():
            if not line.strip():
                if "Id" in current_unit:
                    status_map[current_unit["Id"]] = current_unit
                    for alias in current_unit.get("Names", "").split():
                        status_map[alias] = current_unit
                current_unit = {}
                continue
            if "=" in line:
                k, v = line.split("=", 1)
                current_unit[k] = v
        if "Id" in current_unit:
            status_map[current_unit["Id"]] = current_unit
            for alias in current_unit.get("Names", "").split():
                status_map[alias] = current_unit
    except Exception:
        pass

    # Ensure all queried services exist in status_map with fallback
    for s in services:
        if s not in status_map:
            status_map[s] = {
                "Id": s,
                "ActiveState": "inactive",
                "SubState": "dead",
                "UnitFileState": "not-found",
                "LoadState": "not-found"
            }
    return status_map

def get_all_status():
    config = load_config()
    
    # Collect all user and system services
    user_services = []
    system_services = []
    
    for grp in config.get("groups", []):
        for svc in grp.get("services", []):
            if svc.get("scope", "user") == "system":
                system_services.append(svc["id"])
            else:
                user_services.append(svc["id"])
                
    ungrouped = config.get("ungrouped", {})
    for svc in ungrouped.get("services", []):
        if svc.get("scope", "user") == "system":
            system_services.append(svc["id"])
        else:
            user_services.append(svc["id"])
            
    user_status = get_systemd_batch_status(list(set(user_services)), is_user=True)
    system_status = get_systemd_batch_status(list(set(system_services)), is_user=False)
    
    def enrich_service(svc):
        s_id = svc["id"]
        display_id = svc.get("display_id", s_id)
        scope = svc.get("scope", "user")
        s_map = system_status if scope == "system" else user_status
        raw = s_map.get(s_id, {"ActiveState": "inactive", "SubState": "dead", "UnitFileState": "not-found", "LoadState": "not-found"})
        
        active_state = raw.get("ActiveState", "inactive")
        sub_state = raw.get("SubState", "dead")
        unit_state = raw.get("UnitFileState", "disabled")
        load_state = raw.get("LoadState", "loaded")
        
        is_active = (active_state in ["active", "activating", "reloading"])
        is_enabled = (unit_state in ["enabled", "enabled-runtime", "static", "indirect", "linked", "linked-runtime", "generated"])
        is_installed = (load_state != "not-found" and unit_state != "not-found")
        
        # Color indicator
        if not is_installed:
            color = "#7f8c8d" # Gray/Muted (not installed)
        elif active_state == "active":
            color = "#2ecc71" # Green
        elif active_state in ["activating", "reloading"]:
            color = "#f39c12" # Yellow/Orange
        elif active_state == "failed":
            color = "#e74c3c" # Red
        else:
            color = "#7f8c8d" # Gray/Muted
            
        display_unit_state = "not installed" if not is_installed else unit_state
            
        return {
            "id": s_id,
            "display_id": display_id,
            "name": svc.get("name", s_id.replace(".service", "").capitalize()),
            "scope": scope,
            "is_admin": (scope == "system"),
            "is_active": is_active,
            "active_state": active_state,
            "sub_state": sub_state,
            "is_enabled": is_enabled,
            "unit_state": display_unit_state,
            "is_installed": is_installed,
            "color": color
        }

    total_active = 0
    total_services = 0
    
    result_groups = []
    # Sort groups alphabetically by name
    sorted_groups = sorted(config.get("groups", []), key=lambda g: g.get("name", "").lower())
    
    for grp in sorted_groups:
        enriched_services = [enrich_service(s) for s in grp.get("services", [])]
        enriched_services.sort(key=lambda s: s["name"].lower())
        
        active_count = sum(1 for s in enriched_services if s["is_active"])
        enabled_count = sum(1 for s in enriched_services if s["is_enabled"])
        
        total_active += active_count
        total_services += len(enriched_services)
        
        result_groups.append({
            "id": grp.get("id", grp.get("name", "group").lower()),
            "name": grp.get("name", "Unnamed Group"),
            "icon": grp.get("icon", "system-run"),
            "services": enriched_services,
            "active_count": active_count,
            "enabled_count": enabled_count,
            "total_count": len(enriched_services),
            "all_active": (active_count == len(enriched_services) and len(enriched_services) > 0),
            "all_enabled": (enabled_count == len(enriched_services) and len(enriched_services) > 0),
            "is_ungrouped": False
        })
        
    # Process ungrouped (Always at the bottom, with services sorted alphabetically)
    ungrouped_services = [enrich_service(s) for s in ungrouped.get("services", [])]
    ungrouped_services.sort(key=lambda s: s["name"].lower())
    
    u_active = sum(1 for s in ungrouped_services if s["is_active"])
    u_enabled = sum(1 for s in ungrouped_services if s["is_enabled"])
    total_active += u_active
    total_services += len(ungrouped_services)
    
    result_groups.append({
        "id": "ungrouped",
        "name": ungrouped.get("name", "Ungrouped"),
        "icon": ungrouped.get("icon", "package-x-generic"),
        "services": ungrouped_services,
        "active_count": u_active,
        "enabled_count": u_enabled,
        "total_count": len(ungrouped_services),
        "all_active": (u_active == len(ungrouped_services) and len(ungrouped_services) > 0),
        "all_enabled": (u_enabled == len(ungrouped_services) and len(ungrouped_services) > 0),
        "is_ungrouped": True
    })
    
    return {
        "groups": result_groups,
        "total_active": total_active,
        "total_services": total_services
    }

def run_systemctl_action(action, scope, service_id):
    """Execute action on a single service"""
    cmd = ["systemctl"]
    if scope == "user":
        cmd.append("--user")
        
    if action == "toggle_run":
        chk = subprocess.run(cmd + ["is-active", service_id], stdout=subprocess.PIPE, text=True)
        sub_action = "stop" if chk.returncode == 0 else "start"
        cmd.append(sub_action)
    elif action == "toggle_enable":
        chk = subprocess.run(cmd + ["is-enabled", service_id], stdout=subprocess.PIPE, text=True)
        sub_action = "disable" if ("enabled" in chk.stdout or "generated" in chk.stdout) else "enable"
        cmd.append(sub_action)
    else:
        cmd.append(action)
        
    cmd.append(service_id)
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return res.returncode == 0

def run_group_action(action, group_id):
    """
    Execute bulk action on all services in a group.
    Batches user services and system services into single commands so Polkit only prompts ONCE!
    """
    config = load_config()
    target_services = []
    
    if group_id == "ungrouped":
        target_services = config.get("ungrouped", {}).get("services", [])
    else:
        for grp in config.get("groups", []):
            if grp.get("id") == group_id or grp.get("name") == group_id:
                target_services = grp.get("services", [])
                break
                
    if not target_services:
        return True

    user_svcs = [s["id"] for s in target_services if s.get("scope", "user") != "system"]
    system_svcs = [s["id"] for s in target_services if s.get("scope", "user") == "system"]

    sub_action = action.replace("_all", "")

    success = True
    # 1. Execute User-level batch in one single invocation
    if user_svcs:
        res = subprocess.run(["systemctl", "--user", sub_action] + user_svcs, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode != 0:
            success = False

    # 2. Execute System-level batch in one single invocation (prompts Polkit / password ONCE)
    if system_svcs:
        res = subprocess.run(["systemctl", sub_action] + system_svcs, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode != 0:
            success = False

    return success

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] in ["status", "json", "-j"]:
        data = get_all_status()
        print(json.dumps(data, indent=2))
        sys.exit(0)
        
    cmd = sys.argv[1]
    
    if cmd == "service" and len(sys.argv) >= 5:
        # service <action> <scope> <service_id>
        action, scope, svc_id = sys.argv[2], sys.argv[3], sys.argv[4]
        ok = run_systemctl_action(action, scope, svc_id)
        sys.exit(0 if ok else 1)
        
    elif cmd == "group" and len(sys.argv) >= 4:
        # group <action> <group_id>
        action, grp_id = sys.argv[2], sys.argv[3]
        ok = run_group_action(action, grp_id)
        sys.exit(0 if ok else 1)
        
    else:
        print("Usage: service-deck-helper [status | service <action> <scope> <service_id> | group <action> <group_id>]")
        sys.exit(1)
