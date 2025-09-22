# KasmVNC
#
# KasmVNC provides remote web-based access to a Desktop or application. While VNC is in the name, 
# KasmVNC differs from other VNC variants in that it doesn't follow the VNC RFB specification 
# from the RFB specification which defines VNC, in order to support modern technologies and increase 
# security. KasmVNC is accessed by users from any modern browser and does not support legacy VNC 
# viewer applications. KasmVNC uses a modern YAML based configuration at the server and user level, 
# allowing for ease of management.
#
# ### Packaging
# - Inspired by [Arch Linux](https://aur.archlinux.org/packages/kasmvncserver-bin)

{ lib, stdenv, fetchurl,
  pkgs,
  dpkg,               # provide support for uncompressing the deb package
  makeWrapper,        # provides wrapProgram for Perl module locations
  cacert,             # 
  freetype,           # >=2.2.1
  libbsd,             # >=0.7.0
  libGL,              # 
  libjpeg,            # libjpeg-turbo
  libpng,             # >=1.6.2
  libunwind,          #
  libxcrypt-legacy,   # >=4.1.0' 
  libX11,             # >=1.4.99.1
  libXau,             # >=1.0.9
  libXcursor,         # >1.1.2
  libXdmcp,           #
  libXfixes,          #
  libXrandr,          # >=1.2.0
  libXext,            # 
  libyaml,            #
  openssl,            # >=3.0.0.alpha1
  systemdLibs,        #
  xkbutils,           #
  xkeyboard-config,   #
  xorg,               #
  perl,               # Kasm uses a lot of perl scripting for configuration and setup
  perl540Packages,    # 
  pixman,             # >=0.30.0
  zlib,               # >=1.1.4
  # lib32-mesa
}:
let
  perlModules = with perl540Packages; [
    BHooksEndOfScope
    ClassDataInheritable
    ClassInspector
    ClassSingleton
    DateTime
    DateTimeLocale
    DateTimeTimeZone
    DevelStackTrace
    EvalClosure
    ExceptionClass
    ExporterTiny
    FileShareDir
    HashMergeSimple
    ListMoreUtils
    ModuleImplementation
    ModuleRuntime
    MROCompat
    namespaceclean
    namespaceautoclean
    PackageStash
    ParamsValidationCompiler
    RoleTiny
    Specio
    SubExporterProgressive
    SubIdentify
    Switch
    TryTiny
    VariableMagic
    YAMLTiny
  ];
in

stdenv.mkDerivation rec {
  pname = "kasmvnc";
  version = "1.3.3";

  # Download the deb similar to how Arch Linux does it
  src = fetchurl {
    url = "https://github.com/kasmtech/KasmVNC/releases/download/v${version}/kasmvncserver_jammy_${version}_amd64.deb";
    sha256 = "sha256-KkzhAFvQ0ARW4J5055TU0bubSUJcpLSq2arQ9v4ZJTI=";
  };

  # Build tooling e.g. make, autoconf
  nativeBuildInputs = [ dpkg makeWrapper ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  # Build dependencies e.g. libs, headers
  propagatedBuildInputs = [
    cacert
    freetype
    libbsd
    libGL
    libjpeg
    libpng
    libunwind
    libyaml
    libX11
    libXau
    libXcursor
    libxcrypt-legacy
    libXdmcp
    libXext
    libXfixes
    libXrandr
    openssl
    perl
    pixman
    xkeyboard-config
    xkbutils
    xorg.libxshmfence
    xorg.xauth
    xorg.libXtst
    xorg.libXfont2
    zlib
  ] ++ perlModules;

  # Nice way to debug tree structurs
  # ${pkgs.tree}/bin/tree .
  # |-- etc
  # |   `-- kasmvnc
  # |       `-- kasmvnc.yaml
  # `-- usr
  #     |-- bin
  #     |   |-- Xkasmvnc
  #               ...
  #     |-- lib
  #     |   `-- kasmvncserver
  #     |       `-- select-de.sh
  #     `-- share
  #         |-- doc
  #         |-- kasmvnc
  #         |   |-- kasmvnc_defaults.yaml
  #         |   `-- www
  #         |       |-- index.html
  #                       ...
  #         |-- man
  #         `-- perl5
  #             `-- KasmVNC
  #                 |-- CallbackValidator.pm
  #                     ....
  #                 `-- Utils.pm
  installPhase = ''
    mkdir -p $out/{bin,etc,lib,share}
    cp ./etc/kasmvnc/* $out/etc/

    # KasmVNC searches for specific binary names
    cp ./usr/bin/kasmvncserver $out/bin/vncserver
    cp ./usr/bin/kasmvncpasswd $out/bin/vncpasswd
    cp ./usr/bin/kasmvncconfig $out/bin/vncconfig
    cp ./usr/bin/Xkasmvnc $out/bin/Xvnc
    cp ./usr/bin/kasmxproxy $out/bin/xproxy

    cp -r ./usr/lib/kasmvncserver $out/lib/

    cp -r ./usr/share/doc $out/share/
    cp -r ./usr/share/kasmvnc $out/share/
    cp -r ./usr/share/man $out/share/

    cp -r ./usr/share/perl5 $out/lib/

    # Add all the standard perl module dependencies and tack on KasmVNC specific ones at the end
    for x in $out/bin/*; do
      wrapProgram "$x" --set PERL5LIB "${perl540Packages.makePerlPath perlModules}:$out/lib/perl5"
    done
  '';

  meta = with lib; {
    maintainers = with maintainers; [ phR0ze ];
    platforms = platforms.linux;
  };
}
