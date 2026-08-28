{ pkgs, ... }:
{
  packages = [
    pkgs.radicle-node
  ];

  # So the `rad` CLI finds the control socket of the user unit.
  home.sessionVariables = {
    RAD_SOCKET = "\${XDG_RUNTIME_DIR}/radicle-node/control.sock";
  };

  # radicle-node picks up the control socket from systemd via socket activation
  # (LISTEN_FDNAMES=control). See radicle-systemd/src/listen.rs in heartwood.
  systemd.sockets.radicle-node = {
    unitConfig = {
      Description = "Radicle Node Control Socket";
    };
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenStream = "%t/radicle-node/control.sock";
      FileDescriptorName = "control";
      Service = "radicle-node.service";
      SocketMode = "0660";
      DirectoryMode = "0700";
      RuntimeDirectory = "radicle-node";
      RuntimeDirectoryMode = "0700";
    };
  };

  systemd.services.radicle-node = {
    unitConfig = {
      Description = "Radicle Node";
      Documentation = [ "https://radicle.xyz/guides" ];
      # Don't crash-loop before `rad auth` has created a key.
      ConditionPathExists = [ "%h/.radicle/keys/radicle" ];
    };
    requires = [ "radicle-node.socket" ];
    after = [ "radicle-node.socket" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.radicle-node}/bin/radicle-node";
      Environment = [
        "RAD_HOME=%h/.radicle"
        "RAD_SOCKET=%t/radicle-node/control.sock"
        "RUST_LOG=info"
        "PATH=${pkgs.gitMinimal}/bin"
      ];
      KillMode = "process";
      Restart = "on-failure";
      RestartSec = "30";

      # Hide $HOME and bind-mount only the radicle data the daemon needs, so a
      # compromised daemon cannot read the rest of the user's files.
      ProtectHome = "tmpfs";
      BindPaths = [
        "%h/.radicle/storage"
        "%h/.radicle/node"
        "%h/.radicle/cobs"
      ];
      BindReadOnlyPaths = [
        "%h/.radicle/config.json"
        "%h/.radicle/keys"
        "-/etc/resolv.conf"
        "/run/systemd"
      ];
      ProtectSystem = "strict";
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      PrivateUsers = "self";
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
      AmbientCapabilities = "";
      CapabilityBoundingSet = "";
      DeviceAllow = "";
      KeyringMode = "private";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      ProcSubset = "pid";
      ProtectClock = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectProc = "invisible";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RuntimeDirectoryMode = "0700";
      SocketBindDeny = [ "any" ];
      # radicle-node binds its p2p listen port itself.
      SocketBindAllow = [ "tcp:8776" ];
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "~@aio"
        "~@chown"
        "~@keyring"
        "~@memlock"
        "~@privileged"
        "~@resources"
        "~@setuid"
      ];
      UMask = "0067";
    };
  };
}
