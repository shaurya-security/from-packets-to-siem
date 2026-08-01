# Phase 2 — labs

---

## The Metasploitable attack

Target: `192.168.43.91` (Metasploitable 2 VM)

```bash
# Reconnaissance — scan for open ports and service versions
nmap -sV 192.168.43.91
```

Selected output:
```
PORT     STATE SERVICE     VERSION
21/tcp   open  ftp         vsftpd 2.3.4
22/tcp   open  ssh         OpenSSH 4.7p1
23/tcp   open  telnet      Linux telnetd
80/tcp   open  http        Apache httpd 2.2.8
1524/tcp open  bindshell   Metasploitable root shell
3306/tcp open  mysql       MySQL 5.0.51a
5900/tcp open  vnc         VNC protocol 3.3
```

Port 1524 identified itself as "Metasploitable root shell" in the nmap output. The service database knew what it was.

```bash
# Initial access — connect to the bindshell
nc -nv 192.168.43.91 1524
```

```
Connection to 192.168.43.91 1524 port [tcp/*] succeeded!
root@metasploitable:/# whoami
root
root@metasploitable:/# exit
```

No password prompt. No authentication. Direct root shell.

**Kill chain mapping for this attack:**

| Stage | What happened |
|-------|--------------|
| Reconnaissance | `nmap -sV` found port 1524 with a bindshell |
| Weaponization | Already done — bindshell was pre-installed |
| Delivery | `nc` TCP connection to port 1524 |
| Exploitation | No exploit needed — shell handed over on connection |
| Actions | `whoami` — confirmed root, then exited |

**What was missing at each defensive layer:**

| Missing control | What it would have done |
|----------------|------------------------|
| Firewall rule blocking 1524 | Attacker never reaches the service |
| Authentication on the bindshell | Connection doesn't automatically grant access |
| Service running as non-root | Shell would land as limited user, not root |
| IDS watching for shell connections | Alert fires even if attack succeeds |

---

## CIA triad correction

Initial answer for "what does `chmod 600` protect?": all three — confidentiality (others can't read), integrity (others can't write), availability (owner can still access).

The correction: availability isn't about one person having access. It's about authorized users being able to reach the data when they need it. `chmod 600` on a shared resource *breaks* availability for everyone else who legitimately needs it.

Worked through the clarification:

- `chmod 000` — protects confidentiality and integrity perfectly. Breaks availability for everyone including the owner. Ghost file.
- `chmod 600` on a web server config — the web process (running as `www-data`) can't read it. Availability failure. Service breaks.

The bank vault version: `chmod 600` locks the vault and gives only one person the key. Good for confidentiality and integrity. But if that person is unavailable, so is the vault.

---

## Threat/vulnerability/risk — self-classification

Scenario: Metasploitable VM, port 1524 open with root bindshell.

My classification:
- Threat: "I am the threat on WSL2 Ubuntu" — the attacker in this scenario is me
- Vulnerability: port 1524 open with no authentication, gives root
- Risk: "Catastrophe... or just meh — my Metasploitable has nothing serious in it"

That nuance was noted: the technical risk is maximal (no auth, root access). The business risk is minimal (lab VM, zero value assets). Risk assessment requires both dimensions.

---

## Defense in depth — the iptables check

```bash
sudo iptables -L -n -v
```

Output showed `Chain INPUT (policy ACCEPT)` — all traffic accepted, no rules configured. This is a system with zero host-based firewall configuration. Combined with the open bindshell and no authentication, it demonstrated what zero defensive layers looks like in practice.

The three layers I named for a cloud server: perimeter firewall, host-based firewall, authentication. Correct as a baseline. In Phase 4, the actual implementation used Security Groups (perimeter), IAM (authentication), and CloudTrail (detection) — the same concepts at cloud scale.
