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
# - Default web socket is 8443 or 6901 or 6080??
# - Configuration is at:
#   /etc/kasmvnc/kasmvnc.yaml
#   ~/.vnc/kasmvnc.yaml
#   ~/.vnc/.de-was-selected
#   ~/.vnc/config/
#   ~/.kasmpasswd
# - Create ~/.kasmpasswd: `vncpasswd -u USER -o`
# - Run with: vncserver --vnc --enable-auth --password PASSWORD --port 6901 --bind 0.0.0.0
# 
# - Ubuntu's ssl-cert for snakeoil certs
# /etc/ssl/certs/ssl-cert-snakeoil.pem: certificate file doesn't exist or isn't a file
# /etc/ssl/private/ssl-cert-snakeoil.key: certificate file doesn't exist or isn't a file
# cd /etc/ssl
# sudo openssl genpkey -algorithm RSA -out private/ssl-cert-snakeoil.key
# sudo openssl req -new -key private/ssl-cert-snakeoil.key -out certs/ssl-cert-snakeoil.csr
# sudo openssl x509 -req -days 365 -in certs/ssl-cert-snakeoil.csr -signkey private/ssl-cert-snakeoil.key -out certs/ssl-cert-snakeoil.pem
# sudo chmod 600 private/ssl-cert-snakeoil.key
# sudo chmod 644 certs/ssl-cert-snakeoil.pem

{ lib, pkgs, stdenv, fetchurl, autoPatchelfHook, makeWrapper }:

let
  # KasmVNC has a bunch of Perl scripting to orchestrate their VNC implementation
  perlModules = with pkgs.perl540Packages; [
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
  nativeBuildInputs = [
    autoPatchelfHook    # automatically patches binaries with build input libs
    makeWrapper         # provides wrapProgram for Perl module locations
    pkgs.dpkg           # provide support for uncompressing the deb package
  ];

  # Build time dependencies e.g. libs, headers
  #buildInputs = [ ];

  # Runtime dependencies e.g. dynamically linked libs
  propagatedBuildInputs = with pkgs; [
    cacert              # Bundle of X.509 certs of public CAs
    coreutils           # GNU Core Utilties e.g. base64, basename, chmod, chown etc...
    glibc               # GNU C Library
    freetype            # Font rendering engine
    hostname            # Hostname lookup utility
    libbsd              # Library of common functions found on BSD systems
    libGL               # GL vendor neutral dispatch library
    libgbm              # Open source 3D graphics library
    libjpeg             # libjpeg-turbo
    libpng              # Official reference implementation for the PNG format with animation patch
    libunwind           # Portable and efficicent API to determine the call-chain of a program
    libxcrypt-legacy    # Extended crypt library providing older libcrypt.so.1
    libyaml             # YAML 1.1 parser and emitter written in C
    openssl             # Cryptographic library that implements the SSL and TLS protocols
    openssl_3           # Cryptographic library that implements the SSL and TLS protocols
    stdenv.cc.cc        # libstdc++.so.6
    systemdLibs         # System and service manager for Linux
    xkeyboard-config    # Provides a consistent, well-structured, database of keyboard configuration data
    xorg.libX11         # Core X11 protocol client library aka Xlib
    xorg.libXau         # Functions for handling Xauthority files and entries
    xorg.libXcursor     # X11 Cursor management library
    xorg.libXdmcp       # X Display Manager Control Protocol library
    xorg.libXext        # Xlib libraryfor common extensions to the X11 protocol
    xorg.libXfixes      # Xlib library for the XFIXES extension
    xorg.libXfont2      #
    xorg.libXrandr      # Xlib resize, rotate and reflection RandR extension library
    xorg.libxshmfence   #
    xorg.libXtst        #
    xorg.xauth          #
    xorg.xkbutils       # Collection of small XKB utilities
    xorg.xdpyinfo       #
    perl                # Kasm uses a lot of perl scripting for configuration and setup
    pixman              # Low-level library for pixel manipulation
    util-linux          # System utilties for linux e.g. blkid, dmesg, fdisk, kill etc...
    whoami              # Tiny Go server that prints the os information and HTTP request to outpu
    zlib                # Lossless data-compression library
  ] ++ perlModules;

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  # Note the patch is applied to the original file struction after unpack
  # stage the file struction in 'a' and the copy to modify in 'b'
  # diff -ruN a b > ../packages/kasmvnc/vncserver.patch
  patches = [
    ./vncserver.patch
  ];

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
  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,etc,lib,share}
    cp ./etc/kasmvnc/kasmvnc.yaml $out/etc/

    # KasmVNC searches for specific binary names
    cp ./usr/bin/kasmvncserver $out/bin/vncserver
    cp ./usr/bin/kasmvncpasswd $out/bin/vncpasswd
    cp ./usr/bin/kasmvncconfig $out/bin/vncconfig
    cp ./usr/bin/Xkasmvnc $out/bin/Xvnc
    cp ./usr/bin/kasmxproxy $out/bin/xproxy

    # Stage the select desktop script
    #cp ./usr/lib/kasmvncserver/select-de.sh $out/lib/
    mkdir -p $out/builder/startup/deb
    cp ./usr/lib/kasmvncserver/select-de.sh $out/builder/startup/deb/

    cp -r ./usr/share/doc $out/share/
    cp -r ./usr/share/kasmvnc $out/share/
    cp -r ./usr/share/man $out/share/

    # KasmVNC perl module path .../lib/KasmVNC/*.pm
    cp -r ./usr/share/perl5 $out/lib/

    runHook postInstall
  '';

  # Wraps the post install binaries with:
  # - dependency upstream Perl paths
  # - dependency KasmVNC specific Perl module path
  preFixup = ''
    wrapProgram "$out/bin/vncserver" \
      --prefix KASMVNC_ETC : "$out/etc" \
      --prefix KASMVNC_SELECTDE : "$out/lib/select-de.sh" \
      --prefix KASMVNC_DEFAULTS : "$out/share/kasmvnc/kasmvnc_defaults.yaml" \
      --prefix PERL5LIB : "${pkgs.perl540Packages.makePerlPath perlModules}:$out/lib/perl5"
  '';

  meta = with lib; {
    description = "Modern web-based VNC server + client";
    homepage = "https://github.com/kasmtech/KasmVNC";
    maintainers = with maintainers; [ phR0ze ];
    platforms = platforms.linux;
  };
}
