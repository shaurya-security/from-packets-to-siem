# from-packets-to-siem

A documented journey from Linux fundamentals to cloud detection engineering, built through experiments, labs, mistakes, and investigation workflows.

Not a showcase. Not a certificate collection. Just what I studied, what I built, what broke, and what I figured out.

---

## The path

| Phase | What it covered | Status |
|-------|----------------|--------|
| [Phase 1](./phase-1/) | Linux and networking — how to read a system | ✅ done |
| [Phase 2](./phase-2/) | Security concepts — CIA triad, attacks, frameworks | ✅ done |
| [Phase 3](./phase-3/) | Bash and Python scripting — writing tools that do things | ✅ done |
| [Phase 4](./phase-4/) | Cloud fundamentals — building real AWS infrastructure | ✅ done |
| [Phase 5](./phase-5/) | Cloud security — detecting attacks in the cloud | ✅ done |
| [Phase 6](./phase-6/) | SOC and SIEM — deploying Wazuh, triaging live alerts | ✅ done |

Phase 7 is hands-on projects. Those live in separate repos.

---

## What's in each phase

**Phase 1 — Linux and networking**
Filesystem layout, permissions, processes, and basic networking from a terminal. The ARP/ICMP contradiction — gateway visible in `arp -a`, `ping` returning 100% loss — was the first real troubleshooting moment: absence of ping response doesn't mean the host is down. Layer 2 and Layer 3 are different things. That reasoning came back in Phase 5.

**Phase 2 — Core security concepts**
CIA triad, threat modeling, attack frameworks. Phase 1 gave me commands. Phase 2 gave them context — what an attacker is trying to do, and why the Linux primitives I'd learned are the terrain they move through.

**Phase 3 — Scripting**
Bash and Python. First time building tools instead of only using them. Scripts for log parsing, automation, and small utilities. The shift from running commands to writing programs that run commands.

**Phase 4 — Cloud fundamentals**
AWS infrastructure built entirely through the CLI — VPC, subnets, IGW, route tables, security groups, EC2. No console, no guided tutorial. This phase nearly made me quit: building infrastructure from scratch exposed how much of Phase 1-3 understanding was surface-level.

**Phase 5 — Cloud security**
Detection in the cloud. The attack surface changes — no physical perimeter, logs are the only visibility, and IAM misconfiguration is the most common entry point. Detection in AWS using CloudTrail, VPC Flow Logs, and IAM analysis. Learned that cloud investigations often rely on incomplete or ambiguous telemetry, where the absence of evidence is not evidence of absence.

**Phase 6 — SOC and SIEM**
Deployed Wazuh on a KVM lab. Connected agents, triaged a live alert end-to-end. First time going through a full investigation workflow rather than just reading about one.

---

## What's in each phase folder

Every phase folder has the same three files:

- `notes.md` — what I was supposed to learn, and what it actually meant once it clicked
- `labs.md` — what I ran, what broke, what I fixed
- `summary.md` — closing thoughts: what landed, what I'd do differently

Some phases also include scripts, configurations, and lab artifacts generated during the learning process.
---

## Environment

| Period | Setup |
|--------|-------|
| Phases 1–2 | WSL2 Ubuntu on Windows 11 |
| Phase 3 | Linux Mint (after SSD failure and full rebuild) |
| Phases 4–5 | Linux Mint + AWS free tier, ap-south-1 |
| Phase 6 | KVM on Linux Mint — Wazuh 4.11.2, Fedora agent, Ubuntu server |

Main machine throughout: Dell Inspiron 3490.
