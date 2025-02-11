# Arcologout options
#
# WIP not building because python dependencies don't exist
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.arcologout;

  # Create the package adapted from Arch Linux
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=arcolinux-logout
  arcologout = pkgs.stdenvNoCC.mkDerivation rec {
    name = "arcologout";
    version = "1.0.2";
    src = pkgs.fetchFromGitHub {
      owner = "phR0ze";
      repo = "arcologout":
      rev = "v${version}";
      hash = "sha256-+O1fOL7qh/sHN1tEtIANt/+bEOCsjVmECLDBmSSQmHI=";
    };

    # Build time dependencies
    nativeBuildInputs = [ ];

    # Runtime dependencies
    buildInputs = [ pkgs.python3 pkgs.python-cairo pkgs.python-gobject ];

    buildPhase = ''
      mkdir $out
    '';

    installPhase = ''
      make PREFIX=$out install
    '';
  };

in
{
  options = {
    programs.arcologout = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Install arcologout";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {
      environment.systemPackages = with pkgs; [ arcologout ];
      #files.all.".config/smplayer/themes".link = "${smplayer-themes}/share/smplayer/themes";
    })
  ];
}
