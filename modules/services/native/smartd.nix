# Smartd configuration
#
# ### Description
# Monitors the S.M.A.R.T. health of attached disks via smartmontools' `smartd` daemon, logging
# warnings about failing drives to the journal.
#
# ### Notes
# - Check a disk manually with: sudo smartctl -a /dev/sdX
# - Check service status with: sudo systemctl status smartd
# --------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.services.native.smartd;
in
{
  options = {
    services.native.smartd = {
      enable = lib.mkEnableOption "Install and configure smartd disk health monitoring";
    };
  };

  config = lib.mkIf (cfg.enable) {
    services.smartd.enable = true;
  };
}
