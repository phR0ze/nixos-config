# Jellyfin desktop client wrapper
#
# **egl**: under X11 Qt defaults to a GLX context, which the embedded libmpv can't share VA-API
# surfaces with ("VAAPI hwdec only works with OpenGL or Vulkan backends"), so it falls back to
# vaapi-copy: every decoded frame round trips through system RAM, pegging the CPU on low end hosts.
# Forcing Qt's EGL integration enables mpv's zero-copy EGL dmabuf interop.
#
# **pipewireNode**: PipeWire node mpv's audio stream should connect to, via `PIPEWIRE_NODE` which
# libpipewire turns into the stream's `target.object`. It has to be there when the stream is
# created: WirePlumber records but doesn't act on a later move of mpv's live stream. Falls back to
# the default sink if the node doesn't exist.
#
# Wrapped via symlinkJoin rather than overriding qtWrapperArgs to avoid rebuilding from source.
#---------------------------------------------------------------------------------------------------
{ lib, symlinkJoin, makeWrapper, jellyfin-desktop, egl ? true, pipewireNode ? null }:

symlinkJoin {
  name = "jellyfin-desktop-wrapped";
  paths = [ jellyfin-desktop ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/jellyfin-desktop \
      ${lib.optionalString egl "--set QT_XCB_GL_INTEGRATION xcb_egl"} \
      ${lib.optionalString (pipewireNode != null) "--set PIPEWIRE_NODE ${pipewireNode}"}
  '';
}
