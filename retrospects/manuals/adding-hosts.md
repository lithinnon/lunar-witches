# Adding a New Machine to the Flake

> **Scope:** Multi-Host Dendritic Flake Extension Manual  
> **Reference Architecture:** [ADR 0001: Dendritic Flake Pattern](../adr/0001-dendritic-flake-pattern.md) & [ADR 0010: Six-Tier Decomposition](../adr/0010-six-tier-dendritic-decomposition.md)

---

## Step-by-Step Procedure

To introduce a new host (e.g. `lunar-station`):

### 1. Create Partition Manifest (`hosts/lunar-station/hardware.nix`)
```nix
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  # Declare fileSystems, swapDevices, boot.initrd.availableKernelModules
}
```

### 2. Create Leaf Composition (`hosts/lunar-station/default.nix`)
```nix
{ self, inputs, ... }:
{
  flake.nixosConfigurations.lunar-station = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs self; };
    modules = [
      ./hardware.nix
      self.nixosModules.core
      self.nixosModules.role-desktop
      # Compose hardware traits
      self.nixosModules.hw-cpu-amd
      self.nixosModules.hw-gpu-amd
      # Compose software suites
      self.nixosModules.suite-desktop-plasma
      self.nixosModules.suite-development
      # Attach user
      inputs.home-manager.nixosModules.home-manager
      self.nixosModules.user-nnon
      ({ pkgs, ... }: {
        networking.hostName = "lunar-station";
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [ self.overlays.default ];
      })
    ];
  };
}
```

### 3. Register Host in `flake.nix`
Add `./hosts/lunar-station` to the `imports` list in [`flake.nix`](../../flake.nix).

### 4. Create Device Profile
Create `~/.agents/devices/lunar-station.md` documenting its CPU, GPU, memory, and swap layout.
