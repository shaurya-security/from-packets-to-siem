# Phase 6 — labs

---

## Lab setup

```
Linux Mint (192.168.122.1)      → Wazuh agent 002
Fedora Desktop (192.168.122.62) → Wazuh agent 001
                                          ↓
                              KVM Ubuntu Server
                              Wazuh Manager + Indexer + Dashboard
```

Agent registration port: 1514. Ongoing data: 1514. Dashboard: `https://<ubuntu-server-ip>:443`

---

## Install: first attempt failure

Tried `apt install wazuh-indexer` to install manually.

Service failed to start:
```bash
sudo tail -50 /var/log/wazuh-indexer/wazuh-cluster.log
# Unable to read the file /etc/wazuh-indexer/certs/root-ca.pem
```

```bash
sudo ls /etc/wazuh-indexer/certs/
# ls: cannot access '/etc/wazuh-indexer/certs/': No such file or directory
```

The certs directory didn't exist. Wazuh Indexer (OpenSearch) requires TLS certificates to start. `apt install` provides the binary but doesn't generate certificates. The official assisted installer does.

Diagnosis method: read the log file. Not guessing, not searching first. The error message said exactly what was missing.

---

## Install: official assisted installer

```bash
curl -sO https://packages.wazuh.com/4.x/wazuh-install.sh
chmod +x wazuh-install.sh

sudo ./wazuh-install.sh --generate-config-files
sudo ./wazuh-install.sh --wazuh-indexer node-1
sudo ./wazuh-install.sh --start-cluster
sudo ./wazuh-install.sh --wazuh-server wazuh-1
sudo ./wazuh-install.sh --wazuh-dashboard dashboard
```

Final output:
```
INFO: You can access the web interface https://<wazuh-dashboard-ip>:443
    User: admin
    Password: qREaI7jjXkLDGOj6Rk9.ib9rSLCsc?e4
INFO: Installation finished.
```

Service status:
```
● wazuh-manager.service   Active: active (running)   Memory: 1.9G
● wazuh-indexer.service   Active: active (running)   Memory: 1.3G
● wazuh-dashboard.service Active: active (running)   Memory: 288.5M
```

Total: ~3.5 GB RAM on a 6 GB system. Viable.

---

## Agents connected

From the Wazuh dashboard:

```
Endpoints: Active (2)

ID  | Name           | IP              | OS              | Version  | Status
001 | Fedora-desktop | 192.168.122.62  | Fedora Linux 44 | v4.11.2  | active
002 | Mint-Desktop   | 192.168.122.1   | Linux Mint 22.3 | v4.11.2  | active
```

---

## First real alert — capstone

Alert from the Wazuh dashboard:

```
rule.level:            10
rule.description:      syslog: User missed the password more than one time
rule.mitre.id:         T1110
rule.mitre.tactic:     Credential Access
rule.mitre.technique:  Brute Force
data.srcip:            192.168.122.62
data.dstuser:          shaurya-server
rule.firedtimes:       2
full_log:              PAM 2 more authentication failures;
                       rhost=192.168.122.62 user=shaurya-server
_index:                wazuh-alerts-4.x-2026.05.22
```

Wazuh mapped this to MITRE T1110 automatically. No manual tagging. The MITRE panel in the dashboard showed Credential Access as the tactic. PCI DSS 10.2.4, HIPAA 164.312.b, NIST 800-53 AU.14 — all applied automatically.

---

## Triage walkthrough

**Step 1 — Verify:** SSH failures from `192.168.122.62` (Fedora Desktop) to `shaurya-server` on Ubuntu Server. Count: 2 failures, 0 successes.

**Step 2 — Enrich:** `192.168.122.62` is on the KVM bridge network (`192.168.122.x`). Only local VMs and the host are in this range. Not an external IP.

**Step 3 — Context:** No other alerts from this IP in the same window. No success event following the failures.

**Step 4 — Decide:** False positive. Source is an authorized admin workstation. Count is below any reasonable brute force threshold. No successful login observed.

**Step 5 — Act:** Close. Note logged.

---

## Analyst report written for the capstone

```
Timestamp:   2026-05-22 11:17:58 UTC
Alert:       T1110 – SSH brute force (level 10)
Source:      192.168.122.62 — Fedora Desktop, authorized admin workstation
Target:      shaurya-server on Ubuntu Server
Count:       2 failures, 0 successes
Verdict:     False positive — likely SSH typo during admin session
Evidence:    Source on local KVM bridge network. Count below threshold.
             No success observed. No other anomalous events from this IP.
Action:      No containment. Monitor for recurrence.
Escalation:  No.
Ticket note: "Regular admin typo — source is authorized workstation."
```

Correct verdict. Correct evidence citation. Correct escalation decision. The triage workflow from the notes worked on a live alert.
