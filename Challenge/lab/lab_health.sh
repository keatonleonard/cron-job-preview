#!/bin/bash
# Lab health check.
#
# Scheduled in /etc/crontab to run as root every minute (separate from the
# plug-in runner, so a broken plug-in can never stop it). It does three things:
#   1. Writes a heartbeat the shell banner reads, proving the box is alive.
#   2. Re-asserts the few conditions the challenge needs to stay solvable.
#   3. Records OK / BROKEN so the banner can tell the user when to reset.
#
# It never exits on error.
set +e

LAB_DIR=/var/lab
mkdir -p "$LAB_DIR"
chmod 755 "$LAB_DIR"

# Heartbeat: a fresh timestamp means cron (and the container) is healthy.
date +%s > "$LAB_DIR/heartbeat"
chmod 644 "$LAB_DIR/heartbeat"

reasons=""

# The play area must exist and stay writable by the analyst.
if [ ! -d /opt/maintenance ]; then
  mkdir -p /opt/maintenance
  reasons="$reasons maintenance-dir-missing"
fi
chown root:root /opt/maintenance 2>/dev/null
chmod 777 /opt/maintenance 2>/dev/null

# The runner and the flag must still be present and intact.
[ -x /usr/local/bin/run_maintenance.sh ] || reasons="$reasons runner-missing"
[ -f /root/flag.txt ]                    || reasons="$reasons flag-missing"

# Quietly restore the harmless sample plug-in if the user deleted it, so the
# lab always looks the way the tutorial describes. (This never touches the
# player's own planted scripts, which have different names.)
if [ ! -e /opt/maintenance/cleanup_temp.sh ] && [ -f /usr/local/share/lab/cleanup_temp.sh ]; then
  cp /usr/local/share/lab/cleanup_temp.sh /opt/maintenance/cleanup_temp.sh
  chmod 755 /opt/maintenance/cleanup_temp.sh
fi

if [ -z "$reasons" ]; then
  echo "OK" > "$LAB_DIR/status"
else
  echo "BROKEN:$reasons" > "$LAB_DIR/status"
fi
chmod 644 "$LAB_DIR/status"
