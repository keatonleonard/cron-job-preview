#!/bin/bash
# Report runner.
#
# Scheduled in /etc/crontab to run as root every minute. It runs the status
# report script the administrator left in /opt/cron, and (via the crontab line)
# that script's output is appended to /var/log/report.log.
#
# This runner is owned by root and is NOT writable by the analyst. It is
# hardened so that a broken edit to report.sh cannot wedge the box:
#   flock   -> only one run at a time, so a slow run never piles up.
#   timeout -> a report.sh that loops forever or waits for input is killed,
#              and it gets no stdin.
exec 9>/run/report.lock
flock -n 9 || exit 0

REPORT=/opt/cron/report.sh
[ -f "$REPORT" ] || exit 0

timeout -s KILL 15 /bin/bash "$REPORT" </dev/null
