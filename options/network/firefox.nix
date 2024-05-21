# Firefox configuration
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.firefox;
  xft = config.services.xserver.xft;

  lock-false = {
    Value = false;
    Status = "locked";
  };
  lock-true = {
    Value = true;
    Status = "locked";
  };
in
{
  config = lib.mkIf (cfg.enable) {
    programs.firefox = {
      languagePacks = [ "en-US" ];            # Spell checking support

      # POLICIES
      # --------------------------------------------------------------------------------------------
      # To check documentation for more configuration browse to: `about:policies#documentation`
      policies = {
        DisableTelemetry = true;              # Prevent the collection of telemetry data
        DisableFirefoxStudies = true;         # Prevent Firefox from running studies
        EnableTrackingProtection = {
          Value = true;                       # Enable 
          #Locked = true;
          Cryptomining = true;                # Blocks cryptomining scripts on websites
          EmailTracking = true;               # Blocks hidden email tracking pixels and scripts on websites
          Fingerprinting = true;              # Blocks fingerprinting scripts on websites
        };
        DisablePocket = true;                 # Disable the feature to save webpages to pocket
        DisableFirefoxAccounts = true;        # Disable account-based services like sync
        DisableAccounts = true;               # Disable account-based services like sync
        DisableFirefoxScreenshots = true;     # Disable the Firefox screenshots feature
        OverrideFirstRunPage = "";            # Set to blank to disable the first run page
        OverridePostUpdatePage = "";          # Set to blank to disable the whats new page
        DontCheckDefaultBrowser = true;       # Don't bother with checking the default browser status
        DisableSetDesktopBackground = true;   # Disable the menu command to set Desktop Background
        NoDefaultBookmarks = true;            # Disable the default bookmarks on fresh install
        OfferToSaveLoginsDefault = false;     # Don't offer to remember saved logins and passwords
        #DisplayMenuBar = "default-off";      # alternatives: "always", "never" or "default-on"
        #SearchBar = "unified";               # alternative: "separate"

        ## EXTENSIONS
        # ------------------------------------------------------------------------------------------
        # Check about:support for extension/add-on ID strings.
        # Valid strings for installation_mode are "allowed", "blocked",
        # "force_installed" and "normal_installed".
        ExtensionSettings = {
          "*".installation_mode = "blocked"; # blocks all addons except the ones specified below

          # uBlock Origin:
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
          };

          # Privacy Badger:
          "jid1-MnnxcxisBPnSXQ@jetpack" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
            installation_mode = "force_installed";
          };

        };

        ## PREFERENCES
        # ------------------------------------------------------------------------------------------
        # To check for more configuration options browse to: `about:config`
        Preferences = { 
          "browser.contentblocking.category" = { Value = "strict"; Status = "locked"; };
          "browser.ctrlTab.sortByRecentlyUsed" = lock-true;
          "extensions.pocket.enabled" = lock-false;
          "extensions.screenshots.disabled" = lock-true;
          "browser.topsites.contile.enabled" = lock-false;
          "browser.formfill.enable" = lock-false;
          "browser.search.suggest.enabled" = lock-false;
          "browser.search.suggest.addons" = lock-false;
          "browser.search.suggest.mdn" = lock-false;
          "browser.search.suggest.pocket" = lock-false;
          "browser.search.suggest.enabled.private" = lock-false;
          "browser.urlbar.suggest.quicksuggest.nonsponsored" = lock-false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = lock-false;
          "browser.urlbar.suggest.searches" = lock-false;
          "browser.urlbar.suggest.remotetab" = lock-false;
          "browser.urlbar.suggest.topsites" = lock-false;
          "browser.urlbar.suggest.trending" = lock-false;
          "browser.urlbar.suggest.yelp" = lock-false;
          "browser.urlbar.suggest.weather" = lock-false;
          "browser.urlbar.showSearchSuggestionsFirst" = lock-false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
          "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
          "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
          "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
          "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
          "browser.newtabpage.activity-stream.showSponsored" = lock-false;
          "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
          "font.default.x-western" = { Value = "${xft.serif}"; };
          "font.size.variable.x-western" = { Value = "${toString xft.serifWebSize}"; };
          "font.name.sans-serif.x-western" = { Value = "${xft.sans}"; };
          "font.name.serif.x-western" = { Value = "${xft.serif}"; };
          "font.name.monospace.x-western" = { Value = "${xft.monospace}"; };
          "font.size.monospace.x-western" = { Value = "${toString xft.monospaceSize}"; };
        };
      };
    };
  };
}
