# Hardware trait: Bluetooth sleep & autosuspend quirks
{ ... }:

{
  flake.nixosModules.hw-bluetooth = { ... }: {
    boot.extraModprobeConfig = ''
      options btusb enable_autosuspend=N
    '';
  };
}
