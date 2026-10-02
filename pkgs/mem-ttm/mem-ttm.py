#!/usr/bin/env python3
"""
Lightweight standalone Linux DRM Translation Table Manager (TTM) memory inspector.
Directly reads kernel sysfs parameter and meminfo with zero external dependencies.
Works across any Linux platform using TTM (AMD amdgpu, Intel Xe/i915, NVIDIA nouveau, etc.).
"""
import sys

TTM_PARAM_PATH = "/sys/module/ttm/parameters/pages_limit"

def main():
    try:
        with open(TTM_PARAM_PATH, "r", encoding="utf-8") as f:
            pages = int(f.read().strip())
            gb_value = (pages * 4096) / (1024**3)
            print(f"💻 Current TTM pages limit: {pages} pages ({gb_value:.2f} GB)")
    except FileNotFoundError:
        print(f"❌ Error: Could not find {TTM_PARAM_PATH}")
    except Exception as e:
        print(f"❌ Error reading TTM parameters: {e}")

    try:
        with open("/proc/meminfo", "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    kb = int(line.split()[1])
                    total_gb = kb / (1024**2)
                    print(f"💻 Total system memory: {total_gb:.2f} GB")
                    break
    except Exception:
        pass

if __name__ == "__main__":
    main()
