# Opt-in feature: OpenSSH Daemon (sshd) with hardened key-only authentication
{ self, ... }:

{
  flake.nixosModules.feature-openssh =
    { config, lib, ... }:
    {
      services.openssh = {
        enable = true;
        openFirewall = lib.mkDefault true;
        settings = {
          # Strict key-based authentication only (passwords and interactive logins disabled)
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
          X11Forwarding = false;
        };
      };
    };
}
