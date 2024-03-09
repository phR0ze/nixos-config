# Time and locale configuration
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  time.timeZone = args.settings.timezone;
  i18n.defaultLocale = args.settings.locale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = args.settings.locale;
    LC_IDENTIFICATION = args.settings.locale;
    LC_MEASUREMENT = args.settings.locale;
    LC_MONETARY = args.settings.locale;
    LC_NAME = args.settings.locale;
    LC_NUMERIC = args.settings.locale;
    LC_PAPER = args.settings.locale;
    LC_TELEPHONE = args.settings.locale;
    LC_TIME = args.settings.locale;
  };
}
