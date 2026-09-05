# Time and locale configuration
#---------------------------------------------------------------------------------------------------
{ config, ... }:
let
  host = config.host;
in
{
  time.timeZone = host.timezone;
  i18n.defaultLocale = host.locale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = host.locale;
    LC_IDENTIFICATION = host.locale;
    LC_MEASUREMENT = host.locale;
    LC_MONETARY = host.locale;
    LC_NAME = host.locale;
    LC_NUMERIC = host.locale;
    LC_PAPER = host.locale;
    LC_TELEPHONE = host.locale;
    LC_TIME = host.locale;
  };
}
