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

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };

    bullvpn = {
      url = "path:/home/nnon/sources/github.com/lithinnon/bullvpn";
      inputs.nixpkgs.follows = "nixpkgs";
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

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [
        ./modules
        ./hosts/lunar-qualia
        ./pkgs
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
