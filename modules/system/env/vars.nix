# Environment configuration
#
# ### Details
# - These changes get saved in /etc/set-environment or the session variables
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.system.env;
in
{
  options = {
    system.env = {
      vars.enable = lib.mkEnableOption "Enable standard environment variables";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.vars.enable) {

      # Add ~/.local/bin to the PATH in /etc/set-environment
      environment.localBinInPath = true;

      # Simple static environment variables without any variable expansion
      # environment.variables

      # Use for more complicated environment values that need variable expansion
      environment.sessionVariables ={

        # $XDG_BIN_HOME is a de facto extension to the XDG base directory spec defining where user-specific
        # executables should be stored. Not part of the official spec, but widely honored by install scripts.
        XDG_BIN_HOME = "$HOME/.local/bin";

        # $XDG_CACHE_HOME defines the base directory relative to which user-specific non-essential data files
        # should be stored. If $XDG_CACHE_HOME is either not set or empty, a default equal to $HOME/.cache
        # should be used.
        XDG_CACHE_HOME = "$HOME/.cache";

        # $XDG_CONFIG_HOME defines the base directory relative to which user-specific configuration files
        # should be stored. If $XDG_CONFIG_HOME is either not set or empty, a default equal to $HOME/.config
        # should be used.
        XDG_CONFIG_HOME = "$HOME/.config";

        # $XDG_DATA_HOME defines the base directory relative to which user-specific data files should be
        # stored. If $XDG_DATA_HOME is either not set or empty, a default equal to $HOME/.local/share should
        # be used.
        XDG_DATA_HOME = "$HOME/.local/share";

        # $XDG_STATE_HOME defines the base directory relative to which user-specific state files should be
        # stored. If $XDG_STATE_HOME is either not set or empty, a default equal to $HOME/.local/state should
        # be used.
        XDG_STATE_HOME = "$HOME/.local/state";
      };
    })
  ];
}
