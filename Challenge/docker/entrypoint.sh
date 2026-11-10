#!/bin/bash
# Boots the challenge: start the cron daemon (so root's scheduled jobs actually
# run), make sure the log and health state exist, then keep the container alive.
set -e

touch /var/log/maintenance.log
chmod 644 /var/log/maintenance.log

# Make the health/heartbeat state exist and look healthy from the very first
# second, so a shell opened right after boot doesn't wrongly report "broken".
mkdir -p /var/lab
/usr/local/bin/lab_health.sh || true

# Start the cron daemon. Without this, no scheduled job ever runs.
cron

echo "=================================================================="
echo " Cron CTF is running."
echo "   Open a shell as the analyst user with:"
echo "     docker compose exec -u analyst ctf bash"
echo "=================================================================="

# Keep PID 1 alive and let 'docker compose logs' stream the maintenance log.
tail -F /var/log/maintenance.log
