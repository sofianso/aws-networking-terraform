# Network Architecture and CIDR Design

This document explains the network design, CIDR block selection, and subnet strategy for the AWS networking infrastructure.

## 📊 CIDR Block Strategy

### **VPC CIDR Allocation**

Each environment has a dedicated `/16` VPC CIDR block from the RFC 1918 private address space:

| Environment | VPC CIDR | IP Address Range | Total IPs | Purpose |
|------------|----------|------------------|-----------|---------|
| **Networking** | `10.0.0.0/16` | 10.0.0.0 - 10.0.255.255 | 65,536 | Transit Gateway hub, central networking |
| **Non-Prod** | `10.1.0.0/16` | 10.1.0.0 - 10.1.255.255 | 65,536 | Development, testing, staging environments |
| **Production** | `10.2.0.0/16` | 10.2.0.0 - 10.2.255.255 | 65,536 | Production workloads, critical applications |

### **Why /16 CIDR Blocks?**

- ✅ **Ample capacity:** 65,536 IP addresses per VPC
- ✅ **Flexibility:** Room for growth without renumbering
- ✅ **AWS best practice:** Recommended size for enterprise VPCs
- ✅ **Private RFC 1918:** Non-routable on the internet, secure for internal use
- ✅ **Transit Gateway compatible:** Non-overlapping ranges enable seamless routing

### **Why This Numbering Scheme?**

```
10.{environment}.{subnet_type}{az}.0/24

Examples:
10.0.1.0/24  → Environment 0 (networking), Public (1), AZ 1
10.0.2.0/24  → Environment 0 (networking), Public (2), AZ 2
10.0.11.0/24 → Environment 0 (networking), Private (11), AZ 1
10.1.1.0/24  → Environment 1 (non-prod), Public (1), AZ 1
10.2.1.0/24  → Environment 2 (prod), Public (1), AZ 1
```

**Benefits:**
- 🔍 **Easy troubleshooting** - Identify environment, subnet type, and AZ from the IP
- 🚫 **Prevents conflicts** - Non-overlapping CIDRs across all environments
- 📈 **Scalable** - Can add more environments (10.3.x, 10.4.x, etc.)
- 📚 **Self-documenting** - Pattern is intuitive and easy to understand

---

## 🏗️ Subnet Design

### **Subnet Sizing: /24 Subnets**

Each subnet uses a `/24` CIDR block, providing:
- **Total addresses:** 256
- **AWS reserved:** 5 addresses
- **Usable addresses:** 251

**AWS Reserved IP Addresses (per subnet):**
| IP Address | Purpose |
|------------|---------|
| `x.x.x.0` | Network address |
| `x.x.x.1` | VPC router |
| `x.x.x.2` | DNS server (Amazon Route 53 Resolver) |
| `x.x.x.3` | Reserved for future use |
| `x.x.x.255` | Broadcast address (not supported, but reserved) |

### **Why /24 Subnets?**

- ✅ **Right-sized:** 251 usable IPs per subnet is sufficient for most use cases
- ✅ **Efficient:** Not too large (avoiding IP waste) or too small (limiting growth)
- ✅ **Standard practice:** Industry standard, familiar to most network engineers
- ✅ **Supports micro-segmentation:** Can create multiple subnet tiers
- ✅ **Cost-effective:** Allows precise resource placement and routing

---

## 🌐 Environment-Specific Configurations

### **1. Networking Account (Multi-AZ)**

**Purpose:** Central hub for Transit Gateway and shared services

```hcl
vpc_cidr = "10.0.0.0/16"

# Public Subnets (Internet-facing resources)
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

# Private Subnets (Internal resources)
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
```

**Architecture:**
```
┌─────────────────────────────────────────────────────────────┐
│              Networking VPC: 10.0.0.0/16                    │
├──────────────────┬──────────────────┬───────────────────────┤
│   AZ 1 (2a)      │   AZ 2 (2b)      │   AZ 3 (2c)          │
├──────────────────┼──────────────────┼───────────────────────┤
│ Public Subnet    │ Public Subnet    │ Public Subnet         │
│ 10.0.1.0/24      │ 10.0.2.0/24      │ 10.0.3.0/24          │
│ - NAT Gateway    │ - NAT Gateway    │ - NAT Gateway         │
│ - Load Balancers │ - Load Balancers │ - Load Balancers      │
│                  │                  │                       │
│ Private Subnet   │ Private Subnet   │ Private Subnet        │
│ 10.0.11.0/24     │ 10.0.12.0/24     │ 10.0.13.0/24         │
│ - TGW Attachment │ - TGW Attachment │ - TGW Attachment      │
│ - Shared Services│ - Shared Services│ - Shared Services     │
└──────────────────┴──────────────────┴───────────────────────┘
```

