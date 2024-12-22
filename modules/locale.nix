# Time and locale configuration
#---------------------------------------------------------------------------------------------------
{ config, ... }:
let
  machine = config.machine;
in
{
  time.timeZone = machine.timezone;
  i18n.defaultLocale = machine.locale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = machine.locale;
    LC_IDENTIFICATION = machine.locale;
    LC_MEASUREMENT = machine.locale;
    LC_MONETARY = machine.locale;
    LC_NAME = machine.locale;
    LC_NUMERIC = machine.locale;
    LC_PAPER = machine.locale;
    LC_TELEPHONE = machine.locale;
    LC_TIME = machine.locale;
  };
}
