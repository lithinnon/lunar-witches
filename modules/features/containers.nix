# Opt-in feature: rootless Podman runtime + Distrobox toolboxes
#
# Distrobox needs a container runtime, so both ship as one unit. `dockerCompat`
# maps the `docker` CLI onto Podman (AGENTS rule 5): tooling keeps saying
# `docker`, the backend is daemonless rootless Podman. Sub-uid/gid ranges for
# normal users are auto-allocated by the users-groups module
# (autoSubUidGidRange), so rootless operation needs no extra configuration.
{ ... }:

{
  flake.nixosModules.feature-containers =
    { lib, pkgs, ... }:
    {
      virtualisation.podman = {
        enable = lib.mkDefault true;
        dockerCompat = lib.mkDefault true;
      };

      # Distrobox: ephemeral distro environments sharing $HOME, backed by the
      # rootless runtime above. The nixpkgs package pre-configures
      # container_additional_volumes=/nix:/nix so host Nix paths stay visible
      # inside containers.
      environment.systemPackages = [ pkgs.distrobox ];
    };
}
