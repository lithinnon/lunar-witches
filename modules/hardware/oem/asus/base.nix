# OEM trait: ASUS Base Platform (asusd & asusctl)
{ ... }:

{
  flake.nixosModules.hw-oem-asus-base = { ... }: {
    services.asusd.enable = true;
  };
}
