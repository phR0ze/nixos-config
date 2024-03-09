# Firefox configuration
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ args, ... }:

  environment.systemPackages = with pkgs; [
    firefox
  ];
}
