# Systemd configuration
#
# ### Details
# - Shutdown your system with: shutdown
# - Reboot your system with: reboot
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  # Logind configuration
  # - Defaults were changed here https://github.com/NixOS/nixpkgs/pull/16021
  # - Want shutdown to kill all users process immediately for fast shutdown
  # ------------------------------------------------------------------------------------------------
  services.logind.extraConfig = ''
    KillUserProcesses=yes
    UserStopDelaySec=0
  '';

  # Journald configuration
  # ------------------------------------------------------------------------------------------------
  services.journald.extraConfig = ''
    SystemMaxUse=256M
  '';

  # Timesyncd configuration
  # Defaults are fine
  # ------------------------------------------------------------------------------------------------
  #services.timesyncd.extraConfig = '' '';
}
