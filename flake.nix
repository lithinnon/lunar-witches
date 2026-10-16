{
  description = "Essence of the Lunar Witches, their Spirit World, where the sisters resides.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
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
      url = "path:/home/nnon/Projects/github.com/lithinnon/bullvpn";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bedrock-on-linux = {
      url = "github:Wyze3306/BedrockOnLinux";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chula = {
      url = "github:MiniHarinn/chula-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    digital-egro = {
      url = "github:MiniHarinn/digital-egro";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-craftapps = {
      url = "github:olafkfreund/nix-craftapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
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
        ./shells
      ];

      perSystem = { pkgs, ... }: {
        formatter = pkgs.nixfmt;
      };
    };
}
