# Starship configuration
#
# ### Details
# Purposefully not using the built in 'programs.starship' because when the initialization is added
# to /etc/bashrc it only checks for the 'dumb' TERM and misses typical default 'linux' TERM for
# virtual machines like Virtual Box and looks lame because they don't have modern terminal support.
# Instead configuration is done directly in the bash.nix module using the nix syntax
# '${pkgs.starship}/bin/starship init bash'
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    starship
  ];
}