**Configuration Details:**
- **Availability Zones:** 3 (ap-southeast-2a, 2b, 2c)
- **NAT Gateways:** 3 (one per AZ for high availability)
- **Use Cases:** Transit Gateway, VPN endpoints, shared services, monitoring

---

### **2. Non-Production Account (Single-AZ)**

**Purpose:** Cost-optimized environment for development and testing

```hcl
vpc_cidr = "10.1.0.0/16"

# Public Subnet (Internet-facing resources)
public_subnet_cidrs  = ["10.1.1.0/24"]

# Private Subnet (Internal resources)
private_subnet_cidrs = ["10.1.11.0/24"]
```

**Architecture:**
```
┌─────────────────────────────────────────┐
│    Non-Prod VPC: 10.1.0.0/16            │
├─────────────────────────────────────────┤
│        AZ 1 (2a) - Single AZ            │
├─────────────────────────────────────────┤
│ Public Subnet: 10.1.1.0/24              │
│ - NAT Gateway (single)                  │
│ - Bastion host                          │
│ - Load Balancer                         │
│                                         │
│ Private Subnet: 10.1.11.0/24            │
│ - App servers                           │
│ - Databases (non-HA)                    │
│ - Transit Gateway Attachment            │
└─────────────────────────────────────────┘
```

**Configuration Details:**
- **Availability Zones:** 1 (ap-southeast-2a only)
- **NAT Gateways:** 1 (cost optimization: ~$32/month vs ~$96/month for 3)
- **Trade-offs:** Lower cost, but no high availability
- **Use Cases:** Development, testing, staging, CI/CD pipelines

**Cost Savings:**
- Single NAT Gateway: **~67% cost reduction** vs multi-AZ
- Single AZ resources: **Lower data transfer costs**
- Appropriate for non-critical workloads

---

### **3. Production Account (Multi-AZ)**

**Purpose:** High-availability production environment

```hcl
vpc_cidr = "10.2.0.0/16"

# Public Subnets (Internet-facing resources)
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]

# Private Subnets (Internal resources)
private_subnet_cidrs = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
```

**Architecture:**
```
┌─────────────────────────────────────────────────────────────┐
│            Production VPC: 10.2.0.0/16                      │
├──────────────────┬──────────────────┬───────────────────────┤
│   AZ 1 (2a)      │   AZ 2 (2b)      │   AZ 3 (2c)          │
├──────────────────┼──────────────────┼───────────────────────┤
│ Public Subnet    │ Public Subnet    │ Public Subnet         │
│ 10.2.1.0/24      │ 10.2.2.0/24      │ 10.2.3.0/24          │
│ - NAT Gateway    │ - NAT Gateway    │ - NAT Gateway         │
│ - ALB/NLB        │ - ALB/NLB        │ - ALB/NLB            │
│                  │                  │                       │
│ Private Subnet   │ Private Subnet   │ Private Subnet        │
│ 10.2.11.0/24     │ 10.2.12.0/24     │ 10.2.13.0/24         │
│ - App Servers    │ - App Servers    │ - App Servers         │
│ - RDS (Multi-AZ) │ - RDS (Multi-AZ) │ - RDS (Multi-AZ)      │
│ - ECS/EKS        │ - ECS/EKS        │ - ECS/EKS            │
│ - TGW Attachment │ - TGW Attachment │ - TGW Attachment      │
└──────────────────┴──────────────────┴───────────────────────┘
```

**Configuration Details:**
- **Availability Zones:** 3 (ap-southeast-2a, 2b, 2c)
- **NAT Gateways:** 3 (one per AZ for fault tolerance)
- **High Availability:** Survives single AZ failure
- **Use Cases:** Production applications, databases, critical workloads

