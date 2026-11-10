# Cron Privilege-Escalation CTF — ATT&CK T1053.003 (Scheduled Task/Job: Cron)
#
# A disposable Debian box. The player logs in as the low-privilege "analyst"
# user and escalates to root by editing a script that a root cron job runs.
# Everything lives inside the container, so nothing here can touch the host.
FROM debian:12-slim

# cron    -> the scheduler this whole challenge is about
# procps  -> 'ps' and friends, so players can look around
# less    -> a pager for reading files comfortably
# nano    -> a beginner-friendly text editor for editing the report script
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        cron procps less nano ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# The unprivileged account the player controls — their "foothold" on the box.
RUN useradd -m -s /bin/bash analyst

# ---------------------------------------------------------------------------
# The scheduled "report" the player will hijack.
# ---------------------------------------------------------------------------
# run_report.sh runs as ROOT every minute (see the /etc/crontab lines near the
# bottom). It runs the status report script in /opt/cron under a lock + timeout
# and sends its output to /var/log/report.log. It is readable by everyone but
# NOT writable by the analyst.
COPY lab/run_report.sh /usr/local/bin/run_report.sh

# The status report script that root runs. It is world-writable BY MISTAKE:
# that single misconfiguration is the whole vulnerability. The analyst can edit
# it, and root will run whatever it now contains.
RUN mkdir -p /opt/cron
COPY lab/report.sh /opt/cron/report.sh

# A pristine copy outside the writable area, so the health check can restore
# report.sh if a user deletes or empties it.
RUN mkdir -p /usr/local/share/lab
COPY lab/report.sh /usr/local/share/lab/report.sh

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
        /usr/local/bin/run_report.sh \
        /usr/local/bin/lab_health.sh \
        /usr/local/bin/lab_status.sh \
        /usr/local/sbin/gen_flag.sh \
        /usr/local/share/lab/report.sh \
        /opt/cron/report.sh \
    && chown root:root \
        /usr/local/bin/run_report.sh \
        /usr/local/bin/lab_health.sh \
        /usr/local/bin/lab_status.sh \
        /usr/local/share/lab/report.sh \
    && chmod 755 \
        /usr/local/bin/run_report.sh \
        /usr/local/bin/lab_health.sh \
        /usr/local/bin/lab_status.sh \
        /usr/local/share/lab/report.sh \
    && chown root:root /opt/cron /opt/cron/report.sh \
    && chmod 777 /opt/cron \
    && chmod 777 /opt/cron/report.sh \
    && chmod +x /usr/local/sbin/gen_flag.sh \
    && /usr/local/sbin/gen_flag.sh \
    && rm -f /usr/local/sbin/gen_flag.sh \
    && printf '\n# cron-ctf lab banner\nif [ -r /usr/local/bin/lab_status.sh ]; then . /usr/local/bin/lab_status.sh; fi\n' >> /etc/bash.bashrc \
    && printf '* * * * * root /usr/local/bin/run_report.sh >> /var/log/report.log 2>&1\n' >> /etc/crontab \
    && printf '* * * * * root /usr/local/bin/lab_health.sh >/dev/null 2>&1\n' >> /etc/crontab

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
