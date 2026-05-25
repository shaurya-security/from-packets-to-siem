# Phase 4 — summary

Phase 4 was the first time something I built had real consequences. A misconfigured security group means the VM is unreachable. A wrong IAM policy means the service can't do its job. An accidentally public S3 bucket means the file is on the open internet.

---

## What landed

The CIDR moment at the start was funny in hindsight — I said I didn't know CIDR, then immediately explained it correctly. The concept was there from Phase 1 networking. Cloud just uses the same notation with different stakes.

The JMESPath case bug was genuinely useful. The rule that came from it — look at the raw JSON first, copy the field name exactly, never guess capitalization — applies to every tool that parses structured data. SIEM log field extraction works the same way.

The S3 exposure lab was the most visceral lesson. The file appearing in the browser after two CLI commands made the abstract "misconfigured S3 bucket" security warning into something concrete. I did it, I saw it, I reversed it.

---

## Where I got it wrong

Mostly minor things — wrong `--query` paths, wrong subnet CIDR assignments that had to be corrected. The JMESPath case error was the most significant, and it took inspecting raw JSON to find it. After that, always check raw output before writing the query.

---

## Infrastructure status

Instances are stopped for cost control. Monthly bill is around $1.60 for the EBS volumes. Everything else — VPC, subnets, security groups, route tables, CloudTrail — is free. The architecture is intact and restartable.

---

## Going into Phase 5

Phase 4 built the infrastructure. Phase 5 treated the same infrastructure as a threat model — asking what an attacker could do to each component, and what the logs would look like if they tried.