**Resilience Features:**
- **Multi-AZ NAT Gateways:** If one AZ fails, others continue
- **Load Balancer distribution:** Traffic across all healthy AZs
- **RDS Multi-AZ:** Automatic failover for databases
- **Auto Scaling:** Distributes instances across AZs

---

## 🔄 Subnet Type Breakdown

### **Public Subnets**

**CIDR Pattern:** `10.{env}.{1-3}.0/24` (third octet: 1, 2, 3)

**Route Table:** Routes `0.0.0.0/0` to **Internet Gateway (IGW)**

**Resources:**
- 🌐 **NAT Gateways** - Provide internet access for private subnets
- ⚖️ **Load Balancers** - Application/Network Load Balancers (internet-facing)
- 🔐 **Bastion Hosts** - Jump boxes for SSH access (if used)
- 🌍 **Public-facing web servers** - If direct internet access required

**IP Allocation Example:**
```
10.0.1.0/24 (AZ1 Public) - 251 usable IPs
├─ 10.0.1.5-10    → NAT Gateway ENIs
├─ 10.0.1.11-20   → Load Balancer ENIs
├─ 10.0.1.21-30   → Reserved for future use
└─ 10.0.1.31-254  → Available
```

### **Private Subnets**

**CIDR Pattern:** `10.{env}.{11-13}.0/24` (third octet: 11, 12, 13)

**Route Table:** Routes `0.0.0.0/0` to **NAT Gateway** (outbound only)

**Resources:**
- 💻 **Application Servers** - EC2 instances, ECS tasks, EKS nodes
- 🗄️ **Databases** - RDS, Aurora, DynamoDB VPC endpoints
- 📦 **Cache Layers** - ElastiCache (Redis, Memcached)
- 🔗 **Transit Gateway Attachments** - VPC attachment to TGW
- 🔒 **Internal services** - No direct internet access

**IP Allocation Example:**
```
10.0.11.0/24 (AZ1 Private) - 251 usable IPs
├─ 10.0.11.5-10   → Transit Gateway ENIs
├─ 10.0.11.11-50  → Application servers
├─ 10.0.11.51-100 → Database instances
├─ 10.0.11.101-150→ Lambda ENIs / Container tasks
└─ 10.0.11.151-254→ Available
```

---

## 🚦 Routing Architecture

### **Public Subnet Route Table**

| Destination | Target | Purpose |
|------------|--------|---------|
| `10.0.0.0/16` | local | Intra-VPC communication |
| `10.1.0.0/16` | Transit Gateway | Route to Non-Prod VPC |
| `10.2.0.0/16` | Transit Gateway | Route to Production VPC |
| `0.0.0.0/0` | Internet Gateway | Internet access |

### **Private Subnet Route Table (per AZ)**

| Destination | Target | Purpose |
|------------|--------|---------|
| `10.0.0.0/16` | local | Intra-VPC communication |
| `10.1.0.0/16` | Transit Gateway | Route to Non-Prod VPC |
| `10.2.0.0/16` | Transit Gateway | Route to Production VPC |
| `0.0.0.0/0` | NAT Gateway | Outbound internet (via NAT in same AZ) |

### **Traffic Flow Examples**

**1. Private Instance to Internet:**
```
EC2 (10.0.11.5) → Private Route Table → NAT Gateway (10.0.1.x) 
→ Internet Gateway → Internet
```

**2. Cross-VPC Communication (via Transit Gateway):**
```
Prod App (10.2.11.5) → Transit Gateway → Networking VPC (10.0.11.x)
```

**3. Internet to Load Balancer:**
```
Internet → Internet Gateway → ALB (10.0.1.15) → Target (10.0.11.20)
```

---

## 📈 Capacity Planning and Expansion

### **Current Utilization**

| Environment | VPC Size | Subnets | IPs Allocated | IPs Available | Utilization |
|------------|----------|---------|---------------|---------------|-------------|
| Networking | /16 (65,536) | 6 x /24 | ~1,500 | ~64,000 | 2.3% |
| Non-Prod | /16 (65,536) | 2 x /24 | ~500 | ~65,000 | 0.8% |
| Production | /16 (65,536) | 6 x /24 | ~1,500 | ~64,000 | 2.3% |

