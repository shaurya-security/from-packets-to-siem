# Phase 5 — labs

---

## CloudTrail event structure

What a real event looks like:

```json
{
  "eventTime": "2026-05-18T21:47:00Z",
  "eventSource": "ec2.amazonaws.com",
  "eventName": "RunInstances",
  "awsRegion": "ap-south-1",
  "sourceIPAddress": "185.142.53.100",
  "userAgent": "aws-cli/2.x",
  "userIdentity": {
    "type": "IAMUser",
    "userName": "jenkins-build-server"
  },
  "requestParameters": {
    "instancesSet": {
      "items": [{"imageId": "ami-0abcdef", "minCount": 50, "maxCount": 50}]
    },
    "instanceType": "c5.4xlarge"
  }
}
```

What this event tells an analyst: `jenkins-build-server` launched 50 `c5.4xlarge` instances from an IP that's probably not the CI/CD server, at a time no build should be running. `c5.4xlarge` is high-compute. 50 instances. Three signals in one event.

---

## VPC Flow Log structure

```
2 123456789012 eni-abc123 10.0.2.27 104.21.15.xxx 43210 443 6 1840 2457832400 ACCEPT OK
```

Fields: `version account interface srcaddr dstaddr srcport dstport protocol packets bytes action`

The `bytes` field here is `2,457,832,400` — approximately 2.3 GB. From the private web server IP to an unknown external destination. If daily baseline is 50 MB, this is 46x the normal volume.

Reading flow logs uses the same `awk '{print $N}'` pattern as Phase 3 log parsing. Field 4 is srcaddr. Field 5 is dstaddr. Field 10 is bytes. Same skill, different field numbers.

---

## The S3 detective exercise

Given this sequence of CloudTrail events, describe what happened:

```
09:14:22 — GetCallerIdentity (from IP 185.220.101.x)
09:14:25 — ListBuckets
09:14:28 — GetBucketPolicy on shaurya-data-20260514
09:14:31 — PutBucketPolicy on shaurya-data-20260514 (Principal: *)
09:14:35 — GetObject called 10,000 times on shaurya-data-20260514
```

Reconstruction: attacker got credentials (we don't know how). First call verified who they were impersonating. Listed buckets to find targets. Read the existing policy. Made the bucket public. Downloaded everything.

The attack took 13 seconds from first API call to data loss. Detection at the `PutBucketPolicy` step would have caught it. Detection at `GetCallerIdentity` from an unknown IP would have caught it earlier.

---

## Multi-signal correlation

Single signals are noisy. Combinations are useful:

| Signals | Confidence |
|--------|-----------|
| New IP alone | Low — could be VPN, travel, new laptop |
| New IP + sensitive action | Medium — worth investigating |
| New IP + sensitive action + unusual time | High — alert + investigate |
| Service account doing out-of-scope IAM action | Critical — respond immediately |
| AccessDenied × 30 in 5 minutes from one IP | High — active enumeration |
| Failures then a success from the same IP | Critical — credential compromise confirmed |

The last one (failure → success sequence) was the key insight from the Phase 6 triage exercise.
