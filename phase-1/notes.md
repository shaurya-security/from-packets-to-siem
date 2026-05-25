# Phase 1 — notes

Linux. Networking. The foundation everything else sits on.

---

## The terminal

The first thing that clicked: the terminal isn't a place where you type magic words. It's a conversation. You ask the system a question, it answers. Every command is either *asking for information* or *telling the system to change something*.

`ls -la /` asks: what's here, with full detail?

The `-l` flag means give me details. The `-a` means show hidden files too. The flags aren't decoration — they're how you shape the question.

Running `ls -la /` was the first real command I ran. The output looked like noise at first. Then I noticed the first character of every line: `d` for directory, `-` for file, `l` for symlink. That single character is Linux's entire security model in miniature.

---

## The filesystem

Linux has one tree. Everything lives under `/`. No C: drive, no D: drive.

The directories that matter for security:

- `/etc` — configuration files. SSH settings, sudo rules, the user database. This is where attackers look first after getting in.
- `/var/log` — logs. Auth logs, system logs, application logs. This is where defenders look.
- `/tmp` — temporary files, world-writable. Old privilege escalation tricks lived here.
- `/proc` — not a real directory. A live view into the kernel. `cat /proc/meminfo` shows you RAM. `cat /proc/1/status` shows you process 1.
- `/etc/passwd` — usernames, readable by everyone. That's by design.
- `/etc/shadow` — password hashes, readable only by root. That's why privilege escalation matters.

---

## Permissions

Every file has a permission string like `-rw-r--r--`. It breaks into four parts:

```
- rw- r-- r--
│  │   │   └─ others: read only
│  │   └───── group: read only
│  └───────── owner: read + write
└──────────── type: regular file
```

`chmod 600` means owner can read and write, everyone else gets nothing. I got this mostly right the first time but made one mistake: I said it protects "availability to the owner." The correction landed hard — availability means the system is *reachable when needed*, not *who has a key*. A file locked to one person isn't protecting availability, it's restricting it.

---

## Processes and services

`ps aux` lists every running process. `ss -tulpn` shows what's listening on which ports. These two commands together answer: "what is this system doing, and what doors is it leaving open?"

`systemctl status ssh` checks if a service is running. `kill <PID>` stops a process. Cron jobs schedule things to run automatically — I set one up and verified it.

---

## Networking

An IP address identifies a machine. A port identifies a service running on that machine. SSH listens on 22. HTTP on 80. HTTPS on 443.

`ip addr show` shows my interfaces and IPs. `arp -a` shows MAC-to-IP mappings of nearby devices. `traceroute 8.8.8.8` shows the path packets take across the network.

The ARP/ICMP moment: my gateway at `172.31.112.1` appeared in `arp -a` (Layer 2 — MAC resolved) but `ping` returned 100% packet loss. Contradiction. Resolution: it's alive, just filtering ICMP. Absence of ping response doesn't mean the host is down. That reasoning shows up again in Phase 5.

---

## Netcat

`nc -nv 192.168.43.91 1524`

- `-n` — skip DNS resolution, connect by IP
- `-v` — verbose, show what's happening
- `192.168.43.91` — Metasploitable VM
- `1524` — port with a bindshell

I ran it four ways: `-nv`, just `-n`, just `-v`, bare `nc`. All four connected. The flags only change what you *see during connection*, not whether the connection works. That taught me to test variables methodically — change one thing, observe, repeat.

---

## The shift

By the end of Phase 1, commands weren't magic words anymore. Each one was a question. `ls` asks "what's here?" Permissions tell you "who can touch it?" `ss -tulpn` asks "what's listening?" `nc` asks "what happens if I knock on this door?"

Investigation, not memorization.