### **Expansion Patterns**

You can add additional subnet tiers without renumbering:

#### **Database Tier (Isolated Subnets)**
```hcl
database_subnet_cidrs = [
  "10.0.21.0/24",  # AZ1 - Databases
  "10.0.22.0/24",  # AZ2 - Databases
  "10.0.23.0/24"   # AZ3 - Databases
]
```

#### **Cache Tier (ElastiCache)**
```hcl
cache_subnet_cidrs = [
  "10.0.31.0/24",  # AZ1 - ElastiCache
  "10.0.32.0/24",  # AZ2 - ElastiCache
  "10.0.33.0/24"   # AZ3 - ElastiCache
]
```

#### **Container Platform (EKS/ECS)**
```hcl
container_subnet_cidrs = [
  "10.0.41.0/24",  # AZ1 - EKS Nodes
  "10.0.42.0/24",  # AZ2 - EKS Nodes
  "10.0.43.0/24"   # AZ3 - EKS Nodes
]
```

#### **Management Tier**
```hcl
management_subnet_cidrs = [
  "10.0.51.0/24",  # AZ1 - CI/CD, monitoring
  "10.0.52.0/24",  # AZ2 - CI/CD, monitoring
  "10.0.53.0/24"   # AZ3 - CI/CD, monitoring
]
```

### **Future Environments**

The numbering scheme supports additional environments:

```
10.3.0.0/16 → UAT/Pre-Prod environment
10.4.0.0/16 → DR (Disaster Recovery) environment
10.5.0.0/16 → Partner/External environment
10.6.0.0/16 → Security/Compliance environment
```

---

## 🌍 Transit Gateway Integration

### **Architecture Overview**

```
                    ┌─────────────────────────┐
                    │   Transit Gateway       │
                    │   (Networking Account)  │
                    └────────┬────────────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
    ┌───────▼──────┐  ┌──────▼──────┐  ┌─────▼──────┐
    │ Networking   │  │  Non-Prod   │  │ Production │
    │  VPC         │  │   VPC       │  │    VPC     │
    │ 10.0.0.0/16  │  │ 10.1.0.0/16 │  │ 10.2.0.0/16│
    └──────────────┘  └─────────────┘  └────────────┘
```

### **Route Table Strategy**

The Transit Gateway uses separate route tables for isolation:

| Route Table | Associated VPCs | Purpose |
|------------|----------------|---------|
| `networking-tgw-rt` | Networking VPC | Central hub, can reach all |
| `non-prod-tgw-rt` | Non-Prod VPC | Can reach networking only |
| `prod-tgw-rt` | Production VPC | Can reach networking only |

**Isolation Rules:**
- ✅ Non-Prod → Networking (allowed)
- ✅ Production → Networking (allowed)
- ✅ Networking → Non-Prod (allowed)
- ✅ Networking → Production (allowed)
- ❌ Non-Prod → Production (blocked)
- ❌ Production → Non-Prod (blocked)

This prevents cross-environment contamination while allowing access to shared services.

---

## 🛡️ Security and Best Practices

### **Network Segmentation**

✅ **Public/Private Separation**
- Internet-facing resources in public subnets
- Application workloads in private subnets
- No direct internet access for private resources

✅ **Environment Isolation**
- Non-overlapping CIDR blocks
- Transit Gateway route table controls
- Network ACLs for additional layer

✅ **Defense in Depth**
- Internet Gateway → Public Subnets only
- NAT Gateway → Outbound traffic from Private Subnets
- Security Groups → Instance-level firewall
- Network ACLs → Subnet-level firewall

### **High Availability Design**

✅ **Multi-AZ Deployment (Prod & Networking)**
- Resources distributed across 3 AZs
- Survives single AZ failure
- NAT Gateway redundancy

✅ **Single-AZ for Cost (Non-Prod)**
- Acceptable downtime for dev/test
- Significant cost savings
- Can be upgraded to multi-AZ if needed

### **Compliance Considerations**

✅ **VPC Flow Logs**
- Enabled on all VPCs
- Sent to CloudWatch Logs
- 30-day retention
- Audit trail for security/compliance

✅ **Transit Gateway Flow Logs**
- Monitor cross-VPC traffic
- Detect anomalies
- Compliance reporting

