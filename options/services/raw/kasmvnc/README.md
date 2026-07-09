# KasmVNC

Web-based remote desktop access via any modern browser. Does not follow the standard VNC RFB
specification — legacy VNC viewers are not supported.

## Configuration Notes

- Custom package pulled from `packages/kasmvnc`
- VNC password is generated at build time from `machine.user.pass` using `vncpasswd`
- YAML-based config at server and user level
