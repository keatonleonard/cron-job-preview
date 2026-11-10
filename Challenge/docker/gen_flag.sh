#!/bin/bash
# Generates the CTF flag at image BUILD time and stores it where only root can
# read it (/root/flag.txt, mode 600). Because the value is produced here rather
# than written into the repository, the flag never appears in the challenge's
# source files — reading the repo does not reveal it.
#
# The flag always reads as cron_jobs_rock! with random leet substitutions and
# capitalization, and always ends in '!'. For example:
#   CYBER266{Cr0n_J0b5_R0ck!}
#   CYBER266{cROn_jOb5_r0cK!}
set -e

# Randomly leet-substitute and re-case a single word, keeping it readable.
leet_word() {
  local word="$1" out="" ch i
  for (( i=0; i<${#word}; i++ )); do
    ch="${word:$i:1}"
    case "$ch" in
      o) (( RANDOM % 2 )) && ch="0" ;;
      a) (( RANDOM % 2 )) && ch="4" ;;
      e) (( RANDOM % 2 )) && ch="3" ;;
      s) (( RANDOM % 2 )) && ch="5" ;;
    esac
    # Random capitalization for letters that are still alphabetic.
    if [[ "$ch" =~ [a-z] ]] && (( RANDOM % 2 )); then
      ch="${ch^^}"
    fi
    out+="$ch"
  done
  printf '%s' "$out"
}

flag="CYBER266{$(leet_word cron)_$(leet_word jobs)_$(leet_word rock)!}"

printf '%s\n' "$flag" > /root/flag.txt
chown root:root /root/flag.txt
chmod 600 /root/flag.txt
