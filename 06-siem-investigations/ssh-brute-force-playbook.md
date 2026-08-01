# Playbook: SSH brute force (T1110)

Trigger: Wazuh level ≥ 10, `rule.mitre.id: T1110`, or 5+ SSH failures from same IP in 60 seconds.

---

## Step 1 — Verify

Check these fields before doing anything:

| Field | Question |
|-------|---------|
| `data.srcip` | Is this IP in the admin whitelist? |
| `data.dstuser` | Real account or a phantom (`admin`, `root`, `pi`, `test`)? |
| `rule.firedtimes` | Low count from known IP = probably a typo |
| `agent.name` | Which host is targeted — internet-facing or internal? |

Admin IPs for this lab: `192.168.122.1` (Mint), `192.168.122.62` (Fedora). Any `192.168.122.x` source from a known machine with a low count is almost certainly a typo.

---

## Step 2 — Check for success after failures

This is the most important step.

```
Kibana query:
source.ip: <attacker_ip> AND event.outcome: success AND event.type: authentication
```

If a success exists after failures from the same IP — stop, this is an incident. Go to step 5 immediately.

If no success — continue to step 3.

---

## Step 3 — Enrich

For external IPs only:

1. GeoIP: `https://ipinfo.io/<ip>` — note country and org
2. Threat intel: `https://www.abuseipdb.com/check/<ip>` — confidence score, report count
3. Wazuh/Kibana history: any other alerts from this IP in the last 7 days?

Hosting provider ASN + multiple abuse reports = automated scanner, low priority.
Residential IP + no abuse history = more likely a targeted attempt.

---

## Step 4 — Containment decision

| Situation | Action |
|-----------|--------|
| Internal admin IP, count < 5, no success | False positive — close with note |
| External IP, count < 50, no success | Log and monitor |
| External IP, count > 50, no success | Block at NACL, add to watchlist |
| Any IP, success found | Escalate immediately — step 5 |

Blocking at NACL (stateless — block both directions):
```bash
aws ec2 create-network-acl-entry \
    --network-acl-id acl-XXXXXXXXXX \
    --rule-number 1 \
    --protocol -1 \
    --rule-action deny \
    --ingress \
    --cidr-block "<source_ip>/32"
```

For a local VM target, use `iptables`:
```bash
sudo iptables -A INPUT -s <source_ip> -j DROP
```

---

## Step 5 — Escalation (only if success found)

Immediate actions before escalating:

```bash
who                         # who is currently logged in
w                           # what they're doing
last | head -20             # recent login history
sudo passwd -l <username>   # lock the compromised account
```

Do NOT terminate the instance. Disk snapshot first:
```bash
aws ec2 create-snapshot \
    --volume-id vol-XXXXXXXXXX \
    --description "forensic-$(date +%Y%m%d-%H%M)"
```

Escalation note should include: alert ID, source IP, target host, failure count, success timestamp, username, GeoIP result, threat intel score, Kibana timeline link.

---

## Step 6 — Ticket notes

False positive:
```
Verdict: FALSE POSITIVE
Source: 192.168.122.62 — authorized admin workstation (Fedora Desktop)
Evidence: Internal IP, count 2, no success observed
Action: Closed. No containment.
```

True positive, no breach:
```
Verdict: TRUE POSITIVE — contained
Source: <ip>, <country>
Evidence: <N> failures, 0 successes. IP blocked at NACL.
Action: IP blocked. Added to watchlist.
Escalation: Not required.
```

Incident:
```
Verdict: INCIDENT
Source: <ip>
Evidence: <N> failures followed by success at <timestamp> for user <username>
Action: Escalated to Tier 2. Account locked. Instance isolated.
Status: Open — see ticket #<ID>
```

---

## Tuning notes

Common false positive sources:
- Admin machines — whitelist with `!192.168.122.1` in the Wazuh rule
- Automation tools with stale credentials — whitelist by source IP + service account pair
- Threshold too low — raise `frequency` in the rule

Detection gaps this playbook doesn't cover:
- Slow brute force (1 attempt per minute) — threshold rules won't catch it, needs hunting
- Key-based auth failures — different log pattern, separate rule needed
