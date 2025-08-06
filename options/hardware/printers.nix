# Printer configuration
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.hardware.printers;
  machine = config.machine;
in
{
  options = {
    hardware.printers = {
      epson-wf7710 = lib.mkEnableOption "Configure Epson WF-7710 support";
      brother-hll2405w = lib.mkEnableOption "Configure Brother HL-L2405W support";
    };
  };

  config = lib.mkMerge [

    # Common configuration
    # ----------------------------------------------------------------------------------------------
    {
      services.printing = {
        enable = true;                # Installs the system-config-printer package
        cups-pdf.enable = true;       # Allow for printing to pdf
      };

      users.users.${machine.user.name}.extraGroups = [ "lp" ];

      # Enable autodiscovery of network printers
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    }

    # Brother HL-L2405W support
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.brother-hll2405w) {
      services.printing.drivers = [ pkgs.brlaser ];
    })

    # Workforce Epson WF-7710 support
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.epson-wf7710) {
      services.printing.drivers = [ pkgs.epson-escpr2 ];

      # Enable SANE scanner support
      # https://wiki.nixos.org/wiki/Scanners
      hardware.sane = {
        enable = true; 
        extraBackends = [
          pkgs.epkowa                         # Epson scanner support
          pkgs.utsushi                        # Generic scanner support
        ];
      };

      services.udev.packages = [
        pkgs.utsushi
      ];

      users.users.${machine.user.name}.extraGroups = [ "scanner" ];
    })

  ];
}
