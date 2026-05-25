# Phase 6 — notes

Deploying a real SIEM. Connecting agents. Triaging a live alert.

---

## SOC basics

A Security Operations Center monitors for threats, investigates alerts, and responds to incidents. Tier 1 handles initial triage — is this real or a false positive? Tier 2 investigates deeper. Tier 3 handles advanced threats and does threat hunting.

First question of the shift: what happened while I wasn't here. Shift handover — checking open cases, pending alerts, anything that rolled over from the previous analyst. That instinct appeared before it was taught.

The three-alert prioritization exercise:
1. Firewall blocked a port scan from 8.8.8.8
2. Cron job modified at 3 AM
3. SSH login success at 2 AM from unknown IP

My answer: cron job first. Reasoning: it's likely the most recent attacker action, and cron is a common persistence mechanism — MITRE T1053. A modified cron job at 3 AM from an unknown process is the sign of something being installed to survive a reboot.

Phase 2 MITRE knowledge applied to a Phase 6 triage scenario.

---

## Log normalization

The same event looks different depending on the source:

| Source | What "failed SSH login" looks like |
|--------|-----------------------------------|
| Ubuntu `/var/log/auth.log` | `sshd[9876]: Failed password for shaurya from 192.168.122.1 port 43210 ssh2` |
| Fedora `/var/log/secure` | `pam_unix(sshd:auth): authentication failure; rhost=192.168.122.1 user=shaurya` |
| AWS CloudTrail | `{"eventName": "ConsoleLogin", "responseElements": {"ConsoleLogin": "Failure"}}` |

A SIEM normalizes all three into standard fields: `source.ip`, `user.name`, `event.outcome`, `@timestamp`. Once normalized, the same rule applies regardless of which system the log came from.

---

## Correlation types

**Temporal:** 5 failures in 60 seconds → brute force pattern.

**Spatial:** same IP hitting Ubuntu and Fedora → not a typo, actively scanning.

**Sequential:** failures from IP X, then a success from IP X → they cracked it. This is the most dangerous pattern. Failures alone might be noise. Failure → success is an incident.

**Threshold:** count exceeds N in time window → alert fires.

The correlation exercise: three SSH failures from the same IP across two machines, then one success. My answer: "spatial cause same IP is attacking multiple devices, sequential cause it failed then succeeded."

Correctly identified both types. The sequential part — failure → success — is the signal that distinguishes brute force noise from an actual credential compromise.

---

## Alert rules in Wazuh

```xml
<rule name="SSH brute force" level="10" frequency="5" timeframe="60">
  <if_sid>5710</if_sid>
  <match>Failed password</match>
  <srcip>!192.168.122.1</srcip>
  <description>Multiple SSH failures from non-admin IP</description>
</rule>
```

`level="10"` — high severity on a 0–15 scale. `frequency="5"` — fires after 5 matches. `timeframe="60"` — within 60 seconds. `<if_sid>5710</if_sid>` — extends the built-in SSH failure rule. `!192.168.122.1` — NOT this IP (admin machine whitelist).

The rule I wrote independently:
```
IF source_ip NOT IN known_ips
AND event.type = authentication
AND event.outcome = success
AND device = ubuntu
THEN alert, severity 9
```

Logic correct. Severity 9 reasonable — high but not critical, because it might be a new legitimate user. Wazuh syntax differs from this pseudocode but the structure is the same.

---

## Triage workflow

1. Verify — timestamp, source IP, target, event type
2. Enrich — GeoIP, threat intel, is this IP known?
3. Context — other events from this IP in the same window?
4. Decide — false positive / true positive / needs more data
5. Act — close with note / escalate with evidence

---

## Dashboards vs hunting

**Dashboards** answer: what hit our detection rules? Reactive. Tier 1. Looking at the last few hours.

**Hunting** asks: what didn't hit our rules but looks suspicious anyway? Proactive. Tier 2+. Looking for patterns rules haven't been written for yet.

Alerts catch known bad. Hunting catches unknown bad. Both required.

---

## Playbooks

A playbook is a documented response procedure for a specific alert type. It answers: when this alert fires, what do you do first, second, third? When do you escalate? What's the ticket note?

Without a playbook, Tier 1 analysts make it up under pressure. With one, the response is consistent and documented regardless of who's on shift.

The SSH brute force playbook covers: verify the source IP, check if any login succeeded after failures, look at GeoIP and threat intel, decide severity, write the ticket note. Containment if needed: block the IP at the NACL, preserve the instance for forensics, don't terminate before imaging.
