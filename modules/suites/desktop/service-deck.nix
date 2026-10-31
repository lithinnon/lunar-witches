# Capability suite: KDE Plasma Service Deck Widget
{ ... }:

{
  flake.nixosModules.suite-desktop-service-deck =
    { pkgs, ... }:
    {
      # The plasmoid itself (in-tree); the helper CLI and deck config ship
      # through the HM module below.
      environment.systemPackages = [ pkgs.plasma-widget-servicedeck ];

      home-manager.sharedModules = [
        (
          {
            config,
            lib,
            pkgs,
            ...
          }:
          let
            cfg = config.programs.plasma-service-deck;

            serviceSubmodule = lib.types.submodule {
              options = {
                id = lib.mkOption {
                  type = lib.types.str;
                  example = "asusd.service";
                  description = "Systemd unit ID.";
                };
                display_id = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  example = "kdeconnect.service";
                  description = "Optional display alias for the service unit ID.";
                };
                name = lib.mkOption {
                  type = lib.types.str;
                  example = "ASUS Control Daemon";
                  description = "Human-readable service title.";
                };
                scope = lib.mkOption {
                  type = lib.types.enum [
                    "user"
                    "system"
                  ];
                  default = "user";
                  description = "Systemd scope (user or system).";
                };
              };
            };

            groupSubmodule = lib.types.submodule {
              options = {
                id = lib.mkOption {
                  type = lib.types.str;
                  example = "hardware";
                  description = "Group identifier.";
                };
                name = lib.mkOption {
                  type = lib.types.str;
                  example = "Hardware";
                  description = "Group display name.";
                };
                icon = lib.mkOption {
                  type = lib.types.str;
                  default = "package-x-generic";
                  example = "preferences-system-hardware";
                  description = "Freedesktop icon name for group header.";
                };
                services = lib.mkOption {
                  type = lib.types.listOf serviceSubmodule;
                  default = [ ];
                  description = "List of services monitored in this group.";
                };
              };
            };

            ungroupedSubmodule = lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  default = "Ungrouped";
                  description = "Section name for ungrouped services.";
                };
                icon = lib.mkOption {
                  type = lib.types.str;
                  default = "package-x-generic";
                  description = "Freedesktop icon name for ungrouped header.";
                };
                services = lib.mkOption {
                  type = lib.types.listOf serviceSubmodule;
                  default = [ ];
                  description = "List of ungrouped services monitored in the deck.";
                };
              };
            };

            formatService =
              svc:
              lib.filterAttrs (_: v: v != null) {
                id = svc.id;
                name = svc.name;
                scope = svc.scope;
                display_id = svc.display_id;
              };

            formatGroup = grp: {
              id = grp.id;
              name = grp.name;
              icon = grp.icon;
              services = map formatService grp.services;
            };

            deckJson = {
              groups = map formatGroup cfg.groups;
              ungrouped = {
                name = cfg.ungrouped.name;
                icon = cfg.ungrouped.icon;
                services = map formatService cfg.ungrouped.services;
              };
            };
          in
          {
            options.programs.plasma-service-deck = {
              enable = lib.mkEnableOption "KDE Plasma Service Deck Widget configuration & helper";

              package = lib.mkOption {
                type = lib.types.package;
                default = pkgs.service-deck-helper;
                description = "service-deck-helper package providing the backend CLI/daemon.";
              };

              groups = lib.mkOption {
                type = lib.types.listOf groupSubmodule;
                default = [ ];
                description = "List of grouped services in Plasma Service Deck.";
              };

              ungrouped = lib.mkOption {
                type = ungroupedSubmodule;
                default = { };
                description = "Ungrouped services in Plasma Service Deck.";
              };
            };

            config = lib.mkIf cfg.enable {
              home.packages = [ cfg.package ];
              xdg.configFile."plasma-service-deck.json".text = builtins.toJSON deckJson;
            };
          }
        )
      ];
    };
}
