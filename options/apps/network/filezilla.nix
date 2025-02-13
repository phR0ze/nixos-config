# Filezilla options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.apps.network.filezilla;

  xmlfile = lib.mkIf cfg.enable (pkgs.writeText "filezilla.xml" ''
    <?xml version="1.0"?>
    <FileZilla3 version="3.66.4" platform="*nix">
      <Settings>
        <Setting name="Show Tree Remote">${toString (f.boolToInt cfg.showLocalTree)}</Setting>
        <Setting name="Show Tree Local">${toString (f.boolToInt cfg.showRemoteTree)}</Setting>
        <Setting name="Number of Transfers">${toString cfg.numTransfers}</Setting>
		    <Setting name="Size format">${toString cfg.fileSizeFormat}</Setting>
      </Settings>
    </FileZilla3>
  '');
in
{
  options = {
    apps.network.filezilla = {
      enable = lib.mkEnableOption "Install and configure filezilla";

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
      fileSizeFormat = lib.mkOption {
        type = types.int;
        default = 2;
        description = lib.mdDoc ''
          Set the file size format.
          0 Display size in bytes
          1 IEC binary prefixes (e.g. 1 KiB = 1024 bytes)
          2 Binary prefixes using SI symbols (e.g. 1 KB = 1024 bytes)
          3 Decimal prefixes using SI symbols (e.g. 1 KB = 1000 bytes)
        '';
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ filezilla ];

    files.all.".config/filezilla/filezilla.xml".weakCopy = xmlfile;
  };
}
