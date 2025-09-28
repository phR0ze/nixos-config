# Selkies
#
# ### Background
# Three components are required to run Selkies GStreamer:
# 1. the standalone or distrubution provided GStreamer >= 1.22
# 2. the Python wheel package including the signaling server
# 3. the HTML5 web interface
#
# ### References
# - [Advanced Install instructions](https://github.com/selkies-project/selkies/blob/main/docs/start.md#advanced-install)
# - [Ethorbit's work](https://github.com/Ethorbit/nix-packages)
# - [CorbinWunderLich's work](https://github.com/corbinwunderlich/nixos)
#
# ### Calling syntax
# selkies = pkgs.python312Packages.callPackage ./packages/selkies {};
#
# ### Runtime
# selkies-gstreamer --addr=0.0.0.0 --port=8080 --enable_https=false --basic_auth_user=user --basic_auth_password=mypasswd --encoder=x264enc --enable_resize=false

{ 
  lib, pkgs, buildPythonPackage, callPackage, fetchurl, stdenvNoCC,
  gobject-introspection,
  gst_all_1,
  gst-python,
  libnice,
  msgpack,
  pillow,
  prometheus-client,
  psutil,
  pygobject3,
  pynput,
  watchdog,
  websockets,
  xlib,
  xorg,
  xsel,
}:

let
  version = "1.6.2";

  gputil = (callPackage ./gputil.nix { });
  basicauth = (callPackage ./basicauth.nix { });

  web = stdenvNoCC.mkDerivation {
    pname = "selkies-web";
    inherit version;

    src = fetchurl {
      url = "https://github.com/selkies-project/selkies/releases/download/v${version}/selkies-gstreamer-web_v${version}.tar.gz";
      hash = "sha256-cfzDXVn42KbGtyRywgpFryB6tWoNBVOvNLcxoulm0MY=";
    };

    installPhase = ''
      mkdir -p $out
      cp -r * $out
    '';

    meta = {
      description = "The HTML5/JS web components for Selkies-Gstreamer.";
      homepage = "https://github.com/selkies-project/selkies";
      license = lib.licenses.mpl20;
    };
  };
in
  buildPythonPackage {
    pname = "selkies";
    inherit version;
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://github.com/selkies-project/selkies/releases/download/v${version}/selkies_gstreamer-${version}-py3-none-any.whl";
      hash = "sha256-9CauCThTSS7PhXYJ79TJvSFBskxhkRhWHkIiCSdVTu4=";
    };

    nativeBuildInputs = [
      pkgs.unzip
      pkgs.zip
      gobject-introspection
    ];

    buildInputs = [
      libnice.out
      gst_all_1.gstreamer.out
      gst_all_1.gst-libav
      gst_all_1.gst-devtools
      gst_all_1.gst-vaapi
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-plugins-good
      xorg.xrandr
    ];

    propagatedBuildInputs = [
      gputil
      basicauth
      gst-python
      msgpack
      pillow
      pygobject3
      pynput
      prometheus-client
      psutil
      watchdog
      websockets
      xlib
    ];

    # Unpack the Wheel to be ready to be pateched
    unpackPhase = ''
      unzip -q "$src" -d .
    '';

    # Patch the Wheel files
    patches = [ ./selkies.patch ];

    # Repack the patched Wheel as a .whl file and stage as
    # ./dist/selkies_gstreamer-1.6.2-py3-none-any.whl to be automatically installed
    postPatch = ''
      mkdir dist
      zip -r ./dist/selkies_gstreamer-${version}-py3-none-any.whl selkies_gstreamer selkies_gstreamer-${version}.dist-info
      rm -rf selkies_gstreamer
      rm -rf selkies_gstreamer-${version}.dist-info
    '';

    postFixup = ''
      for f in $(find $out/bin/ -type f -executable); do
        wrapProgram "$f" \
          --prefix PATH ":" "${xsel}/bin:${xorg.xrandr}/bin/xrandr:$PATH" \
          --prefix SELKIES_WEB_ROOT ":" "${web}/gst-web" \
          --prefix GI_TYPELIB_PATH ":" "${gobject-introspection.out}/lib/girepository-1.0:$GI_TYPELIB_PATH" \
          --prefix GST_PY_PATH ":" "${gst-python}/lib/python3" \
          --prefix GSTREAMER_PATH ":" "${gst-python.outPath}" \
          --prefix GST_PLUGIN_SYSTEM_PATH_1_0 ":" "${libnice.out}/lib/gstreamer-1.0:${gst_all_1.gstreamer.out}/lib/gstreamer-1.0:${gst_all_1.gst-plugins-base}/lib/gstreamer-1.0:${gst_all_1.gst-plugins-good}/lib/gstreamer-1.0:${gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0:${gst_all_1.gst-plugins-ugly}/lib/gstreamer-1.0"
      done
    '';

    meta = {
      description = "Low-latency WebRTC HTML5 Remote Desktop streaming platform";
      homepage = "https://github.com/selkies-project/selkies";
      license = lib.licenses.mpl20;
    };
  }
