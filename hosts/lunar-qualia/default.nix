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
    self.nixosModules.suite-gaming
    self.nixosModules.suite-ai-rocm
    self.nixosModules.suite-ai-claude
    self.nixosModules.suite-ai-antigravity
    self.nixosModules.suite-ai-open-webui
    self.nixosModules.suite-ai-opencode
    self.nixosModules.suite-ai-local
    self.nixosModules.suite-ai-prose
    self.nixosModules.suite-development
    self.nixosModules.suite-development-gamedev

    # 7. User Profile
    inputs.home-manager.nixosModules.home-manager
    self.nixosModules.user-nnon

    # 8. External Infrastructure (Chaotic Nyx)
    inputs.chaotic.nixosModules.default

    # 9. Host-Specific Overrides & Arbitrary Parameters
    ({ pkgs, ... }: {
      networking.hostName = "lunar-qualia";

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
        disableDcIps = false; # Allow AMD Display Core Idle Power States (IPS1/IPS2) for low idle power
      };

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
