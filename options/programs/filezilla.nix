# Filezilla options
#
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../funcs { inherit lib; };
  cfg = config.programs.filezilla;

  xmlfile = lib.mkIf cfg.enable
    (pkgs.writeText "filezilla.xml" ''
     <?xml version="1.0"?>
      <FileZilla3 version="3.66.4" platform="*nix">
        <Settings>
          <Setting name="Show Tree Remote">${toString (f.boolToInt cfg.showLocalTree)}</Setting>
          <Setting name="Show Tree Local">${toString (f.boolToInt cfg.showRemoteTree)}</Setting>
          <Setting name="Number of Transfers">${toString cfg.numTransfers}</Setting>
        </Settings>
      </FileZilla3>
    '');
in
{
  options = {
    programs.filezilla = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Install filezilla";
      };
      persist = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Persist filezilla settings across reboots";
      };
      showLocalTree = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Show the local tree";
      };
      showRemoteTree = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Show the remote tree";
      };
      numTransfers = lib.mkOption {
        type = types.int;
        default = 10;
        description = lib.mdDoc "Set the number of parallel transfers";
      };
    };
  };

  # Install the generated xml file
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ filezilla ];
    lib.mkIf (cfg.persist) files.all.".config/filezilla/filezilla.xml".copy = xmlfile;
  };
}
