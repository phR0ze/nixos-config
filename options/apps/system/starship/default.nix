# Starship configuration
#
# ### Details
# Purposefully not using the built in 'programs.starship' because when the initialization is added
# to /etc/bashrc it only checks for the 'dumb' TERM and misses typical default 'linux' TERM for
# virtual machines like Virtual Box and looks lame because they don't have modern terminal support.
# Instead configuration is done using the nix syntax '${pkgs.starship}/bin/starship init bash'
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:

let
  cfg = config.apps.system.starship;
in
{
  options = {
    apps.system.starship = {
      enable = lib.mkEnableOption "Install and configure Starship shell prompt";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      starship
    ];

    programs.bash.promptInit = ''
      # Smart term starship
      if [[ "$TERM" != "dumb" && "$TERM" != "linux" ]]; then
        export STARSHIP_CONFIG=${
          pkgs.writeText "starship.toml"
          (lib.fileContents ../../../../include/home/.config/starship.toml)
        }
        eval "$(${pkgs.starship}/bin/starship init bash)"
      fi
    '';
  };
}
