#!/bin/bash
# Persistence "watchdog" - a harmless stand-in for what the Rocke group did.
#
# The Rocke group's real cron job re-downloaded their crypto-miner whenever a
# defender deleted it. This script does the same idea safely: if the "miner"
# is missing, it re-creates it and runs it. Nothing here mines anything or
# touches the network - the "miner" just writes a line to the lab log so you
# can SEE it running.
#
# This is the core lesson of persistence: deleting the malware is not enough.
# As long as the cron job survives, the malware keeps coming back.

TARGET=/tmp/miner.sh

if [ ! -f "$TARGET" ]; then
  cat > "$TARGET" <<'MINER'
#!/bin/bash
echo "[$(date '+%Y-%m-%d %H:%M:%S')] (miner) earning fake coins... :coin:" >> /var/log/cron-lab.log
MINER
  chmod +x "$TARGET"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] (watchdog) miner was missing - restored it!" >> /var/log/cron-lab.log
fi

# Run the miner.
"$TARGET"
