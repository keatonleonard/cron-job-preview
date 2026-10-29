# Cron Attack Lab - a disposable Linux box for ATT&CK T1053.003
# Everything the student does happens INSIDE this container. Deleting the
# container (docker compose down) throws it all away, so the lab is safe.
FROM debian:12-slim

# cron      -> the scheduler this whole lab is about
# python3   -> serves the interactive HTML page on port 8080
# nano/less -> simple editors/pagers so beginners can look at files
# procps    -> gives us 'ps' so students can see processes
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        cron python3 nano less procps ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# An unprivileged user. Students play the role of "student"; the
# privilege-escalation scenario shows how that low-privilege account can
# trick root's cron job into doing its bidding.
RUN useradd -m -s /bin/bash student

# ---------------------------------------------------------------------------
# Lab resources
# ---------------------------------------------------------------------------
RUN mkdir -p /opt/lab/payloads /opt/drop /opt/web \
    && chmod 777 /opt/drop

# "Sensitive" company files used by the exfiltration scenario.
COPY lab/company_data/ /home/student/company_data/

# A secret only root can read. Used to prove privilege escalation worked.
COPY lab/root_secret.txt /root/secret.txt
RUN chmod 600 /root/secret.txt

# The persistence "payload" + its self-healing watchdog (harmless stand-ins
# for the crypto-miner the Rocke group actually used).
COPY lab/payloads/ /opt/lab/payloads/

# A root-run "health check" script that is world-writable BY MISTAKE.
# This single misconfiguration is the privilege-escalation vulnerability.
COPY lab/system_health.sh /usr/local/bin/system_health.sh
RUN chmod 777 /usr/local/bin/system_health.sh

# The optional end-of-lab "chaos" gag.
COPY lab/chaos.sh /opt/lab/chaos.sh

# Make scripts executable.
RUN chmod +x /opt/lab/chaos.sh /opt/lab/payloads/*.sh /usr/local/bin/system_health.sh

# The interactive page.
COPY web/ /opt/web/

# The student should own their own home directory and files.
RUN chown -R student:student /home/student

# The "administrator" scheduled the health check to run every minute as root.
# (This is a normal, realistic thing an admin might do.)
RUN echo '* * * * * /usr/local/bin/system_health.sh >> /var/log/system_health.log 2>&1' | crontab -

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
