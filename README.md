# learning-journal

A record of six months learning cybersecurity and cloud from zero.
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

## Environment

- **Main machine:** Dell Inspiron 3490, Linux Mint 22
- **Early phases:** WSL2 Ubuntu on Windows 11
- **VMs:** Metasploitable 2 (attack target), Linux Mint VM, KVM Ubuntu Server
- **Cloud:** AWS free tier, ap-south-1 (Mumbai)
- **SIEM:** Wazuh 4.11.2 + Elastic, self-hosted on KVM

---

## What's in each phase folder

Every phase folder has the same three files:

- `notes.md` — what I was supposed to learn, and what it actually meant once it clicked
- `labs.md` — what I ran, what broke, what I fixed
- `summary.md` — closing thoughts: what landed, what I'd do differently

Scripts and configs live in their phase folders too.
