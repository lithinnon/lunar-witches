{
  description = "Essence of the Lunar Witches, their Spirit World, where the sisters resides.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs = {
        flake-compat.follows = "flake-compat";
        flake-parts.follows = "flake-parts";
      };
    };

    # Libraries / Dependencies
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [
        ./modules/core
        ./modules/hardware/asus-tuf-a14-fa401ea.nix
        ./modules/desktop/plasma.nix
        ./hosts/lunar-qualia
      ];

      perSystem = { config, pkgs, ... }: {
        formatter = pkgs.nixfmt;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixd
            nixfmt
          ];
        };
      };
    };
}
