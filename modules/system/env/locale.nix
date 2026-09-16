# Time and locale configuration
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }: with lib.types;
let
  cfg = config.system.env;
in
{
  options = {
    system.env = {
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

  config = {
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
  };
}
