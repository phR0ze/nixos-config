# firefight
#
# ### Purpose
# Deploys firefight, timers that run commands and sounds on a fleet of Linux machines. Each part
# is enabled on its own, so a host can be the server, a client, or both:
# - `server`   - firefight-server as a system service, with pre-configured admin token,
#                enrollment key and declarative timers (assigned to clients in the control deck)
# - `serverUi` - the control deck app, already pointed at the server with the admin token
# - `client`   - firefight-agent as a systemd user service in the graphical session, enrolling
#                itself with the shared enrollment key so no manual approval is needed
# - `clientUi` - the client display app, autostarted with the desktop session and living in the
#                system tray (closing the window hides it, it returns when a timer fires)
#
# ### Secrets
# Both keys come from this host's sops secrets (`sopsFile`, forwarded from `host.sopsFile` by
# modules/default.nix) and are installed readable by `wheel`:
#   ```yaml
#   firefight:
#     adminToken: <random>   # control deck/admin API, e.g. `openssl rand -hex 32`
#     enrollKey: <random>    # shared by the server and every client, e.g. `openssl rand -hex 32`
#   ```
# The server and every client must share the same `enrollKey`; the server and every control
# deck the same `adminToken`.
#
# ### Example
#   Server host:
#   ```nix
#   apps.system.firefight = {
#     server.enable = true;
#     serverUi.enable = true;
#     server.timers.lab-closes = {
#       name = "Lab closes";
#       duration = 15 * 60;
#       allowClientDismiss = false;
#       actions = [
#         { type = "sound"; sound = "gong"; }
#         { type = "command"; cmd = "loginctl lock-session"; afterPrevious = true; }
#       ];
#     };
#   };
#   ```
#   Then assign timers to clients in the control deck.
#
#   Client host (it shows up in the deck as its `client.name`, the hostname by default):
#   ```nix
#   apps.system.firefight = {
#     client.enable = true;
#     clientUi.enable = true;
#   };
#   ```
#
# ### Server address
# `client.server` and `serverUi.server` default to this host when the server runs here. Otherwise
# keep the address out of git in build-time args (root `args.enc.yaml` for the whole fleet, or a
# host's own); modules/default.nix forwards it to both:
#   ```yaml
#   host:
#     services:
#       firefight:
#         server: server-host:7878
#   ```
# Setting `client.server`/`serverUi.server` in a host's configuration.nix also works; if args set
# it too, use `lib.mkForce` there to override them. Note the address still ends up in the built
# unit and desktop files on each machine; args only keep it out of the repository.
#
# ### Notes
# - Declared timers are managed: every server start rewrites them, so edits made in the deck don't
#   survive a restart, and a timer removed here is deleted (and so unassigned everywhere). Timers
#   created in the deck are kept. Assignments are only ever made in the deck.
# - With no `server.timers` set, the server gets the example timers in its default. Declaring any
#   timer on a host replaces them all, and the server then deletes them.
# - Traffic is plain HTTP/WebSocket; only run this on a trusted LAN.
# - The tray needs a panel that hosts StatusNotifierItems (XFCE and KDE do; GNOME needs the
#   AppIndicator extension).
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.system.firefight;
  firefight = pkgs.firefight;

  secretPath = key: config.secret.files.${key}.path;
  usesSecrets = cfg.server.enable || cfg.client.enable || cfg.serverUi.enable;

  # Same address the agent and the deck use when the server runs on this host
  localServer = if cfg.server.enable then "localhost:${toString cfg.server.port}" else "";

  weekdays = [ "Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun" ];

  actionType = submodule {
    options = {
      type = lib.mkOption {
        description = "Play a sound or run a shell command (`sh -c`) on each assigned client";
        type = enum [ "sound" "command" ];
      };
      sound = lib.mkOption {
        description = "Bundled sound (gong, chime, bell) or an absolute path on the client";
        type = str;
        default = "gong";
      };
      volume = lib.mkOption {
        description = "Sound volume, 0.0 - 1.0";
        type = numbers.between 0.0 1.0;
        default = 0.8;
      };
      loop = lib.mkOption {
        description = ''
          Loop the sound until dismissed. Ignored (plays once) when the timer's
          `allowClientDismiss` is off, since the run must then finish on its own.
        '';
        type = bool;
        default = true;
      };
      cmd = lib.mkOption {
        description = "Shell command to run, for `type = \"command\"`";
        type = str;
        default = "";
      };
      afterPrevious = lib.mkOption {
        description = "Wait for the previous action to finish instead of starting together with it";
        type = bool;
        default = false;
      };
    };
  };

  timerType = submodule ({ name, ... }: {
    options = {
      name = lib.mkOption {
        description = "Name shown on the timer's card, defaults to its attribute name (the key)";
        type = str;
        default = name;
      };
      type = lib.mkOption {
        description = "`countdown` runs for `duration` once started; `atTime` fires at `time`";
        type = enum [ "countdown" "atTime" ];
        default = "countdown";
      };
      duration = lib.mkOption {
        description = "Countdown length in seconds";
        type = nullOr ints.positive;
        default = null;
        example = 900;
      };
      time = lib.mkOption {
        description = "Wall-clock time `HH:MM` in the server's timezone, for `atTime`";
        type = nullOr (strMatching "([01][0-9]|2[0-3]):[0-5][0-9]");
        default = null;
        example = "17:30";
      };
      repeat = lib.mkOption {
        description = "When an `atTime` timer recurs; `days` uses the `days` list";
        type = enum [ "once" "daily" "weekdays" "days" ];
        default = "once";
      };
      days = lib.mkOption {
        description = "Days for `repeat = \"days\"`";
        type = listOf (enum weekdays);
        default = [ ];
        example = [ "Mon" "Wed" ];
      };
      allowClientDismiss = lib.mkOption {
        description = ''
          Let client displays dismiss the timer while it fires. When off, the timer returns to idle
          by itself once every client has finished its actions.
        '';
        type = bool;
        default = true;
      };
      actions = lib.mkOption {
        description = "What each assigned client does when the timer finishes, in order";
        type = listOf actionType;
        default = [ ];
      };
    };
  });

  # The server's --config JSON, see the firefight README's "Pre-configured deployment"
  timerJson = key: t: {
    inherit key;
    inherit (t) name;
    kind = if t.type == "countdown"
      then { type = "countdown"; duration_secs = t.duration; }
      else {
        type = "at_time";
        inherit (t) time;
        repeat = { type = t.repeat; } // lib.optionalAttrs (t.repeat == "days") { inherit (t) days; };
      };
    actions = map (a: {
      kind = if a.type == "sound"
        then { type = "sound"; inherit (a) sound volume; loop_until_dismissed = a.loop; }
        else { type = "command"; inherit (a) cmd; };
      mode = if a.afterPrevious then "after_previous" else "parallel";
    }) t.actions;
    allow_client_dismiss = t.allowClientDismiss;
  };

  serverConfig = pkgs.writeText "firefight-server.json" (builtins.toJSON {
    timers = lib.mapAttrsToList timerJson cfg.server.timers;
  });

  timerAssertions = lib.concatLists (lib.mapAttrsToList (key: t: [
    {
      assertion = t.type != "countdown" || t.duration != null;
      message = "apps.system.firefight.server.timers.${key}: countdown timers need `duration`";
    }
    {
      assertion = t.type != "atTime" || t.time != null;
      message = "apps.system.firefight.server.timers.${key}: atTime timers need `time`";
    }
    {
      assertion = t.repeat != "days" || t.days != [ ];
      message = "apps.system.firefight.server.timers.${key}: `repeat = \"days\"` needs `days`";
    }
    {
      assertion = lib.all (a: a.type != "command" || a.cmd != "") t.actions;
      message = "apps.system.firefight.server.timers.${key}: command actions need `cmd`";
    }
  ]) cfg.server.timers);

  # Client display command line, shared by its desktop entry and autostart entry
  displayExec = lib.concatStringsSep " " ([
    "${firefight.app}/bin/firefight" "--mode=client" "--agent-port=${toString cfg.client.uiPort}"
  ] ++ lib.optional cfg.clientUi.startHidden "--start-hidden"
    ++ lib.optional (!cfg.clientUi.tray) "--no-tray");
