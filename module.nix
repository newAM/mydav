{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.mydav;
in {
  options.services.mydav = {
    enable = mkEnableOption "mydav";

    ip = mkOption {
      type = types.str;
      description = ''
        IP of the WebDAV server.
      '';
    };

    port = mkOption {
      type = types.ints.u16;
      description = ''
        Port of the WebDAV server.
      '';
    };

    path = mkOption {
      type = types.path;
      example = "/var/www/webdav";
      description = ''
        Directory to serve with WebDAV.
      '';
    };

    user = mkOption {
      type = types.str;
      default = "mydav";
      description = ''
        User account under which the service runs.
      '';
    };

    group = mkOption {
      type = types.str;
      default = "mydav";
      description = ''
        Group under which the service runs.
      '';
    };
  };

  config = mkIf cfg.enable {
    users = {
      users."${cfg.user}" = {
        inherit (cfg) group;
        description = "WebDAV user";
        isSystemUser = true;
        createHome = false;
      };
      groups."${cfg.group}" = {};
    };

    systemd.services.mydav = let
      configFile = pkgs.writeText "mydav-config.json" (builtins.toJSON {
        inherit (cfg) ip port path;
      });
    in {
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      description = "My WebDAV server";
      serviceConfig = {
        Type = "idle";
        KillSignal = "SIGINT";
        ExecStart = "${pkgs.mydav}/bin/mydav ${configFile}";
        Restart = "on-failure";
        RestartSec = 10;

        User = cfg.user;
        Group = cfg.group;

        # hardening
        DevicePolicy = "closed";
        CapabilityBoundingSet = "";
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
        DeviceAllow = [];
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        BindPaths = [cfg.path];
        MemoryDenyWriteExecute = true;
        LockPersonality = true;
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "~@debug"
          "~@mount"
          "~@privileged"
          "~@resources"
          "~@cpu-emulation"
          "~@obsolete"
        ];
        ProtectProc = "invisible";
        ProtectHostname = true;
        ProcSubset = "pid";
      };
    };
  };
}
