# Dendritic host module: lunar-qualia (ASUS TUF A14 FA401EA)
{ self, inputs, ... }:

{
  flake.nixosConfigurations.lunar-qualia = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs self; };
    modules = [
      self.nixosModules.core
      self.nixosModules.hardware-asus-tuf-a14-fa401ea
      self.nixosModules.desktop-plasma
      ./hardware.nix
      inputs.home-manager.nixosModules.home-manager
      {
        networking.hostName = "lunar-qualia";

        # Optimized CachyOS BORE Kernel with Zen 4 microarchitecture tuning
        boot.kernelPackages = inputs.nix-cachyos-kernel.legacyPackages.x86_64-linux.linuxPackages-cachyos-bore-zen4;

        # Allow Unfree Packages (Brave, Zoom, Steam, etc.)
        nixpkgs.config.allowUnfree = true;

        # Integrated Home Manager
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "backup";
        home-manager.extraSpecialArgs = { inherit inputs self; };
        home-manager.users.nnon = import ./home.nix;
      }
    ];
  };
}
