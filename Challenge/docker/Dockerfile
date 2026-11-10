# Cron Privilege-Escalation CTF — ATT&CK T1053.003 (Scheduled Task/Job: Cron)
#
# A disposable Debian box. The player logs in as the low-privilege "analyst"
# user and must escalate to root by abusing a scheduled task (a cron job).
# Everything lives inside the container, so nothing here can touch the host.
FROM debian:12-slim

# cron    -> the scheduler this whole challenge is about
# procps  -> 'ps' and friends, so players can look around
# less    -> a pager for reading files comfortably
# (coreutils provides 'timeout' and 'flock' is in util-linux; both are in the
#  base image already and are used to keep the lab robust.)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        cron procps less ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# The unprivileged account the player controls — their "foothold" on the box.
RUN useradd -m -s /bin/bash analyst

# ---------------------------------------------------------------------------
# The scheduled "maintenance" system — this is what the player will abuse.
# ---------------------------------------------------------------------------
# run_maintenance.sh runs as ROOT every minute (see the /etc/crontab lines near
# the bottom). It executes every *.sh an administrator drops into
# /opt/maintenance. It is readable by everyone but NOT writable by the analyst,
# so the player is not meant to edit this runner itself.
COPY lab/run_maintenance.sh /usr/local/bin/run_maintenance.sh

# The plug-in directory the runner executes. It is world-writable BY MISTAKE.
# That single misconfiguration is the whole vulnerability: the analyst can drop
# a script here, and root's scheduled job will happily run it.
RUN mkdir -p /opt/maintenance
COPY lab/maintenance/ /opt/maintenance/

# A pristine copy of the sample plug-in, outside the writable dir, so the
# health check can restore it if a confused user deletes it.
RUN mkdir -p /usr/local/share/lab
COPY lab/maintenance/cleanup_temp.sh /usr/local/share/lab/cleanup_temp.sh

# Robustness helpers (both run as root from cron, neither writable by analyst):
#   lab_health.sh -> heartbeat + invariants + OK/BROKEN status
#   lab_status.sh -> shell banner that tells the user to reset if broken
COPY lab/lab_health.sh /usr/local/bin/lab_health.sh
COPY lab/lab_status.sh /usr/local/bin/lab_status.sh

# The flag generator. It runs at BUILD time (below) and is then deleted, so the
# generated flag value never exists anywhere in the challenge's source files.
COPY docker/gen_flag.sh /usr/local/sbin/gen_flag.sh

# Normalize line endings (in case scripts were checked out on Windows), set the
# deliberately-vulnerable ownership/permissions, generate the flag, wire up the
# shell banner, and install root's scheduled jobs.
RUN sed -i 's/\r$//' \
        /usr/local/bin/run_maintenance.sh \
        /usr/local/bin/lab_health.sh \
        /usr/local/bin/lab_status.sh \
        /usr/local/sbin/gen_flag.sh \
        /usr/local/share/lab/cleanup_temp.sh \
        /opt/maintenance/*.sh \
    && chown root:root \
        /usr/local/bin/run_maintenance.sh \
        /usr/local/bin/lab_health.sh \
        /usr/local/bin/lab_status.sh \
        /usr/local/share/lab/cleanup_temp.sh \
    && chmod 755 \
        /usr/local/bin/run_maintenance.sh \
        /usr/local/bin/lab_health.sh \
        /usr/local/bin/lab_status.sh \
        /usr/local/share/lab/cleanup_temp.sh \
    && chown root:root /opt/maintenance \
    && chmod 777 /opt/maintenance \
    && chown root:root /opt/maintenance/*.sh \
    && chmod 755 /opt/maintenance/*.sh \
    && chmod +x /usr/local/sbin/gen_flag.sh \
    && /usr/local/sbin/gen_flag.sh \
    && rm -f /usr/local/sbin/gen_flag.sh \
    && printf '\n# cron-ctf lab banner\nif [ -r /usr/local/bin/lab_status.sh ]; then . /usr/local/bin/lab_status.sh; fi\n' >> /etc/bash.bashrc \
    && printf '* * * * * root /usr/local/bin/run_maintenance.sh >> /var/log/maintenance.log 2>&1\n' >> /etc/crontab \
    && printf '* * * * * root /usr/local/bin/lab_health.sh >/dev/null 2>&1\n' >> /etc/crontab

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
