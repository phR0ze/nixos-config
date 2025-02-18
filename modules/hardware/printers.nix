# Printer configuration
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  # Standard printing services
  services.printing = {
    enable = true;                # Installs the system-config-printer package
    cups-pdf.enable = true;       # Allow for printing to pdf
    drivers = [
      pkgs.epson-escpr2           # Support for Epson Workforce printers e.g. Epson WF-7710
    ];
  };

  # Enable autodiscovery of network printers
  #services.avahi = {
  #  enable = true;
  #  nssmdns4 = true;
  #  openFirewall = true;
  #};
}
