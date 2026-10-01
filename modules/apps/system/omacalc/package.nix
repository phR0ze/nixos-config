# omacalc package
#
# Omarchy's simple Qt Quick calculator. Upstream only ships a qmake project with no install target
# or desktop entry, so the binary is installed by hand and a desktop entry is generated here.
# - Theme colors are read from ~/.local/state/omarchy/current/theme/colors.toml when present,
#   otherwise it falls back to built in light/dark colors chosen via the xdg desktop portal
#---------------------------------------------------------------------------------------------------
{ lib, stdenv, fetchFromGitHub, qt6, makeDesktopItem, copyDesktopItems }:

stdenv.mkDerivation rec {
  pname = "omacalc";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "omacom";
    repo = "omacalc";
    rev = "v${version}";
    hash = "sha256-I+WxkMz/2hCf4OpJKu99+30c0CxyxFD0M6eSLFDLs1I=";
  };

  nativeBuildInputs = [
    qt6.qmake
    qt6.wrapQtAppsHook
    copyDesktopItems
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
  ];

  # Skip upstream's tests/ subproject, only the app's .pro is needed
  qmakeFlags = [ "omacalc.pro" ];

  installPhase = ''
    runHook preInstall
    install -Dm755 omacalc $out/bin/omacalc
    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "omacalc";
      desktopName = "Omacalc";
      comment = "Simple calculator";
      exec = "omacalc";
      icon = "accessories-calculator";
      categories = [ "Utility" "Calculator" ];
    })
  ];

  meta = {
    description = "Omarchy's simple calculator";
    homepage = "https://github.com/omacom/omacalc";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "omacalc";
  };
}
