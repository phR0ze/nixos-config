# Executable helper scripts
#
# ### Details
# - Each entry deploys ./include/<name> (or an explicit `source`) as an executable link to
#   ~/.local/bin/<name>. Opt in per-script; e.g. `tt` is consumed by app wrappers (e.g.
#   `apps.dev.claude`) that shell out to it if present.
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.system.env.scripts;
in
{
  options.system.env.scripts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
      options = {
        enable = lib.mkEnableOption "Deploy the ${name} helper script to ~/.local/bin";
        source = lib.mkOption {
          type = lib.types.path;
          default = ./include/${name};
          description = lib.mdDoc "Path to the script to install";
        };
      };
    }));
    default = { };
    description = lib.mdDoc "Executable helper scripts to deploy to ~/.local/bin";
  };

  config = lib.mkMerge (lib.mapAttrsToList
    (name: script: lib.mkIf script.enable {
      files.all.".local/bin/${name}" = {
        link = script.source;
        filemode = "0755";
      };
    })
    cfg);
}
