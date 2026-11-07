# Capability suite: Virtualization & Hypervisors (KVM, QEMU, virtiofsd)
{ ... }:

{
  flake.nixosModules.suite-virtualisation =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.virtiofsd
      ];
    };
}
