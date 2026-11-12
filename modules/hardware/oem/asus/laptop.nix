# OEM trait: ASUS Laptop Platform (Power state coordinator: Panel overdrive & SD card PCIe PM)
{ self, ... }:

{
  flake.nixosModules.hw-oem-asus-laptop =
    { pkgs, ... }:
    {
      imports = [
        self.nixosModules.hw-oem-asus-base
      ];

      environment.systemPackages = [
        pkgs.asus-power-sync
      ];

      # Native systemd one-shot service triggered at boot and on AC/battery udev events
      systemd.services.asus-power-sync = {
        description = "ASUS Hardware Power State Synchronization";
        after = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.asus-power-sync}/bin/asus-power-sync auto";
          RemainAfterExit = false;
        };
      };

      # Trigger power state sync whenever AC or USB-C PD power supply status changes
      services.udev.extraRules = ''
        SUBSYSTEM=="power_supply", ACTION=="change", TAG+="systemd", ENV{SYSTEMD_WANTS}+="asus-power-sync.service"
      '';
    };
}
