#!/bin/bash
# inventory.sh
# Query live AWS infrastructure state by resource name tags.
# No hardcoded IDs — everything is discovered through the API.
#
# What I learned building this:
#   - 'Vpcs[0].VpcId' not 'vpcs[0].VpcId' (JMESPath is case-sensitive)
#   - --output text strips quotes, needed for bash variables
#   - [ -z "$VAR" ] tests for empty string — same as hero_exist() from Phase 3

echo ""
echo "=== Cloud Inventory ==="

# VPC
echo ""
echo "VPC:"
VPC_ID=$(aws ec2 describe-vpcs \
    --filters Name=tag:Name,Values=shaurya-domain-vpc \
    --query 'Vpcs[0].VpcId' \
    --output text 2>/dev/null)

if [ -z "$VPC_ID" ] || [ "$VPC_ID" = "None" ]; then
    echo "  not found"
else
    VPC_CIDR=$(aws ec2 describe-vpcs \
        --vpc-ids "$VPC_ID" \
        --query 'Vpcs[0].CidrBlock' \
        --output text)
    echo "  $VPC_ID  ($VPC_CIDR)"
fi

# Subnets
echo ""
echo "Subnets:"
SUBNET_PUB=$(aws ec2 describe-subnets \
    --filters Name=tag:Name,Values=shaurya-public-subnet \
    --query 'Subnets[0].SubnetId' \
    --output text 2>/dev/null)
SUBNET_PRIV=$(aws ec2 describe-subnets \
    --filters Name=tag:Name,Values=shaurya-private-subnet \
    --query 'Subnets[0].SubnetId' \
    --output text 2>/dev/null)

echo "  public:  ${SUBNET_PUB:-not found}"
echo "  private: ${SUBNET_PRIV:-not found}"

# EC2 instances
echo ""
echo "EC2:"
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=shaurya-bastion,shaurya-webserver" \
    --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],State.Name,PrivateIpAddress]' \
    --output table 2>/dev/null || echo "  none found"

# S3
echo ""
echo "S3 buckets:"
aws s3 ls 2>/dev/null || echo "  none or no permission"

echo ""
echo "=== done ==="
echo ""
