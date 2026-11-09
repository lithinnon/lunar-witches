# Dendritic host manifest: lunar-qualia (ASUS TUF A14 FA401EA)
{
  self,
  inputs,
  ...
}:

let
  baseModules = [
    # 1. Physical Disks & Declarative Partitions (Disko & Hardware)
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./hardware.nix

    # 2. Universal System Foundation
    self.nixosModules.core

    # 3. Form Factor Role
    self.nixosModules.role-laptop

    # 4. Hardware Traits
    self.nixosModules.hw-cpu-amd
    self.nixosModules.hw-gpu-amd-integrated
    self.nixosModules.hw-memory-zswap
    self.nixosModules.hw-bluetooth
    self.nixosModules.hw-oem-asus-laptop
    self.nixosModules.hw-peripheral-yubikey
    self.nixosModules.hw-peripheral-keychron

    # 5. Opt-in Features for this machine
    self.nixosModules.feature-syncthing
    self.nixosModules.feature-chulawifi
    self.nixosModules.feature-openssh
    self.nixosModules.feature-sops

    # 6. Workload Suites
    self.nixosModules.suite-desktop-plasma
    self.nixosModules.suite-desktop-apps
    self.nixosModules.suite-education-kafae
    self.nixosModules.suite-gaming
    self.nixosModules.suite-ai-rocm
    self.nixosModules.suite-ai-claude
    self.nixosModules.suite-ai-antigravity
    self.nixosModules.suite-ai-mattpocock-skills
    self.nixosModules.suite-ai-pi
    self.nixosModules.suite-ai-deepseek-harness
    self.nixosModules.suite-ai-open-webui
    self.nixosModules.suite-ai-local
    self.nixosModules.suite-ai-prose
    self.nixosModules.suite-development
    self.nixosModules.suite-development-gamedev

    # 7. User Profile
    inputs.home-manager.nixosModules.home-manager
    self.nixosModules.user-nnon

    # 8. External Infrastructure (Chaotic Nyx, Brave Browser)
    inputs.chaotic.nixosModules.default
    inputs.brave-browser.nixosModules.default

    # 9. Host-Specific Overrides & Arbitrary Parameters
    ({ config, pkgs, ... }: {
      networking.hostName = "lunar-qualia";

      users.users.nnon.linger = true;

      # Optimized CachyOS Zen 4 Kernel with Clang ThinLTO via Chaotic Nyx
      boot.kernelPackages = pkgs.linuxPackages_cachyos-lto-znver4;

      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [ self.overlays.default ];

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      home-manager.extraSpecialArgs = { inherit inputs self; };

      # Machine-Specific Parameters for 32GB RAM Strix Halo
      # 5,862,940 pages == 24,014,602,240 bytes (approx 22.365 GiB / 24.014 GB)
      hardware.amdgpu.integrated = {
        enable = true;
        ttmPagesLimit = 5862940;
        overrideGfxVersion = "11.5.1";
        rocmArch = "gfx1151";
      };

      # Firmware loses the SD reader's subsystem IDs in S0i3; pciehp would remove the reader and
      # hang resume on a mounted card. Cache the post-S0i3 IDs at boot (ADR 0018).
      boot.extraModulePackages = [
        (config.boot.kernelPackages.callPackage ../../pkgs/rtsx-subsystem-ids { })
      ];
      boot.kernelModules = [ "rtsx_subsystem_ids" ];

      hardware.amdgpu.development.enable = true;

      services.syncthing.enable = true;

      suites.ai.rocm = {
        enable = true;
        gfx = "gfx1151";
      };

      suites.desktop.plasma.sddm.background = ./assets/sddm-wallpaper.png;
    })
  ];
in
{
  flake.nixosConfigurations = {
    # Full host with conditional spirit-world overlay
    lunar-qualia = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs self; };
      modules = baseModules ++ [
        (
          if (builtins.pathExists ../../spirit-world/default.nix) then ../../spirit-world/default.nix else { }
        )
      ];
    };

    # Standalone public fallback host (evaluates purely without spirit-world)
    lunar-qualia-standalone = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs self; };
      modules = baseModules;
    };
  };
}
