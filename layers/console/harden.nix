# hardened.nix provides additional hardening configuration for a public internet host
#
# ### Features
# - Bash custom shell configuration
# - Basic Nix flake and commands configuration
# --------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  host = config.host;
in
{
  # SSH access
  # ------------------------------------------------------------------------------------------------
  services.openssh = {
    enable = true;
    ports = [ 2222 ];                                 # cut down on automated scanning noise
    settings = {
      PermitRootLogin = "prohibit-password";          # root login only via key, never password
      PasswordAuthentication = false;                 # key-only auth for all users
      KbdInteractiveAuthentication = false;           # PAM can otherwise prompt for a password anyway
      LogLevel = "VERBOSE";                           # log the key fingerprint used on each auth attempt
    };
  };

  # CrowdSec: detects repeated failed sshd auth attempts (via the community ssh-bf scenario) and
  # hands decisions to the firewall bouncer below, which actually bans the offending IPs.
  services.crowdsec = {
    enable = true;
    settings.general.api.server.enable = true;   # local LAPI for the bouncer to query decisions from
    hub = {
      parsers = [ "crowdsecurity/sshd-logs" ];
      scenarios = [ "crowdsecurity/ssh-bf" ];
    };
    localConfig.acquisitions = [
      {
        source = "journalctl";
        journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
        labels.type = "syslog";
      }
    ];
  };
  services.crowdsec-firewall-bouncer.enable = true;   # applies CrowdSec's ban decisions via iptables
}
