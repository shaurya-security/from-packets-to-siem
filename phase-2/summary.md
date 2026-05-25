# Phase 2 — summary

Phase 2 gave Phase 1 a reason. The commands I learned before had context now — every `nmap` scan is reconnaissance, every open port is a potential vulnerability, every missing authentication check is an access control failure.

---

## What landed

The attack lifecycle framing was the most useful thing from this phase. Having a named sequence — reconnaissance through actions on objectives — means I can look at any event and ask: what stage is this? What comes before it? What probably comes next?

Identifying myself as "the threat" in the Metasploitable lab was a deliberate shift. A defender who can think from the attacker's perspective understands *why* controls matter, not just *what* they are.

The distinction between technical risk and business risk clicked through the Metasploitable example. A root shell on a lab VM is technically catastrophic, practically irrelevant. The same vulnerability on a production payment server is both technically and practically catastrophic. Risk assessment requires both lenses.

---

## Where I got it wrong

The CIA triad availability mistake from Phase 1 carried into Phase 2 briefly — I initially framed `chmod 600` as protecting all three. Getting that corrected before moving on meant the triad actually stuck rather than becoming a memorized list.

---

## The hardware interruption

SSD died mid-phase. Two days lost to hardware replacement and a bad Windows 11 upgrade. Looking back: that was an availability failure (drive failure), a failed change management process (upgrade without testing), and an incident response (manual recovery). All Phase 2 concepts, lived through rather than studied.

---

## Going into Phase 3

I had frameworks but no implementation. I could describe what a log parser does. I couldn't write one. Phase 3 was supposed to fix that — and it was harder than I expected.
