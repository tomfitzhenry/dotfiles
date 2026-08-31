{ pkgs, ... }:
{
  # Declarative equivalent of the systemd user units `git maintenance start`
  # installs on a systemd-timer system (git's builtin/gc.c:
  # systemd_timer_write_service_template / systemd_timer_write_timer_file).
  #
  # Repos opt in with `git maintenance register`, which adds them to the
  # maintenance.repo config the service iterates over. Each --schedule frequency
  # runs the tasks whose maintenance.<task>.schedule matches that frequency.
  systemd.services."git-maintenance@" = {
    unitConfig = {
      Description = "Optimize Git repositories data";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.git}/bin/git --exec-path=${pkgs.git}/libexec/git-core for-each-repo --keep-going --config=maintenance.repo maintenance run --schedule=%i";
    };
  };

  # Git's schedule gives the midnight slot to daily/weekly, so hourly skips
  # hour 0; daily skips Monday, leaving it for weekly. A fixed minute is used
  # instead of git's per-client random one, since this config is per-user.
  systemd.timers."git-maintenance@hourly" = {
    unitConfig = {
      Description = "Optimize Git repositories data";
    };
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 1..23:30:00";
      Persistent = true;
    };
  };

  systemd.timers."git-maintenance@daily" = {
    unitConfig = {
      Description = "Optimize Git repositories data";
    };
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Tue..Sun *-*-* 0:30:00";
      Persistent = true;
    };
  };

  systemd.timers."git-maintenance@weekly" = {
    unitConfig = {
      Description = "Optimize Git repositories data";
    };
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Mon 0:30:00";
      Persistent = true;
    };
  };
}
