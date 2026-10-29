#!/bin/bash
# "System health check" installed by the administrator.
# Runs from ROOT's crontab once every minute.
#
# ---------------------------------------------------------------------------
# THE VULNERABILITY (privilege-escalation scenario):
# This file is world-writable (its permissions are 777), yet it runs as ROOT.
# That means ANY user - including the unprivileged "student" account - can
# edit it, and whatever they add will be executed by root a minute later.
# ---------------------------------------------------------------------------

echo "[$(date '+%Y-%m-%d %H:%M:%S')] system health: OK" >> /var/log/cron-lab.log
