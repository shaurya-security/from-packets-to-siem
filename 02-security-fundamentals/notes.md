# Phase 2 — notes

Security isn't about stopping hackers. That's the Hollywood version. It's about protecting three things — and understanding what breaks when each one fails.

---

## CIA triad

**Confidentiality** — only authorized people see the data.
**Integrity** — the data hasn't been tampered with.
**Availability** — the data is there when you need it.

Every security decision maps to one of these. A firewall primarily protects availability (stops DDoS) and confidentiality (blocks unauthorized access). File integrity monitoring protects integrity. Encryption protects confidentiality in transit.

The triad isn't a checklist. It's a lens. When something breaks, asking "which of these three failed, and how?" cuts through the noise fast.

---

## Authentication vs authorization

Authentication: prove you're who you say you are. Password, PIN, fingerprint, SSH key.

Authorization: prove you're allowed to do what you're trying to do. Permissions, roles, policies.

These are different failures. Authentication failing means someone got in who shouldn't have. Authorization failing means someone who *did* get in can do more than they should.

The Metasploitable bindshell had no authentication — the port accepted any connection. Once inside, authorization was complete: root. That's the worst-case version of both failing simultaneously. No door check, infinite access.

Bank analogy I worked through:
- Entering the PIN → authentication (proving who you are)
- Checking your balance before allowing withdrawal → authorization (checking what you're allowed to do)

Got it right on the first try. The distinction felt obvious once the airport passport example framed it.

---

## Hashing, encryption, salting

Hashing is one-way. Same input always gives the same output. Run the same string through SHA-256 twice — identical hash. Change one character — completely different hash. You can't reverse a hash back to the original input. Used for: storing passwords, verifying file integrity.

Encryption is two-way. Data goes in, encrypted data comes out. With the right key, you reverse it. Used for: protecting data in transit (HTTPS), protecting data at rest (S3 encryption).

Salting: before hashing a password, add a unique random string to it. Two users with the same password get completely different hashes. This defeats precomputed hash tables (rainbow tables) — attackers can't crack one password and automatically crack everyone who used the same one.

The question I asked: "I'll forget the command format for salting in an hour — is that a problem?" Answer: no. Real systems use bcrypt or Argon2 and handle salting automatically. Understanding *why* salting exists matters. The plumbing details you can look up.

---

## Threats, vulnerabilities, risk

**Threat** — who or what could cause harm. Hackers, malware, disgruntled employees, hardware failure.

**Vulnerability** — a weakness that could be exploited. Open port with no authentication. Unpatched software. Weak password policy.

**Risk** — likelihood of a threat exploiting a vulnerability, multiplied by the impact.

The nuance I picked up from the Metasploitable example: technical risk and business risk are different. Port 1524 open with a root bindshell is technically catastrophic — zero authentication, complete access. But on a lab VM with nothing in it? Business risk is near zero. The asset has no value to an attacker.

This matters in a real job. A CVSS 10.0 vulnerability on a test server nobody uses is lower priority than a CVSS 6.0 on a database handling payment information.

---

## Defense in depth

No single control is enough. An attacker who gets through one layer should hit another, then another.

Metasploitable had zero layers. No firewall blocking port 1524. No authentication on the bindshell. Service running as root. No IDS watching for connections. Any one of those would have raised the cost of the attack.

Real example from Phase 4 AWS setup: S3 bucket was private by default (layer 1), IAM policy restricted which identities could access it (layer 2), S3 access logs recorded every read (layer 3), CloudTrail logged every policy change (layer 4). Remove one layer and the others still hold.

The goal isn't an unhackable system. The goal is making the attack expensive enough that attackers go find easier targets.

---

## MITRE ATT&CK

A knowledge base of real attacker behavior. Organized into tactics (the goal) and techniques (the method).

Tactics are the stages: Reconnaissance, Initial Access, Execution, Persistence, Privilege Escalation, Defense Evasion, Credential Access, Discovery, Lateral Movement, Collection, Exfiltration, Impact.

Techniques are how each tactic gets executed. T1190 is exploiting a public-facing application. T1110 is brute force. Each technique has documented procedures — actual commands and tools real attackers used.

The reveal: everything I did against Metasploitable already mapped to MITRE. `nmap -sV` was Reconnaissance (T1046 — Network Service Scanning). `nc` to port 1524 was Initial Access (T1190). `whoami` was Discovery (T1033). I was following the pattern without knowing the pattern's name.

In a SOC, when an alert fires, the first question is: what MITRE tactic is this? That context determines what to look for next.

---

## The attack lifecycle

Reconnaissance → Weaponization → Delivery → Exploitation → Installation → Command and Control → Actions on Objectives.

Each stage has a defender's response:

| Stage | How to stop it |
|-------|---------------|
| Reconnaissance | Firewall, IDS, hide service versions |
| Delivery | Email filtering, web proxies |
| Exploitation | Patch, remove unnecessary services, require authentication |
| Installation | File integrity monitoring |
| C2 | Egress filtering, DNS monitoring |
| Actions on objectives | Least privilege, data classification, backups |

You can't stop every attack. But you can interrupt it at any stage. Each interruption raises the attacker's cost and creates a detection opportunity.
