# Phase 3 — labs

The actual sessions. Errors preserved.

---

## First script — `test.sh`

Goal: print current directory, check if `/etc/passwd` exists.

Attempt 1 — used `cd /etc/passwd`:
```
bash: cd: /etc/passwd: Not a directory
```
`cd` is for directories.

Attempt 2 — used `cat /etc/passwd` as the condition. Dumped the whole file instead of returning true/false. Not a test.

Attempt 3 — `test -f /etc/passwd`. Silent. Returns exit code 0 if it's a regular file. That's what a conditional needs.

```bash
shaurya@shaurya-VirtualBox:~$ ./script.sh
Phase 3: scripting started, Shaurya.
here I am: /home/shaurya
user database found.
```

---

## Log parser — `log_check.sh`

Goal: read `access.log` line by line, flag "Failed" entries, extract the IP.

First attempt had a nested for loop inside the while loop — created an infinite stream of alerts, had to Ctrl+C to stop. Then an unclosed `fi` gave `unexpected end of file`. After fixing that, the grep wasn't filtering correctly and flagged everything.

After several iterations:

```
---[ALERT!] IP 192.168.1.5 had failed access.---
---[ACCESSED!] IP 10.0.0.2 had succeeded the access. Good, Maybe. Verify!---
---[ALERT!] IP 192.168.1.5 had failed access.---
---[ALERT!] IP 8.8.8.8 had failed access.---
```

Working script is in `log_check.sh`.

---

## The counting problem

Goal: count how many times each IP failed. Extend the log parser.

Syntax errors encountered, in order:

```
./script.sh: line 8: syntax error near unexpected token `do'
```
Used `if ... ;do` instead of `if ... ;then`. `do` is for loops.

```
./script.sh: line 10: unexpected EOF while looking for matching `''
```
Unclosed quote. Hit this three times in a row.

```
./script.sh: line 10: Failed: command not found
```
`$status` expanded to `Failed` without quotes. Bash tried to execute `Failed` as a command.

```
./script.sh: line 14: 192.168.1.5: command not found
```
Passed an IP address to `sort`. Sort thought it was a filename.

The real problem: `uniq -c` counts consecutive duplicates. Running it inside a per-line loop means each IP appears once per iteration — count always returns 1. Counting has to happen after the loop, on the whole file at once.

Working:
```bash
grep 'Failed' access.log | awk '{print $1}' | sort | uniq -c | sort -nr
```
```
      2 192.168.1.5
      1 8.8.8.8
```

---

## Functions — `hero.sh`

Bug during development: wrote `[ -f "exist" ]` instead of `[ -f "$exist" ]`. Quoted the variable name as a literal string. `"exist"` is always false because no file named `exist` exists. Always `"$variable"`.

First run attempt:
```
shaurya@shaurya-VirtualBox:~$ hero access.log
hero: command not found
```
`hero` is a function inside `hero.sh`. It doesn't exist in the shell until the script runs. Use `./hero.sh`.

Working output:
```
Security Scanner v1.0
=== Found ===
=== Checking access.log ===
      1 8.8.8.8
      2 192.168.1.5
```

---

## The cron duplication bug

Added log backup logic to a cron job running every minute:
```bash
cat "/home/shaurya/aces.log" >> "/home/shaurya/aces1.log"
cat "/home/shaurya/aces1.log" >> "/home/shaurya/aces.log"
rm "aces1.log"
```

After a few minutes, counts doubled: 256, 512, 1024, 2048. The script was appending the log to a backup then appending the backup back to the original — exponential growth every run.

Lesson: never write back to a file you're reading from in an automation script. Real SIEM systems treat source logs as read-only. If the source gets modified, the forensic evidence is gone.

---

## VPC flow log analyzer

Same bash patterns, different data format:

```bash
# auth.log: IP is field 1
grep "Failed" auth.log | awk '{print $1}'

# VPC flow log: srcaddr is field 4
grep "REJECT" vpc_flow.log | awk '{print $4}'
```

Same logic. Different field number. Output:
```
Top 3 source IPs with REJECT traffic:
      7 192.168.1.5
      1 10.0.0.9
      1 10.0.0.8
Unique destination ports: 26
```

---

## Python log parser

Runs from the command line. Accepts a filename as argument. Defaults to `/var/log/auth.log`. Handles file-not-found gracefully. Scans for multiple keywords. Stops after the first match per line so one line doesn't count twice.

Script is in `log_parser.py`.
