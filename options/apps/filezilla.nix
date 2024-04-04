# Filezilla options
#
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../funcs { inherit lib; };
  cfg = config.network.filezilla.default;

  xmlfile = lib.mkIf cfg.enable
    (pkgs.writeText "filezilla.xml" ''
     <?xml version="1.0"?>
      <FileZilla3 version="3.66.4" platform="*nix">
        <Settings>
          <Setting name="Show Tree Remote">${toString (f.boolToInt cfg.show-local-tree)}</Setting>
          <Setting name="Show Tree Local">${toString (f.boolToInt cfg.show-remote-tree)}</Setting>
          <Setting name="Number of Transfers">${toString cfg.num-transfers}</Setting>
        </Settings>
      </FileZilla3>
    '');
in
{
  options = {
    network.filezilla.default = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable initial filezilla defaults settings";
      };
      show-local-tree = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Show the local tree";
      };
      show-remote-tree = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Show the remote tree";
      };
      num-transfers = lib.mkOption {
        type = types.int;
        default = 10;
        description = lib.mdDoc "Set the number of parallel transfers";
      };
    };
  };

  # Install the generated xml file
  config = lib.mkIf cfg.enable {
    files.all.".config/filezilla/filezilla.xml".copy = thunarXmlfile;
  };
}
