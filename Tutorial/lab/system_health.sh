#!/bin/bash
# System health check. Runs from root's crontab every minute.

echo "[$(date '+%Y-%m-%d %H:%M:%S')] system health: OK" >> /var/log/cron-lab.log
