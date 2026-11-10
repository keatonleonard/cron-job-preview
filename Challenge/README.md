# Cron CTF: "Scheduled for Success"

**ATT&CK Technique:** [T1053.003 - Scheduled Task/Job: Cron](https://attack.mitre.org/techniques/T1053/003/)
**Tactic:** Privilege Escalation (TA0004) · **Flag format:** `CYBER266{...}`
**Estimated time:** 10–20 minutes · **Difficulty:** Beginner

---

## The Scenario

You've landed a foothold on a company's Linux server as **`analyst`**, an
ordinary, low-privilege user. Somewhere on this box, the administrator left a
file that only **root** is allowed to read, and that file contains the flag.

Your account can't read it. But you don't always have to *be* root to get root
to do something for you. On a Unix system, **cron** (the built-in task
scheduler) quietly runs jobs on a timer, and some of those jobs run as root.
The administrator has a routine "report" job that runs as root every minute.
If you can change what that job does, you can make root reveal its secret.

> This is the exact idea behind **T1053.003**: abusing scheduled tasks. Here
> you'll use it to go from a normal user to reading a root-only file.

---

## Your Objective

Read the root-only flag file and submit the flag.

```
CYBER266{...}
```

---

## Setup

You only need **Docker Desktop** installed and running. Everything happens
inside a disposable container, so nothing you do can affect your real computer,
and you can reset at any time.

**1. Open a terminal in this `Challenge` folder.** (In File Explorer, open the
folder, copy its path from the address bar, then in PowerShell type `cd`, a
space, and that path in quotes.)

```bash
cd "C:\path\to\Scheduled-Task-Cron\Challenge"
```

**2. Build and start the challenge:**

```bash
docker compose up -d --build
```

The first build takes a minute or two. Each student's build generates its own
flag, so the flag is **not** written anywhere in these files.

**3. Get a shell on the box as `analyst`:**

```bash
docker compose exec -u analyst ctf bash
```

Confirm who you are. It should say `analyst`:

```bash
whoami
```

> **Every command in this challenge runs _inside_ that container shell**, not
> in your normal PowerShell window. If a command gives a "command not found"
> or a Windows-looking error, you're outside the container, so re-run the
> `docker compose exec` command above.

**Reset at any time** (throws the box away and rebuilds it fresh; this also
generates a brand-new flag):

```bash
docker compose down
```

```bash
docker compose up -d --build
```

**The lab watches itself.** If it ever gets into a broken state, it notices on
its own: every shell you open will print a **"THE LAB LOOKS BROKEN"** banner
with these same two reset commands. When in doubt, reset: it's quick, safe, and
loses nothing but your own experiments.

### Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| A scheduled job never seems to run | Cron only checks once a minute | Wait a full 60 seconds, then look again |
| `whoami` says `root` | You left off `-u analyst` | `exit`, then re-run the exec command with `-u analyst` |
| `cat`/`nano` gives a Windows-style error | You're in PowerShell, not the container | Run `docker compose exec -u analyst ctf bash` first |
| A **"THE LAB LOOKS BROKEN"** banner appears | Something essential stopped or was damaged | Reset with the two commands above |
| Everything is a mess | Normal while experimenting | `docker compose down`, then `docker compose up -d --build` |

---

## Rules & Tips

- **Assumed background.** This challenge assumes you're comfortable with a few
  basic Linux commands (`cd`, `ls`, `cat`) and with editing a file in a simple
  editor (`nano` is installed). Everything specific to the attack is explained
  in the hints.
- **Explore first.** Get comfortable moving around the box and reading files
  before you try anything.
- **No cracking required.** You should not brute-force, guess, or crack any
  password; the intended path does not rely on that kind of secret.
- **Cron runs on a timer.** After you make a change, you may need to **wait up
  to 60 seconds** for the scheduler to act, then check again.

---

## Hints

Try the hints in order, and only if you're stuck. The goal is to *understand*
how a scheduled task becomes a privilege-escalation tool, not just to reach the
flag.

<details>
<summary>Click to reveal Hint 1 (where cron jobs live, and how to read them)</summary>

The system-wide cron schedule lives in `/etc/crontab`, and it is readable by
**every** user. Each line is five time fields, then the **user** the job runs
as, then the command:

```
*  *  *  *  *   user   command-to-run
|  |  |  |  |
|  |  |  |  +--- day of week   (0-6)
|  |  |  +------ month          (1-12)
|  |  +--------- day of month   (1-31)
|  +------------ hour           (0-23)
+--------------- minute         (0-59)
```

Five `*`s means "every minute." Read `/etc/crontab` and look for a job that
runs **as root**. Note which script it runs and where it sends its output.

</details>

<details>
<summary>Click to reveal Hint 2 (the way in)</summary>

You found a job that runs a script **as root** every minute. You can't edit
root's crontab, but you *can* look at the script that job runs. Check its
permissions with `ls -l`.

If that script is writable by you, open it in `nano` and add a line that prints
the secret:

```bash
cat /root/flag.txt
```

Save and exit, then wait up to a minute. Root will run the script (now with
your line in it) and send the output to the job's log, which you *can* read.
You never needed to be root; you made root's own job reveal the flag.

</details>

---

## Learn More

- **[MITRE ATT&CK T1053.003: Cron](https://attack.mitre.org/techniques/T1053/003/)**: the technique this challenge demonstrates.
- **[crontab.guru](https://crontab.guru/)**: decode any cron schedule into plain English.
- **[crontab(5) man page](https://man7.org/linux/man-pages/man5/crontab.5.html)**: the official crontab file-format reference.
