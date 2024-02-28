# Starship configuration
#
# ### Details
# Purposefully not using the built in 'programs.starship' because when the initialization is added
# to /etc/bashrc it only checks for the 'dumb' TERM and misses typical default linux terminals for
# virtual machines like Virtual Box and looks lame because they don't have modern support. Despite
# disabling here the 'settings' option below ensures the package is installed and the configuration
# is saved and can be accessed with '${pkgs.starship}/bin/starship init bash'
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  environment.systemPackages = with pkgs; [
    starship
  ];
}

# vim:set ts=2:sw=2:sts=2