✅ **DNS Configuration**
- DNS hostnames enabled
- DNS resolution enabled
- Supports hybrid cloud scenarios

---

## 💰 Cost Optimization

### **Cost Breakdown by Environment**

#### **Non-Production (Single-AZ)**
```
NAT Gateway:           ~$32/month  (1 gateway)
Data Transfer (out):   ~$50/month  (varies)
VPC (no charge):       $0
Transit Gateway:       ~$36/month  (attachment + data)
──────────────────────────────────
Estimated Total:       ~$118/month
```

#### **Production (Multi-AZ)**
```
NAT Gateways:          ~$96/month  (3 gateways)
Data Transfer (out):   ~$150/month (varies, higher traffic)
VPC (no charge):       $0
Transit Gateway:       ~$36/month  (attachment + data)
──────────────────────────────────
Estimated Total:       ~$282/month
```

### **Cost Optimization Strategies**

✅ **Right-size subnets** - /24 provides enough IPs without waste  
✅ **Single NAT in non-prod** - 67% savings vs multi-AZ  
✅ **VPC endpoints** - Reduce data transfer costs for AWS services  
✅ **Monitor usage** - Review VPC Flow Logs for optimization opportunities  
✅ **Reserved capacity** - For predictable workloads (NAT Gateway data)

---

## 📚 Reference Documentation

### **CIDR Calculations**

| CIDR | Subnet Mask | Total IPs | Usable IPs | Hosts |
|------|------------|-----------|------------|-------|
| /16 | 255.255.0.0 | 65,536 | 65,531 | Large VPC |
| /20 | 255.255.240.0 | 4,096 | 4,091 | Large subnet |
| /24 | 255.255.255.0 | 256 | 251 | Standard subnet |
| /28 | 255.255.255.240 | 16 | 11 | Tiny subnet |

### **AWS Regional Availability Zones**

**ap-southeast-2 (Sydney):**
- ap-southeast-2a
- ap-southeast-2b
- ap-southeast-2c

### **IP Address Ranges (RFC 1918)**

| CIDR Block | Range | Total IPs | Usage |
|-----------|-------|-----------|-------|
| 10.0.0.0/8 | 10.0.0.0 - 10.255.255.255 | 16,777,216 | **Used in this project** |
| 172.16.0.0/12 | 172.16.0.0 - 172.31.255.255 | 1,048,576 | Reserved for future |
| 192.168.0.0/16 | 192.168.0.0 - 192.168.255.255 | 65,536 | Reserved for future |

---

## 🔍 Troubleshooting

### **IP Address Conflicts**

**Symptom:** Resources can't communicate across VPCs

**Check:**
```bash
# Verify VPC CIDR blocks don't overlap
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock]' --output table
```

**Solution:** Ensure all VPC CIDRs are non-overlapping

### **NAT Gateway Issues**

**Symptom:** Private instances can't reach internet

**Check:**
1. NAT Gateway is in public subnet
2. Route table has `0.0.0.0/0 → NAT Gateway`
3. Security groups allow outbound traffic
4. Network ACLs allow traffic

### **Transit Gateway Routing**

**Symptom:** Can't reach resources in another VPC

**Check:**
```bash
# Verify Transit Gateway attachments
aws ec2 describe-transit-gateway-attachments

# Check route tables
aws ec2 describe-transit-gateway-route-tables
```

**Solution:** Verify route table associations and propagations

---

## 📖 Additional Resources

- [AWS VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [AWS Transit Gateway Guide](https://docs.aws.amazon.com/vpc/latest/tgw/)
- [VPC CIDR Blocks](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-cidr-blocks.html)
- [NAT Gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)

---

## 🎯 Summary

This network design provides:

✅ **Scalability** - Room to grow from 2% to 100% utilization  
✅ **Security** - Public/private isolation, environment separation  
✅ **High Availability** - Multi-AZ for production workloads  
✅ **Cost Optimization** - Single-AZ for non-production  
✅ **Transit Gateway Ready** - Non-overlapping CIDRs  
✅ **Best Practices** - Following AWS Well-Architected Framework  
✅ **Clear Documentation** - Self-explanatory IP addressing scheme

The infrastructure is production-ready, secure, and built for long-term growth! 🚀
