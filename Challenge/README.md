# Cron CTF — "Scheduled for Success"

**ATT&CK Technique:** [T1053.003 — Scheduled Task/Job: Cron](https://attack.mitre.org/techniques/T1053/003/)
**Tactic:** Privilege Escalation (TA0004) · **Flag format:** `CYBER266{...}`
**Estimated time:** 10–20 minutes · **Difficulty:** Beginner

---

## The Scenario

You've landed a foothold on a company's Linux server as **`analyst`** — an
ordinary, low-privilege user. Somewhere on this box, the administrator left a
file that only **root** is allowed to read, and that file contains the flag.

Your account can't read it. But you don't always have to *be* root to get root
to do something for you. On a Unix system, **cron** — the built-in task
scheduler — quietly runs jobs on a timer, and some of those jobs run as root.
If an attacker can influence *what* one of those root jobs does, they can make
root hand over its secrets.

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
inside a disposable container — nothing you do can affect your real computer,
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

Confirm who you are — it should say `analyst`:

```bash
whoami
```

> **Every command in this challenge runs _inside_ that container shell**, not
> in your normal PowerShell window. If a command gives a "command not found"
> or a Windows-looking error, you're outside the container — re-run the
> `docker compose exec` command above.

**Reset at any time** (throws the box away and rebuilds it fresh — this also
generates a brand-new flag):

```bash
docker compose down
```

```bash
docker compose up -d --build
```

**The lab watches itself.** If it ever gets into a broken state, it notices on
its own — every shell you open will print a **"THE LAB LOOKS BROKEN"** banner
with these same two reset commands. When in doubt, reset: it's quick, safe, and
loses nothing but your own experiments.

### Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| A scheduled job never seems to run | Cron only checks once a minute | Wait a full 60 seconds, then look again |
| `whoami` says `root` | You left off `-u analyst` | `exit`, then re-run the exec command with `-u analyst` |
| `crontab`/`cat` gives a Windows-style error | You're in PowerShell, not the container | Run `docker compose exec -u analyst ctf bash` first |
| A **"THE LAB LOOKS BROKEN"** banner appears | Something essential stopped or was damaged | Reset with the two commands above |
| Everything is a mess | Normal while experimenting | `docker compose down`, then `docker compose up -d --build` |

---

## Rules & Tips

- **Start by looking around.** Who are you? What can you read? What runs
  automatically on this system, and *as whom*? Unix keeps some of that
  information in files any user can read.
- **You do not need root's password**, and you should not try to brute-force or
  guess anything. The path to the flag is a **misconfiguration**, not a secret.
- **Cron runs on a timer.** After you make your move, you may need to **wait up
  to 60 seconds** for the scheduler to act.
- Think about the project's core lesson: a scheduled task that runs as root is
  only as safe as the files it is allowed to touch.

---

## Hint

<details>
<summary>Click to reveal Hint 1</summary>

Something on this box runs **as root every minute**. You can read *what* it is
and *what it runs* — the schedule and the script it points to are both
readable. You aren't meant to edit root's script. Instead, look closely at the
**permissions** of everything that script uses, and ask: is there a place the
runner pulls work from that *you* are allowed to write to?

</details>

---

## Stuck?

A full step-by-step solution is in the instructor's **walkthrough document**
(submitted separately). Try the hint and some exploring first — the goal is to
*understand* how a scheduled task becomes a privilege-escalation tool, not just
to reach the flag.

---

## Learn More

- **[MITRE ATT&CK T1053.003 — Cron](https://attack.mitre.org/techniques/T1053/003/)** — the technique this challenge demonstrates.
- **[crontab.guru](https://crontab.guru/)** — decode any cron schedule into plain English.
- **[crontab(5) man page](https://man7.org/linux/man-pages/man5/crontab.5.html)** — the official crontab file-format reference.
