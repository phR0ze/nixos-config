# Flatpak management
#
# Manages flatpak remotes and package installation via a systemd oneshot service.
#
{ config, lib, pkgs, ... }:
let
  xfce = config.system.xfce;
  cfg = config.apps.system.flatpak;
in
{
  options = {
    apps.system.flatpak = {
      enable = lib.mkEnableOption "Flatpak management";

      remotes = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Name of the flatpak remote.";
            };
            location = lib.mkOption {
              type = lib.types.str;
              description = "URL of the flatpak remote.";
            };
          };
        });
        default = [
          { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
        ];
        description = "List of flatpak remotes to add.";
      };

      packages = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            appId = lib.mkOption {
              type = lib.types.str;
              description = "Flatpak application ID.";
            };
            origin = lib.mkOption {
              type = lib.types.str;
              default = "flathub";
              description = "Flatpak remote origin to install from.";
            };
          };
        });
        default = [];
        description = "List of flatpak packages to install.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.flatpak.enable = true;

      systemd.services.flatpak-managed-install = {
        description = "Managed Flatpak remotes and packages";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script =
          let
            flatpak = "${pkgs.flatpak}/bin/flatpak";
            desiredState = builtins.toJSON { inherit (cfg) remotes packages; };
            stateHash = builtins.hashString "sha256" desiredState;
            stampFile = "/var/lib/flatpak-managed/.state-hash";
            remoteCommands = map (r:
              "${flatpak} remote-add --system --if-not-exists ${lib.escapeShellArg r.name} ${lib.escapeShellArg r.location}"
            ) cfg.remotes;
            installCommands = map (p:
              "${flatpak} install --system --noninteractive --or-update ${lib.escapeShellArg p.origin} ${lib.escapeShellArg p.appId}"
            ) cfg.packages;
          in
          ''
            if [ -f ${stampFile} ] && [ "$(cat ${stampFile})" = "${stateHash}" ]; then
              echo "Flatpak config unchanged, skipping."
              exit 0
            fi

            ${lib.concatStringsSep "\n" (remoteCommands ++ installCommands)}

            mkdir -p "$(dirname ${stampFile})"
            echo "${stateHash}" > ${stampFile}
          '';
      };
    })

    # XDG supporting configuration
    (lib.mkIf xfce.enable {
      xdg.portal.enable = true;
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    })
  ];
}
