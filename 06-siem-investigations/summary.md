# Phase 6 — summary

Phase 6 was the first time everything previous became operational. Not described, not simulated — actually running, with real agents shipping real logs, and a real alert to triage.

---

## What landed

The install failure was instructive. The error message said exactly what was wrong: the certificates directory didn't exist. The fix was reading the log rather than guessing. That's the same method used to debug bash scripts in Phase 3 — when something breaks, read the output before trying anything.

The T1110 alert was satisfying because the triage worked cleanly. Source IP on the KVM bridge, count of 2, no successful login — false positive, close with note. The five-step workflow produced the right answer without hesitation. That's what the workflow is for.

The MITRE mapping appearing automatically in the dashboard made Phase 2 feel like it had returned. The same T-codes from the attack lifecycle exercise mapped to a live alert from my own lab. The framework isn't abstract anymore.

---

## Where I got it wrong

Port scan detection was admitted as unknown — never tried it, not sure how to detect it, was told it requires firewall or network telemetry data that wasn't covered yet. That's an honest boundary. Knowing what you don't know is more useful than guessing.

---

## The through-line

Looking back across six phases:

- Phase 1 taught how to read a system
- Phase 2 gave that reading a security context
- Phase 3 automated the reading into scripts
- Phase 4 moved the system into the cloud
- Phase 5 turned the cloud into a detection surface
- Phase 6 deployed a real detection system and used it

None of it is disconnected. The `awk '{print $1}'` from Phase 3 log parsing is the same field extraction logic as Phase 5 flow log analysis. The CIDR notation from Phase 1 is the same notation used for VPC subnets in Phase 4. The blast radius concept from Phase 2 (Metasploitable root shell) is the same concept applied to IAM roles in Phase 4 and 5. The blank screen problem from Phase 3 scripting was solved the same way in Phase 5 detection rules.

---

## What's next

Phase 7 is projects. Separate repositories. Each one a standalone deliverable:

- A home SOC lab with attack simulation (Hydra brute force → Wazuh alert → full incident report)
- A custom Wazuh detection rule for an uncommon pattern
- A cloud honeypot with log collection
- A written incident report in professional format

Those aren't more learning. They're what the learning produces.
