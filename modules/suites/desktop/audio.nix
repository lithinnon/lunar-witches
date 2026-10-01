# Capability suite: High-Performance PipeWire Audio
{ ... }:

{
  flake.nixosModules.suite-desktop-audio = { ... }: {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
