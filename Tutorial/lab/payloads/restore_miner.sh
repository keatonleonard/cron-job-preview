#!/bin/bash
# Recreates the miner if it is missing, then runs it.

TARGET=/tmp/miner.sh

if [ ! -f "$TARGET" ]; then
  cat > "$TARGET" <<'MINER'
#!/bin/bash
echo "[$(date '+%Y-%m-%d %H:%M:%S')] (miner) earning fake coins... :coin:" >> /var/log/cron-lab.log
MINER
  chmod +x "$TARGET"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] (watchdog) miner was missing - restored it!" >> /var/log/cron-lab.log
fi

"$TARGET"
