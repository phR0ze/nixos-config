# Printer configuration
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  services.printing = {
    enable = true;                # Installs the system-config-printer package
    cups-pdf.enable = true;       # Allow for printing to pdf
    drivers = [
      pkgs.epson-escpr2           # Support for Epson Workforce printers e.g. Epson WF-7710
    ];
  };
  #services.avahi.enable = true;
  #services.avahi.nssmdns = true;
}
