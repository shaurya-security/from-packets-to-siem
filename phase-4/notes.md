# Phase 4 — notes

Building actual cloud infrastructure. Not reading about it — provisioning it, breaking it, and fixing it through the CLI.

---

## The shared responsibility model

Cloud isn't just "someone else's computer." It's a split of who's responsible for what.

With IaaS (EC2 instances): AWS manages the physical hardware, the hypervisor, and the network hardware. I'm responsible for the operating system, the firewall rules, the application, the data. If I misconfigure a security group to allow all inbound traffic, that's on me.

With PaaS (managed databases, Lambda): AWS takes more of the stack. I'm still responsible for the data and access control.

The model matters for incident response. When something breaks, the first question is: whose layer is this? If it's my EC2's OS configuration — my problem. If the physical data center has a power outage — AWS's problem.

---

## VPC and subnets

A VPC (Virtual Private Cloud) is a private network inside AWS. I define the IP range, create subnets, control routing.

The address range notation (CIDR) from Phase 1 networking came back here. Before Phase 4 started, I said I didn't know what CIDR was — then immediately explained it correctly: `/16` is 256×256 addresses (65,536 total), `/24` is 256 addresses with 254 usable (two reserved: network address and broadcast). The concept was there; it just needed naming.

The architecture I built:
```
VPC: 10.0.0.0/16  (shaurya-domain-vpc)
├── Public subnet: 10.0.1.0/24  — has a route to the internet
│   └── EC2 bastion host  (t2.micro, Ubuntu 22.04)
└── Private subnet: 10.0.2.0/24  — no direct internet access
    └── EC2 web server  (t2.micro, no public IP)
```

The bastion pattern: to reach the web server, you SSH into the bastion first, then SSH from the bastion to the web server. The web server has no public IP. The attack surface for SSH is limited to one hardened entry point.

---

## Security groups and NACLs

Security groups are instance-level firewalls. Stateful — if you allow inbound traffic, the response is automatically allowed out. Default: deny all inbound.

NACLs are subnet-level firewalls. Stateless — must explicitly allow traffic in both directions. Applied before traffic reaches instances.

Practical difference: use security groups for per-instance control. Use NACLs for subnet-wide blocking, like a blanket IP ban.

After creating the bastion EC2, I couldn't ping its public IP even though it existed. Reason: security groups deny all inbound by default. ICMP wasn't allowed. Same lesson as the Phase 1 gateway: absent ping doesn't mean absent host.

---

## IAM

IAM (Identity and Access Management) is access control for cloud resources. Every API call is an IAM decision — is this identity allowed to do this action on this resource?

I created two users:
- `shaurya-admin` — administrator access (full account)
- `shaurya-s3-reader` — only `s3:GetObject` and `s3:ListBucket`

Blast radius: if `shaurya-s3-reader` credentials are stolen, the attacker can read from one S3 bucket. They cannot launch instances, modify IAM, or delete anything. The scope of the breach is limited to what the credential allows.

Principle of least privilege: give identities exactly what they need and nothing more. Same concept as Linux file permissions — but for cloud services.

---

## S3

S3 is object storage. Files live in buckets. Buckets are private by default.

Four settings block public access — all enabled by default. Disabling them plus applying a public bucket policy makes objects readable by anyone with the URL. No authentication required.

Did this intentionally in a lab: disabled the blocks, applied a public policy, loaded the file URL in a browser. The file appeared. Then locked it back down and enabled access logging.

That sequence is the entire explanation for every S3 data breach you've read about. Someone ran those two steps without understanding what they did.

---

## CloudTrail

Every API call to AWS is an event. CloudTrail captures them all and writes them to S3.

Structure of an event:
```json
{
  "eventTime": "2026-05-17T09:14:22Z",
  "eventSource": "ec2.amazonaws.com",
  "eventName": "RunInstances",
  "userIdentity": {"userName": "shaurya-admin"},
  "sourceIPAddress": "49.x.x.x",
  "requestParameters": {"imageId": "ami-..."}
}
```

CloudTrail answers: who did what, to which resource, from where, at when.

Importantly: CloudTrail logs *failed* API calls too. An access denied error shows up in the logs. That's detection without any exploit succeeding.

---

## JMESPath and the case-sensitivity lesson

`--query 'vpcs[0].VpcId'` returned nothing. `--query 'Vpcs[0].VpcId'` returned the VPC ID.

AWS API responses use `"Vpcs"` with a capital V. JMESPath is case-sensitive. The wrong case returns `None` silently — no error, just empty output.

Rule discovered through breaking it: always look at the raw JSON output first (`aws ec2 describe-vpcs` without `--query`), find the exact key name, copy it. Don't guess.

Also: `--output text` strips the quotes from the response. Necessary when storing the result in a bash variable — otherwise the quotes end up inside the variable value and break the next command.

---

## `inventory.sh`

Phase 3's `hero.sh` pattern applied to AWS:

```bash
VPC_ID=$(aws ec2 describe-vpcs \
    --filters Name=tag:Name,Values=shaurya-domain-vpc \
    --query 'Vpcs[0].VpcId' \
    --output text)

if [ -z "$VPC_ID" ] || [ "$VPC_ID" = "None" ]; then
    echo "VPC not found"
else
    echo "VPC: $VPC_ID"
fi
```

`$()` command substitution — Phase 3. `-z` empty string test — Phase 3. Conditional structure — Phase 3. Same patterns, new data source.
