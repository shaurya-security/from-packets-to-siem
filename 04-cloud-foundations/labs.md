# Phase 4 — labs

---

## CLI authentication

```bash
shaurya@Mint-Dell-3490:~$ aws sts get-caller-identity
{
    "UserId": "XXXXX",
    "Account": "XXXXX",
    "Arn": "arn:aws:iam::XXXXX:user/shaurya-admin"
}
```

`sts get-caller-identity` answers: who am I in AWS right now? If this returns a valid ARN, the credentials are working and every subsequent API call authenticates as that identity.

---

## VPC build (via CLI)

```bash
# Create VPC
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $VPC_ID \
    --tags Key=Name,Value=shaurya-domain-vpc

# Public subnet
SUBNET_PUB=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 \
    --availability-zone ap-south-1a \
    --query 'Subnet.SubnetId' --output text)

# Private subnet
SUBNET_PRIV=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 \
    --availability-zone ap-south-1a \
    --query 'Subnet.SubnetId' --output text)

# Internet gateway — gives the public subnet internet access
IGW_ID=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

# Route table for public subnet — sends 0.0.0.0/0 to the IGW
RTB_PUB=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route \
    --route-table-id $RTB_PUB \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID
aws ec2 associate-route-table \
    --route-table-id $RTB_PUB --subnet-id $SUBNET_PUB
```

Infrastructure state after build:

| Resource | Value |
|---------|-------|
| VPC | `vpc-0f3078cdc3bb963c1` / `10.0.0.0/16` |
| Public subnet | `subnet-05b370584309c1f1f` / `10.0.1.0/24` |
| Private subnet | `subnet-065fa31ce2da431ba` / `10.0.2.0/24` |
| Bastion EC2 | `10.0.1.x`, stopped (cost control) |
| Web server EC2 | `10.0.2.x`, no public IP, stopped |
| S3 data bucket | `shaurya-data-20260514` |
| S3 logs bucket | `shaurya-logs-20260515` |

Monthly cost while instances stopped: ~$1.60 (two 8GB EBS volumes). VPCs, subnets, security groups, route tables: free.

---

## The JMESPath case bug

```bash
# Wrong
aws ec2 describe-vpcs --query 'vpcs[0].VpcId' --output text
# Output: None

# Correct
aws ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text
# Output: vpc-0f3078cdc3bb963c1
```

Diagnosed by running without `--query` first, reading the raw JSON, and noticing `"Vpcs"` with a capital V. Copied exactly. Worked.

---

## S3 exposure lab

```bash
# Step 1: Upload a file (bucket is private by default)
echo "Hello from Shaurya's cloud journey!" > ~/hello-cloud.txt
aws s3 cp ~/hello-cloud.txt s3://shaurya-data-20260514/

# Step 2: Disable public access blocks
aws s3api put-public-access-block \
    --bucket shaurya-data-20260514 \
    --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Step 3: Apply public read policy
aws s3api put-bucket-policy \
    --bucket shaurya-data-20260514 \
    --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::shaurya-data-20260514/*"}]}'
```

Loaded this URL in a browser:
```
https://shaurya-data-20260514.s3.ap-south-1.amazonaws.com/hello-cloud.txt
```

File contents appeared. No authentication. Anyone with the URL.

```bash
# Step 4: Lock it back down
aws s3api delete-bucket-policy --bucket shaurya-data-20260514
aws s3api put-public-access-block \
    --bucket shaurya-data-20260514 \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Step 5: Enable versioning and access logging
aws s3api put-bucket-versioning \
    --bucket shaurya-data-20260514 \
    --versioning-configuration Status=Enabled
aws s3api put-bucket-logging \
    --bucket shaurya-data-20260514 \
    --bucket-logging-status '{"LoggingEnabled":{"TargetBucket":"shaurya-logs-20260515","TargetPrefix":"access-logs/"}}'
```

---

## IAM blast radius test

```bash
# Configured AWS CLI with shaurya-s3-reader credentials
aws s3 ls s3://shaurya-data-20260514      # allowed
aws ec2 describe-instances               # access denied
aws iam list-users                       # access denied
```

Confirmed: `shaurya-s3-reader` credentials, if stolen, let an attacker read one bucket. Nothing else.
