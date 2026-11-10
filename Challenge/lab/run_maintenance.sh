#!/bin/bash
# Maintenance runner.
#
# Scheduled in /etc/crontab to run as root every minute. It executes every
# maintenance plug-in (*.sh) that an administrator has placed in
# /opt/maintenance. Anything in that folder is run with root privileges.
#
# Hardened so that one broken plug-in cannot wedge the lab. Without these
# guards, a plug-in that loops forever, waits for input, or sleeps for a long
# time would block every later plug-in and pile up a new stuck copy every
# minute. The guards:
#   * flock    -> only one runner may be active at a time (no pile-ups).
#   * timeout  -> each plug-in is capped and given no stdin, so a hang or an
#                 interactive read is killed instead of blocking the others.

# Take a non-blocking lock. If a previous runner is still going, skip this
# minute rather than stacking a second copy on top of it.
exec 9>/run/run_maintenance.lock
flock -n 9 || exit 0

MAINT_DIR=/opt/maintenance
[ -d "$MAINT_DIR" ] || exit 0

for script in "$MAINT_DIR"/*.sh; do
  [ -e "$script" ] || continue
  # Cap each plug-in at 15 seconds and detach its stdin. A script that loops
  # forever or waits for input is force-killed; the runner then moves on.
  timeout -s KILL 15 /bin/bash "$script" </dev/null
done
