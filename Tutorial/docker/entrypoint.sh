#!/bin/bash
# Starts the two things the lab needs - the cron daemon (which actually runs
# scheduled jobs) and the web server (which serves the interactive page) -
# then keeps the container alive.
set -e

# The shared log that lab jobs write to, so students can watch cron work.
touch /var/log/cron-lab.log /var/log/system_health.log
chmod 666 /var/log/cron-lab.log

# Start the cron daemon. Without this, scheduled jobs never run.
cron

# Serve the interactive HTML page on port 8080.
cd /opt/web
python3 -m http.server 8080 --bind 0.0.0.0 >/var/log/webserver.log 2>&1 &

echo "======================================================"
echo " Cron Attack Lab is running."
echo "   Interactive page : http://localhost:8080"
echo "   Open a terminal  : docker compose exec -u student lab bash"
echo "======================================================"

# Keep the container running and stream the shared log to 'docker compose logs'.
tail -F /var/log/cron-lab.log
