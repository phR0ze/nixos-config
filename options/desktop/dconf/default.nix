# dconf options
#
# ### Details
# - implemented in nixpkgs/nixos/modules/programs/dconf.nix
# - run `dconf watch /` to monitor changes
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.programs.dconf;

in
{
  options = {
    services.dconf.gtk = {
      orderDirsFirst = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Order directories before files in file pickers";
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [
      gnome.dconf-editor
    ];

    # Inspiration
    # https://github.com/eribertto/wimpy-nix-config/blob/28a66113895abce9baa20a70f85d3ced0148a9c1/nixos/_mixins/desktop/gnome/default.nix#L52
    programs.dconf.profiles = {
      user.databases = [{
        settings = with lib.gvariant; {
          "ca/desrt/dconf-editor" = {
            show-warning = false;
          };

          # GTK 3 support
          "org/gtk/settings/file-chooser" = {
            show-hidden = true;
            sort-directories-first = true;
          };

          # GTK 4 support
          "org/gtk/gtk4/settings/file-chooser" = {
            show-hidden = true;
            sort-directories-first = true;
          };
        };
      }];
    };
  };
}
