# Systemd configuration
#
# ### Details
# - Shutdown your system with: shutdown
# - Reboot your system with: reboot
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  machine = config.machine;
in
{
  # /etc/machine-id contains an unique identifier for the local system that is set during boot if it 
  # doesn't exist. It is a single newline terminated, hexadecimal, 32-character, lowercase value. It 
  # is usually generated from a random source and stays constant ever more. It may be set with the 
  # `systemd.machine_id=` kernel command line param or by passing the `--machine-id=` option to 
  # systemd. You can use `dbus-uuidgen` to create one manually.
  # - https://www.freedesktop.org/software/systemd/man/latest/machine-id.html
  environment.etc."machine-id".text = "${machine.id}\n";

  # Logind configuration
  # - Defaults were changed here https://github.com/NixOS/nixpkgs/pull/16021
  # - Want shutdown to kill all users process immediately for fast shutdown
  # ------------------------------------------------------------------------------------------------
  services.logind.killUserProcesses = true;
  services.logind.extraConfig = ''
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
  services.timesyncd.enable = lib.mkForce true;
}
