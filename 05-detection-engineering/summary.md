# Phase 5 — summary

Phase 5 was the phase where Phase 4 infrastructure became meaningful. Every resource I built — VPC, EC2, S3, IAM, CloudTrail — was now analyzed from the question: "what does an attack on this look like, and where in the logs would I find it?"

---

## What landed

The service account insight was the clearest moment. Machine identities behave narrowly and predictably. Any deviation from that narrow behavior is high-confidence signal. This is fundamentally different from human users, who have wide, variable behavior. Building detection rules for service accounts is operationally easier and produces fewer false positives. That distinction carries into Phase 6.

Data egress spike was correctly identified as the highest-priority detection to tune. The reasoning: data loss is irreversible. Everything else in this list can be undone — terminate an unauthorized instance, rotate a compromised credential, restore a deleted resource. Exfiltrated data is gone. That asymmetry justifies prioritizing it.

The blank screen problem came up again with detection rules — "can't start on blank screen, same as Phase 3 scripting." The solution was the same: start from the nearest working template, change only what's specific to the new scenario. Case 5 (service account anomaly) was written independently by adapting Case 1's structure.

---

## Where I got it wrong

Nothing major in Phase 5 — the concepts were building on solid Phase 4 foundations. The main gap was getting comfortable with multi-signal correlation. Single signals generate noise; knowing which combinations raise confidence enough to act on is a skill that develops through practice, not through a single phase.

---

## Going into Phase 6

Phase 5 described what detection looks like. Phase 6 deployed an actual SIEM and triaged a real alert from real data. The detection logic written in Phase 5 became the mental model for understanding what Wazuh was doing with the events it received.
