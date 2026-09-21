{ config, lib, ... }: with lib.types;
let
  cfg = config.system.env;
in
{
  imports = [
    ./bash.nix
    ./clu
    ./dircolors.nix
    ./nix.nix
    ./starship
    ./vars.nix
  ];

  options = {
    system.env = {
      machineId = lib.mkOption {
        description = lib.mdDoc ''
          Unique identifier for the local system to write to /etc/machine-id. A single newline
          terminated, hexadecimal, 32-character, lowercase value. Usually generated from a random
          source and stays constant ever more. Leave null to let systemd generate one at boot.
          You can use `dbus-uuidgen` to create one manually.
          - https://www.freedesktop.org/software/systemd/man/latest/machine-id.html
        '';
        type = nullOr str;
        default = null;
      };
      locale = lib.mkOption {
        description = lib.mdDoc "Locale to use for various identifiers";
        type = types.str;
        default = "en_US.UTF-8";
      };
      timezone = lib.mkOption {
        description = lib.mdDoc "Timezone to use for various identifiers";
        type = types.str;
        default = "Etc/GMT";
      };
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = builtins.match "[0-9a-f]{32}" cfg.machineId != null;
          message = ''
            system.env.systemd.machineId must be a 32-character lowercase hexadecimal string, got:
            "${cfg.machineId}". Generate one with `dbus-uuidgen`.
          '';
        }
      ];

      environment.etc."machine-id".text = "${cfg.machineId}\n";

      time.timeZone = cfg.timezone;
      i18n.defaultLocale = cfg.locale;
      i18n.extraLocaleSettings = {
        LC_ADDRESS = cfg.locale;
        LC_IDENTIFICATION = cfg.locale;
        LC_MEASUREMENT = cfg.locale;
        LC_MONETARY = cfg.locale;
        LC_NAME = cfg.locale;
        LC_NUMERIC = cfg.locale;
        LC_PAPER = cfg.locale;
        LC_TELEPHONE = cfg.locale;
        LC_TIME = cfg.locale;
      };
    }
  ];
}
