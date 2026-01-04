# keyd configuration
#
# ### Description
# [keyd](https://github.com/rvaiya/keyd) is a key remapper for linux. Map the keys from an input 
# device to a virtual device output. Provides a way to map those specialty keys to something else 
# that you can then have mapped to a function via a standard shotcut tool like XFCE's keyboard 
# shortcuts.
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.raw.keyd;
in
{
  options = {
    services.raw.keyd = {
      enable = lib.mkEnableOption "Install and configure keyd";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "1915:1025" ]; # Pepper Jobs remote identifier
        settings = {
          main = {
            homepage = "macro(leftmeta+w)";
            "leftmeta+x" = "macro(leftmeta+j)";
            "leftmeta+d" = "macro(home)";
            "leftmeta+tab" = "macro(end)";
          };
        };
      };
    };
  };
}
