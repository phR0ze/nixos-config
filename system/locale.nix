# Time and locale configuration
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  time.timeZone = args.systemSettings.timezone;
  i18n.defaultLocale = args.systemSettings.locale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = args.systemSettings.locale;
    LC_IDENTIFICATION = args.systemSettings.locale;
    LC_MEASUREMENT = args.systemSettings.locale;
    LC_MONETARY = args.systemSettings.locale;
    LC_NAME = args.systemSettings.locale;
    LC_NUMERIC = args.systemSettings.locale;
    LC_PAPER = args.systemSettings.locale;
    LC_TELEPHONE = args.systemSettings.locale;
    LC_TIME = args.systemSettings.locale;
  };
}

# vim:set ts=2:sw=2:sts=2
