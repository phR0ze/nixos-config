# Import all the options
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }: with lib.types;
{
  imports = [
    ./desktop
    ./development
    ./files
    ./games
    ./hardware
    ./office
    ./multimedia
    ./network
    ./services
    ./virtualization
  ];

  options = {
    services.xserver.type = {
      develop = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Develop deployment type";
      };
      theater = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Theater deployment type";
      };
    };
  };
}
