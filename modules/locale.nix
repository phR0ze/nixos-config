# Time and locale configuration
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  time.timeZone = args.timezone;
  i18n.defaultLocale = args.locale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = args.locale;
    LC_IDENTIFICATION = args.locale;
    LC_MEASUREMENT = args.locale;
    LC_MONETARY = args.locale;
    LC_NAME = args.locale;
    LC_NUMERIC = args.locale;
    LC_PAPER = args.locale;
    LC_TELEPHONE = args.locale;
    LC_TIME = args.locale;
  };
}
