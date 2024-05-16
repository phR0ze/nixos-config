# Import all the options
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
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
    ./utils
    ./virtualization
  ];

  options = {
    deployment.type = {
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
