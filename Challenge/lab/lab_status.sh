#!/bin/bash
# Shell banner. Sourced from /etc/bash.bashrc, so it prints every time someone
# opens a shell in the container. If the lab looks broken, it tells the user
# exactly how to reset. Safe to run as any user; it only reads status files.

_lab_hb=/var/lab/heartbeat
_lab_st=/var/lab/status
_now=$(date +%s 2>/dev/null)
_broken=""

# 1. Is the scheduler alive? A stale (or missing) heartbeat means the box is
#    wedged or cron has stopped. The health check refreshes it every minute,
#    so anything older than ~2.5 minutes is a problem.
if [ -r "$_lab_hb" ]; then
  _hb=$(cat "$_lab_hb" 2>/dev/null)
  if [ -n "$_now" ] && [ -n "$_hb" ]; then
    _age=$(( _now - _hb ))
    if [ "$_age" -gt 150 ]; then
      _broken="the scheduled job has stopped running"
    fi
  fi
else
  _broken="the lab health check is not running"
fi

# 2. Did the health check flag a missing/damaged required file?
if [ -z "$_broken" ] && [ -r "$_lab_st" ]; then
  case "$(cat "$_lab_st" 2>/dev/null)" in
    BROKEN*) _broken="a required lab file is missing or damaged" ;;
  esac
fi

if [ -n "$_broken" ]; then
  printf '\n'
  printf '  ============================================================\n'
  printf '   !!  THE LAB LOOKS BROKEN -- %s.\n' "$_broken"
  printf '   !!\n'
  printf '   !!  Reset it from your HOST terminal (NOT inside this box),\n'
  printf '   !!  in the Challenge folder, one line at a time:\n'
  printf '   !!      docker compose down\n'
  printf '   !!      docker compose up -d --build\n'
  printf '   !!  Then reconnect:  docker compose exec -u analyst ctf bash\n'
  printf '  ============================================================\n\n'
else
  printf '\n  [cron-ctf] Lab is running. Goal: read the root-only flag.\n'
  printf '  If anything ever misbehaves, reset from your HOST terminal\n'
  printf '  (in the Challenge folder):\n'
  printf '      docker compose down\n'
  printf '      docker compose up -d --build\n\n'
fi

unset _lab_hb _lab_st _now _hb _age _broken
