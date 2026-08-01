# Phase 5 — notes

Same infrastructure as Phase 4. Different question: what does an attack look like in these logs?

---

## Three attack surfaces that didn't exist before the cloud

**Control plane API.** Every AWS action is an HTTPS request — create a bucket, launch an instance, attach a policy. The API is internet-accessible. Credentials are a text key pair. If someone gets the access key and secret key (from a leaked `.env` file, a GitHub commit, an infected laptop), they can make authenticated API calls from anywhere on earth. No firewall blocks a legitimate-looking API call.

**EC2 metadata service.** Any code running inside an EC2 instance can call `http://169.254.169.254/latest/meta-data/iam/security-credentials/` and get live credentials for the instance's IAM role. Code execution on the VM — even as a low-privilege user — can become cloud account access.

**Public storage.** An accidentally public S3 bucket is readable by anyone with the URL. No exploit required. Just misconfiguration.

Asked which is most dangerous: "Control plane seems strongest exploit — if an attacker owns the control plane, they own the entire account, not one VM."

That's right. A compromised network service gets you one machine. Compromised control plane credentials get you everything.

---

## IAM patterns attackers look for

After stealing credentials, an attacker runs IAM enumeration — checking what the stolen identity can do. The patterns that signal a valuable find:

- `"Action": "*", "Resource": "*"` — administrator access. One credential, full account.
- `iam:CreateAccessKey` permission — can create new backdoor credentials that persist after the original compromise is detected.
- No MFA on a privileged user — password theft alone is enough.
- EC2 instance role with broad permissions — compromise the application, get cloud access.

---

## What CloudTrail logs vs what it misses

CloudTrail captures every API call: create, modify, delete, describe. Who did it, from where, when, what parameters.

What it doesn't capture by default: S3 object reads. `GetObject` on a file isn't a control-plane action — it's data-plane. You need S3 Server Access Logs or CloudTrail Data Events (enabled separately, costs more) to see individual file reads.

So: an attacker downloads an entire S3 bucket using valid credentials. CloudTrail alone shows nothing. You'd need S3 access logs to see 10,000 `GetObject` calls in two minutes.

The Phase 4 access logging setup (`shaurya-logs-20260515`) covers this gap.

---

## Detection thinking

Before writing a detection rule, answer four questions:

1. What does normal behavior look like? (the baseline)
2. What does the attack look like? (the anomaly)
3. What legitimate activity looks exactly like the attack? (the false positive)
4. If it fires and it's real — what's the first action?

A rule that can't answer question 3 will generate noise. A rule with no answer to question 4 is an alert nobody acts on.

---

## Service accounts and detection confidence

Asked which is more suspicious: a human user from a new IP with MFA, or a service account from a new IP without MFA?

"I would be less suspicious of the human. Service account actions are fixed and predictable — easy to detect anomalies. But humans — even experts might have surprising behavior."

That's the principle behind UEBA. Machine identities have narrow expected behavior. Any deviation is high-confidence signal. Human identities have wide expected behavior. Deviation needs context.

---

## Five detection use cases

**Case 1: Credential use from a new IP**

A service account that always runs from your office IP (`203.0.113.x`) calls `ec2:RunInstances` 50 times from `185.142.53.100` at 3 AM.

Detection logic:
```
IF source_ip NOT IN known_ips_for_this_identity
AND action IN [RunInstances, CreateAccessKey, AssumeRole, PutBucketPolicy]
AND time NOT IN expected_hours
THEN alert — possible stolen credentials
```

False positive: developer working from a new VPN exit node.
Triage: was there any VPN activity logged at that time?

**Case 2: Resource launched in wrong region**

`RunInstances` in `us-east-1` when you only operate in `ap-south-1`.

Detection logic:
```
IF eventName = "RunInstances"
AND awsRegion NOT IN ["ap-south-1"]
THEN alert — shadow infrastructure
```

Common attacker use: crypto mining in a region nobody's watching, billed to the victim.

**Case 3: IAM enumeration**

47 `AssumeRole` AccessDenied errors from one IP in three minutes.

Detection logic:
```
IF errorCode = "AccessDenied"
AND eventName = "AssumeRole"
AND COUNT(same sourceIPAddress) > 10 WITHIN 5 minutes
THEN alert — IAM structure mapping
```

Attackers enumerate roles to find one they can assume. AccessDenied still shows up in CloudTrail. The failure is the signal.

**Case 4: Data egress spike**

VPC Flow Logs show 2.3 GB outbound from the web server EC2 to an unknown external IP. Daily baseline: 50 MB.

Detection logic:
```
IF srcaddr IN [private_EC2_IPs]
AND dstaddr NOT IN known_service_CIDRs
AND bytes > (baseline * 10)
THEN alert — possible data exfiltration
```

Prioritized highest: data loss is irreversible. A launched instance can be terminated. Exfiltrated data can't be un-exfiltrated.

Containment: do NOT terminate the instance. Change the security group to block all outbound. Take a disk snapshot. Investigate.

**Case 5: Service account doing IAM things**

A web server's EC2 instance role (expected actions: `s3:GetObject`, `logs:PutLogEvents`) calls `iam:CreateAccessKey`.

Detection logic:
```
IF userIdentity.type = "AssumedRole"
AND sessionIssuer.userName = "webserver-role"
AND eventName NOT IN ["s3:GetObject", "logs:PutLogEvents", "logs:CreateLogStream"]
THEN alert — CRITICAL, application is likely compromised
```

A web server never needs IAM permissions. If it calls IAM, either the code was changed or the instance was compromised. This is the detection rule written independently, adapting the pattern from Case 1.

---

## The template approach

Five cases with different specifics, same structure. Starting from the nearest working case and changing only what's different from the new scenario is the same blank-screen solution from Phase 3 scripting. The pattern transferred.
