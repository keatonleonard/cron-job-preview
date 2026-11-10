#!/bin/bash
# Example maintenance plug-in. The runner executes this as root every minute.
# It only records that maintenance ran — a normal, harmless housekeeping task.
# Its real job here is to show you the pattern: scripts in this folder get run,
# automatically, as root.
echo "[$(date '+%Y-%m-%d %H:%M:%S')] maintenance: temp cleanup completed" >> /var/log/maintenance.log
