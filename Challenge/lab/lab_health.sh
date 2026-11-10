#!/bin/bash
# Lab health check.
#
# Scheduled in /etc/crontab to run as root every minute (separate from the
# report runner, so a broken edit can never stop it). It:
#   1. Writes a heartbeat the shell banner reads, proving the box is alive.
#   2. Re-asserts the conditions the challenge needs to stay solvable.
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

# The editable report script must exist and stay writable by the analyst.
mkdir -p /opt/cron
chown root:root /opt/cron 2>/dev/null
chmod 777 /opt/cron 2>/dev/null

# If report.sh is missing or has been emptied, restore the pristine (benign)
# copy so the lab stays solvable. A normal edit leaves the file non-empty, so
# this never clobbers the player's own changes.
if [ ! -s /opt/cron/report.sh ] && [ -f /usr/local/share/lab/report.sh ]; then
  cp /usr/local/share/lab/report.sh /opt/cron/report.sh
fi
chmod 777 /opt/cron/report.sh 2>/dev/null

# The runner and the flag must still be present.
[ -x /usr/local/bin/run_report.sh ] || reasons="$reasons runner-missing"
[ -f /root/flag.txt ]               || reasons="$reasons flag-missing"

if [ -z "$reasons" ]; then
  echo "OK" > "$LAB_DIR/status"
else
  echo "BROKEN:$reasons" > "$LAB_DIR/status"
fi
chmod 644 "$LAB_DIR/status"