in
{
  options = {
    apps.system.firefight = {
      sopsFile = lib.mkOption {
        description = ''
          Path to this host's sops-encrypted secrets file holding the admin token and enrollment
          key. Nullable so modules/default.nix can forward `host.sopsFile` here unconditionally -
          required via an assertion when a part that uses the secrets is enabled.
        '';
        type = nullOr path;
        default = null;
      };

      adminTokenSecretRef = lib.mkOption {
        description = "Key path within `sopsFile` holding the admin token";
        type = str;
        default = "firefight/adminToken";
      };

      enrollKeySecretRef = lib.mkOption {
        description = ''
          Key path within `sopsFile` holding the shared enrollment key. `null` disables enrollment:
          new clients then wait for approval in the control deck.
        '';
        type = nullOr str;
        default = "firefight/enrollKey";
      };

      server = {
        enable = lib.mkEnableOption "Run firefight-server as a system service";

        port = lib.mkOption {
          description = "Port the server listens on";
          type = port;
          default = 7878;
        };

        bind = lib.mkOption {
          description = "Address the server listens on";
          type = str;
          default = "0.0.0.0";
        };

        openFirewall = lib.mkOption {
          description = "Open `port` in the firewall for clients and remote control decks";
          type = bool;
          default = true;
        };

        timers = lib.mkOption {
          description = ''
            Timers managed by this config, keyed by a stable key the timer id is derived from.
            Rewritten on every server start; removing one deletes it. The defaults are examples
            and only apply while a host declares no timers: declaring any replaces the whole set
            (and the server then deletes the example timers).
          '';
          type = attrsOf timerType;
          default = {
            logout-warning-40 = {
              name = "40min logout warning";
              duration = 40 * 60;
              allowClientDismiss = true;
              actions = [ { type = "sound"; sound = "chime"; loop = true; } ];
            };
            logout-45 = {
              name = "45min logout";
              duration = 45 * 60;
              allowClientDismiss = false;
              actions = [
                { type = "sound"; sound = "gong"; }
                { type = "command"; cmd = "loginctl lock-session"; afterPrevious = true; }
              ];
            };
            logout-warning-45 = {
              name = "45min logout warning";
              duration = 45 * 60;
              allowClientDismiss = true;
              actions = [ { type = "sound"; sound = "chime"; loop = true; } ];
            };
            logout-50 = {
              name = "50min logout";
              duration = 50 * 60;
              allowClientDismiss = false;
              actions = [
                { type = "sound"; sound = "gong"; }
                { type = "command"; cmd = "loginctl lock-session"; afterPrevious = true; }
              ];
            };
          };
        };
      };

      client = {
        enable = lib.mkEnableOption "Run firefight-agent as a systemd user service";

        server = lib.mkOption {
          description = "Server address as `host:port`";
          type = str;
          default = localServer;
          defaultText = lib.literalExpression ''"localhost:''${server.port}" when server.enable'';
          example = "server-host:7878";
        };

        name = lib.mkOption {
          description = "Name this client shows up as in the control deck";
          type = str;
          default = config.host.name;
          defaultText = lib.literalExpression "config.host.name";
        };

        uiPort = lib.mkOption {
          description = "Loopback port the agent serves the client display on";
          type = port;
          default = 7879;
        };

        autoStart = lib.mkOption {
          description = "Start the agent with the graphical session";
          type = bool;
          default = true;
        };
      };

      serverUi = {
        enable = lib.mkEnableOption "Install the control deck, pointed at `serverUi.server`";

        server = lib.mkOption {
          description = "Server address the control deck connects to, as `host:port`";
          type = str;
          default = localServer;
          defaultText = lib.literalExpression ''"localhost:''${server.port}" when server.enable'';
          example = "server-host:7878";
        };
      };

      clientUi = {
        enable = lib.mkEnableOption "Install the client display for the local agent";

        autoStart = lib.mkOption {
          description = "Start the client display with the desktop session (at boot with autologin)";
          type = bool;
          default = true;
        };

        startHidden = lib.mkOption {
          description = "Start in the system tray instead of showing the window";
          type = bool;
          default = false;
        };

        tray = lib.mkOption {
          description = "Closing the window hides it to the system tray instead of quitting";
          type = bool;
          default = true;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf usesSecrets {
      assertions = [
        {
          assertion = cfg.sopsFile != null;
          message = "apps.system.firefight.sopsFile must be set when the server, client or serverUi is enabled";
        }
      ];
    })

    # Admin token: the server, and decks on this host
    (lib.mkIf (cfg.server.enable || cfg.serverUi.enable) {
      secret.files.${cfg.adminTokenSecretRef} = {
        sopsFile = cfg.sopsFile;
        group = "wheel";
        filemode = "0440";
      };
    })

    # Enrollment key: the server, and the agent on this host
    (lib.mkIf ((cfg.server.enable || cfg.client.enable) && cfg.enrollKeySecretRef != null) {
      secret.files.${cfg.enrollKeySecretRef} = {
        sopsFile = cfg.sopsFile;
        group = "wheel";
        filemode = "0440";
      };
    })

    (lib.mkIf cfg.server.enable {
      assertions = timerAssertions;

      networking.firewall.allowedTCPPorts = lib.optional cfg.server.openFirewall cfg.server.port;

      # Binding needs no network, so per this repo's networking rules it doesn't wait for one
      systemd.services.firefight-server = {
        description = "firefight timer server";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          DynamicUser = true;
          StateDirectory = "firefight";
          # Root-owned secrets handed to the dynamic user under $CREDENTIALS_DIRECTORY (%d)
          LoadCredential = [ "admin-token:${secretPath cfg.adminTokenSecretRef}" ]
            ++ lib.optional (cfg.enrollKeySecretRef != null) "enroll-key:${secretPath cfg.enrollKeySecretRef}";
          ExecStart = lib.concatStringsSep " " ([
            "${firefight.server}/bin/firefight-server"
            "--bind" "${cfg.server.bind}:${toString cfg.server.port}"
            "--data-dir" "%S/firefight"
            "--admin-token-file" "%d/admin-token"
            "--config" "${serverConfig}"
          ] ++ lib.optionals (cfg.enrollKeySecretRef != null) [ "--enroll-key-file" "%d/enroll-key" ]);
          Restart = "on-failure";
          RestartSec = 2;
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
        };
      };
    })

    (lib.mkIf cfg.client.enable {
      assertions = [
        {
          assertion = cfg.client.server != "";
          message = "apps.system.firefight.client.server must be set when the server isn't on this host";
        }
      ];

      environment.systemPackages = [ firefight.agent ];

      # Runs in the graphical session so sounds and session commands (loginctl lock-session) work.
      # Its credentials once enrolled live in ~/.config/firefight/agent.toml.
      systemd.user.services.firefight-agent = {
        description = "firefight agent";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = lib.optional cfg.client.autoStart "graphical-session.target";
        # Timer commands run through `sh -c` and expect the usual system tools
        path = [ "/run/wrappers" "/run/current-system/sw" ];
        serviceConfig = {
          ExecStart = lib.concatStringsSep " " ([
            "${firefight.agent}/bin/firefight-agent"
            "--server" cfg.client.server
            "--name" (lib.escapeShellArg cfg.client.name)
            "--ui-port" (toString cfg.client.uiPort)
          ] ++ lib.optionals (cfg.enrollKeySecretRef != null) [
            "--enroll-key-file" (secretPath cfg.enrollKeySecretRef)
          ]);
          Restart = "on-failure";
          RestartSec = 2;
        };
      };
    })

    (lib.mkIf cfg.serverUi.enable {
      assertions = [
        {
          assertion = cfg.serverUi.server != "";
          message = "apps.system.firefight.serverUi.server must be set when the server isn't on this host";
        }
      ];

      environment.systemPackages = [
        firefight.app
        (pkgs.makeDesktopItem {
          name = "firefight-deck";
          desktopName = "Firefight Control Deck";
          comment = "Configure and control firefight timers";
          exec = "${firefight.app}/bin/firefight --mode=server --server=${cfg.serverUi.server}"
            + " --token-file=${secretPath cfg.adminTokenSecretRef}";
          icon = "alarm-symbolic";
          categories = [ "Utility" ];
        })
      ];
    })

    (lib.mkIf cfg.clientUi.enable {
      environment.systemPackages = [
        firefight.app
        (pkgs.makeDesktopItem {
          name = "firefight-display";
          desktopName = "Firefight Display";
          comment = "This machine's firefight timers";
          exec = displayExec;
          icon = "alarm-symbolic";
          categories = [ "Utility" ];
        })
      ];

      # Delayed so the panel's StatusNotifierWatcher is up first, otherwise the tray icon can be
      # missed (the rustdesk module does the same)
      environment.etc."xdg/autostart/firefight-display.desktop" = lib.mkIf cfg.clientUi.autoStart {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=Firefight Display
          Terminal=false
          Exec=${pkgs.bash}/bin/sh -c "sleep 5; exec ${displayExec}"
        '';
      };
    })
  ];
}
