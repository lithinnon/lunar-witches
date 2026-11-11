"""
ACG Config Sync Core Engine
Shared library for syncing, merging, and applying Unreal Engine configs
with custom user overrides and read-only protections across anime/ACG games.
"""

import os
import sys
import subprocess
import shutil
import argparse
from pathlib import Path
from collections import OrderedDict
from typing import Dict, List, Optional

class ACGConfigEngine:
    def __init__(
        self,
        game_name: str,
        repo_url: str,
        default_config_dir: Path,
        default_cache_dir: Path,
        default_preset: str = "Config 3",
        common_files: Optional[List[str]] = None,
        read_only: bool = False,
        legacy_cleanup_files: Optional[List[Path]] = None,
    ):
        self.game_name = game_name
        self.repo_url = repo_url
        self.default_config_dir = default_config_dir
        self.default_cache_dir = default_cache_dir
        self.default_preset = default_preset
        self.common_files = common_files or ["DeviceProfiles.ini", "Input.ini"]
        self.read_only = read_only
        self.legacy_cleanup_files = legacy_cleanup_files or []

    def update_repo(self, cache_dir: Path) -> bool:
        """Clones or pulls the latest repository."""
        if not cache_dir.exists():
            print(f"[*] Cloning {self.game_name} configs repository into {cache_dir}...")
            try:
                subprocess.run(
                    ["git", "clone", "--depth", "1", self.repo_url, str(cache_dir)],
                    check=True,
                    capture_output=True,
                    text=True,
                    timeout=15,
                )
                return True
            except Exception as e:
                print(f"[!] Warning: Failed to clone upstream repository: {e}")
                return False
        else:
            try:
                print(f"[*] Checking for upstream {self.game_name} updates...")
                subprocess.run(
                    ["git", "-C", str(cache_dir), "pull", "--ff-only"],
                    check=True,
                    capture_output=True,
                    text=True,
                    timeout=8,
                )
                return True
            except Exception as e:
                print(f"[!] Warning: Could not update repository (offline / timeout): {e}")
                return False

    @staticmethod
    def set_writable(file_path: Path) -> None:
        """Ensures a file is writable before editing or replacing."""
        if file_path.exists():
            try:
                current_mode = file_path.stat().st_mode
                file_path.chmod(current_mode | 0o600)
            except Exception as e:
                print(f"[!] Warning: Failed to set write permissions on {file_path}: {e}")

    @staticmethod
    def set_readonly(file_path: Path) -> None:
        """Sets file to read-only (chmod 444)."""
        if file_path.exists():
            try:
                file_path.chmod(0o444)
            except Exception as e:
                print(f"[!] Warning: Failed to set read-only on {file_path}: {e}")

    @staticmethod
    def parse_ini_sections(file_path: Path) -> "OrderedDict[str, List[str]]":
        """Parses INI file preserving duplicate multi-value keys and section order."""
        sections = OrderedDict()
        current_section = None

        if not file_path.exists():
            return sections

        with open(file_path, "r", encoding="utf-8", errors="replace") as f:
            for raw_line in f:
                line = raw_line.strip()
                if not line or line.startswith(";"):
                    continue
                if line.startswith("[") and line.endswith("]"):
                    current_section = line[1:-1].strip()
                    if current_section not in sections:
                        sections[current_section] = []
                elif current_section is not None:
                    sections[current_section].append(line)

        return sections

    @staticmethod
    def merge_section_lines(base_lines: List[str], user_lines: List[str]) -> List[str]:
        """
        Merges lines in a section:
        - Unique cvars are overridden by user values.
        - Multi-value keys (paths, cvars, startupmovies) are preserved and accumulated.
        """
        key_dict = OrderedDict()
        multi_keys = {"paths", "cvars", "startupmovies"}
        multi_list = []

        for line in base_lines:
            if "=" in line:
                k, _ = line.split("=", 1)
                k_clean = k.strip()
                if k_clean.lower() in multi_keys:
                    if line not in multi_list:
                        multi_list.append(line)
                else:
                    key_dict[k_clean.lower()] = line
            else:
                multi_list.append(line)

        for line in user_lines:
            if "=" in line:
                k, _ = line.split("=", 1)
                k_clean = k.strip()
                if k_clean.lower() in multi_keys:
                    if line not in multi_list:
                        multi_list.append(line)
                else:
                    key_dict[k_clean.lower()] = line
            else:
                if line not in multi_list:
                    multi_list.append(line)

        return multi_list + list(key_dict.values())

    def apply_config(self, preset: str, config_dir: Path, cache_dir: Path) -> None:
        """Merges preset and user overrides, then applies files with proper permissions."""
        preset_dir = cache_dir / preset
        if not preset_dir.exists():
            available = [p.name for p in cache_dir.glob("Config *")]
            print(f"[!] Error: Preset '{preset}' not found in {cache_dir}!")
            print(f"    Available presets: {available}")
            sys.exit(1)

        config_dir.mkdir(parents=True, exist_ok=True)

        # 1. Clean up conflicting legacy files
        for legacy_file in self.legacy_cleanup_files:
            if legacy_file.exists():
                print(f"[*] Removing legacy {legacy_file}...")
                self.set_writable(legacy_file)
                legacy_file.unlink()

        # 2. Parse Preset Engine.ini
        preset_engine_ini = preset_dir / "Engine.ini"
        preset_sections = self.parse_ini_sections(preset_engine_ini)

        # 3. Parse User Overrides (Engine.user.ini)
        user_override_file = config_dir / "Engine.user.ini"
        if not user_override_file.exists():
            with open(user_override_file, "w", encoding="utf-8") as f:
                f.write(
                    f"; User Custom Overrides for {self.game_name}\n"
                    "; Add custom cvars or tweaks here. They will persist across upstream updates!\n"
                    "; Example:\n"
                    "; [SystemSettings]\n"
                    "; r.MotionBlur.Max=0\n\n"
                )
            print(f"[*] Created user custom overrides template at {user_override_file}")

        user_sections = self.parse_ini_sections(user_override_file)

        # 4. Merge Sections
        all_sections = list(preset_sections.keys())
        for s in user_sections.keys():
            if s not in all_sections:
                all_sections.append(s)

        merged_output = []
        for sname in all_sections:
            p_lines = preset_sections.get(sname, [])
            u_lines = user_sections.get(sname, [])
            m_lines = self.merge_section_lines(p_lines, u_lines)
            if m_lines:
                merged_output.append(f"[{sname}]")
                merged_output.extend(m_lines)
                merged_output.append("")

        target_engine_ini = config_dir / "Engine.ini"
        self.set_writable(target_engine_ini)
        with open(target_engine_ini, "w", encoding="utf-8") as f:
            f.write("\n".join(merged_output) + "\n")

        if self.read_only:
            self.set_readonly(target_engine_ini)
        print(f"[✓] Engine.ini successfully generated from '{preset}' + user overrides.")

        # 5. Deploy Common files
        common_dir = cache_dir / "Common"
        if common_dir.exists():
            for ini_file in self.common_files:
                src = common_dir / ini_file
                dst = config_dir / ini_file
                if src.exists():
                    self.set_writable(dst)
                    shutil.copy2(src, dst)
                    if self.read_only:
                        self.set_readonly(dst)
                    print(f"[✓] Deployed {ini_file} (Read-Only: {self.read_only}).")

    def run_cli(self, args_list: Optional[List[str]] = None) -> None:
        """Command-line interface runner with launcher wrapper support."""
        parser = argparse.ArgumentParser(description=f"{self.game_name} Config Integrator & Updater")
        parser.add_argument(
            "--preset",
            default=self.default_preset,
            help=f"Target preset (default: '{self.default_preset}')",
        )
        parser.add_argument(
            "--config-dir",
            type=Path,
            default=self.default_config_dir,
            help="Path to game configuration directory",
        )
        parser.add_argument(
            "--cache-dir",
            type=Path,
            default=self.default_cache_dir,
            help="Path to cache upstream repository",
        )
        parser.add_argument(
            "--no-pull",
            action="store_true",
            help="Skip updating upstream repository from git",
        )
        parser.add_argument(
            "launch_cmd",
            nargs=argparse.REMAINDER,
            help="Optional command to execute after sync (for Steam/Proton wrapper)",
        )

        args = parser.parse_args(args_list)

        if not args.no_pull:
            self.update_repo(args.cache_dir)

        self.apply_config(args.preset, args.config_dir, args.cache_dir)

        if args.launch_cmd:
            cmd = args.launch_cmd
            if cmd and cmd[0] == "--":
                cmd = cmd[1:]
            if cmd:
                print(f"[*] Executing game binary: {cmd}")
                os.execvp(cmd[0], cmd)
