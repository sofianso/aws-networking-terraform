# Network Diagrams

## Overall Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         AWS Multi-Account Architecture                        │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                            Networking Account                                 │
│  Account ID: 123456789012                                                    │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     Transit Gateway (64512)                          │    │
│  │  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐             │    │
│  │  │ Networking  │  │   Non-Prod   │  │     Prod      │             │    │
│  │  │ Route Table │  │ Route Table  │  │  Route Table  │             │    │
│  │  └──────┬──────┘  └──────┬───────┘  └───────┬───────┘             │    │
│  └─────────┼────────────────┼──────────────────┼──────────────────────┘    │
│            │                │                  │                            │
│       ┌────▼────────────────┼──────────────────┼──────────┐                │
│       │    VPC 10.0.0.0/16  │                  │          │                │
│       │  ┌────────────────┐ │                  │          │                │
│       │  │  ap-southeast-2a    │ │                  │          │                │
│       │  │ Public: .1.0/24│ │                  │          │                │
│       │  │ Private:.11.0/24│ │                  │          │                │
│       │  │   NAT GW       │ │                  │          │                │
│       │  └────────────────┘ │                  │          │                │
│       │  ┌────────────────┐ │                  │          │                │
│       │  │  ap-southeast-2b    │ │                  │          │                │
│       │  │ Public: .2.0/24│ │                  │          │                │
│       │  │ Private:.12.0/24│ │                  │          │                │
│       │  │   NAT GW       │ │                  │          │                │
│       │  └────────────────┘ │                  │          │                │
│       │  ┌────────────────┐ │                  │          │                │
│       │  │  ap-southeast-2c    │ │                  │          │                │
│       │  │ Public: .3.0/24│ │                  │          │                │
│       │  │ Private:.13.0/24│ │                  │          │                │
│       │  │   NAT GW       │ │                  │          │                │
│       │  └────────────────┘ │                  │          │                │
│       │  Internet Gateway   │                  │          │                │
│       └────────┬────────────┘                  │          │                │
│                │                               │          │                │
└────────────────┼───────────────────────────────┼──────────┼────────────────┘
                 │                               │          │
              Internet                           │          │
                                                 │          │
┌────────────────────────────────────────────────┼──────────┼────────────────┐
│                         Non-Prod Account       │          │                │
│  Account ID: 234567890123                      │          │                │
│                                           ┌────▼──────────┼──────┐         │
│                                           │ VPC 10.1.0.0/16      │         │
│                                           │ ┌──────────────────┐ │         │
│                                           │ │   ap-southeast-2a     │ │         │
│                                           │ │ Public: .1.0/24  │ │         │
│                                           │ │ Private: .11.0/24│ │         │
│                                           │ │   NAT GW         │ │         │
│                                           │ └──────────────────┘ │         │
│                                           │ Internet Gateway     │         │
│                                           └──────────┬───────────┘         │
│                                                      │                     │
└──────────────────────────────────────────────────────┼─────────────────────┘
                                                       │
                                                    Internet
                                                       
┌────────────────────────────────────────────────────────────────────────────┐
│                            Prod Account                                     │
│  Account ID: 345678901234                                                  │
│                                                              ┌─────────────┐
│                                                         ┌────▼───────────┐ │
│                                                         │ VPC 10.2.0.0/16│ │
│                                                         │ ┌────────────┐ │ │
│                                                         │ │ap-southeast-2a  │ │ │
│                                                         │ │Pub:.1.0/24 │ │ │
│                                                         │ │Prv:.11.0/24│ │ │
│                                                         │ │  NAT GW    │ │ │
│                                                         │ └────────────┘ │ │
│                                                         │ ┌────────────┐ │ │
│                                                         │ │ap-southeast-2b  │ │ │
│                                                         │ │Pub:.2.0/24 │ │ │
│                                                         │ │Prv:.12.0/24│ │ │
│                                                         │ │  NAT GW    │ │ │
│                                                         │ └────────────┘ │ │
│                                                         │ ┌────────────┐ │ │
│                                                         │ │ap-southeast-2c  │ │ │
│                                                         │ │Pub:.3.0/24 │ │ │
│                                                         │ │Prv:.13.0/24│ │ │
│                                                         │ │  NAT GW    │ │ │
│                                                         │ └────────────┘ │ │
│                                                         │ Internet GW    │ │
│                                                         └───────┬────────┘ │
│                                                                 │          │
└─────────────────────────────────────────────────────────────────┼──────────┘
                                                                  │
                                                               Internet
```

## Traffic Flow Diagrams

### 1. Outbound Internet Traffic (Private Subnet)

```
┌──────────────┐      ┌────────────┐      ┌──────────────┐      ┌──────────┐
│   EC2 in     │ ───> │   Route    │ ───> │ NAT Gateway  │ ───> │ Internet │
│   Private    │      │   Table    │      │  (Public)    │      │ Gateway  │
│   Subnet     │      │            │      │              │      │          │
└──────────────┘      └────────────┘      └──────────────┘      └────┬─────┘
                                                                       │
                                                                       v
                                                                   Internet
```

### 2. Inbound Internet Traffic (Public Subnet)

```
               ┌──────────┐      ┌──────────────┐      ┌──────────────┐
   Internet ───│ Internet │ ───> │   Route      │ ───> │   EC2 in     │
               │ Gateway  │      │   Table      │      │   Public     │
               └──────────┘      └──────────────┘      │   Subnet     │
                                                        └──────────────┘
```

### 3. Inter-VPC Traffic (Transit Gateway)

```
┌──────────────┐      ┌────────────┐      ┌────────────┐      ┌──────────────┐
│   EC2 in     │ ───> │   Route    │ ───> │  Transit   │ ───> │   EC2 in     │
│  Non-Prod    │      │   Table    │      │  Gateway   │      │   Prod VPC   │
│    VPC       │      │            │      │            │      │              │
└──────────────┘      └────────────┘      └────────────┘      └──────────────┘
```

## Subnet Layout

### Networking VPC (10.0.0.0/16)
```
┌─────────────────────────────────────────────────────────────┐
│                     Networking VPC                           │
├─────────────────────────────────────────────────────────────┤
│ AZ          │ Public Subnet  │ Private Subnet  │ NAT GW    │
├─────────────┼────────────────┼─────────────────┼───────────┤
│ ap-southeast-2a  │ 10.0.1.0/24    │ 10.0.11.0/24    │ Yes       │
│ ap-southeast-2b  │ 10.0.2.0/24    │ 10.0.12.0/24    │ Yes       │
│ ap-southeast-2c  │ 10.0.3.0/24    │ 10.0.13.0/24    │ Yes       │
└─────────────┴────────────────┴─────────────────┴───────────┘
```

### Non-Prod VPC (10.1.0.0/16)
```
┌─────────────────────────────────────────────────────────────┐
│                      Non-Prod VPC                            │
├─────────────────────────────────────────────────────────────┤
│ AZ          │ Public Subnet  │ Private Subnet  │ NAT GW    │
├─────────────┼────────────────┼─────────────────┼───────────┤
│ ap-southeast-2a  │ 10.1.1.0/24    │ 10.1.11.0/24    │ Yes       │
└─────────────┴────────────────┴─────────────────┴───────────┘
```

### Production VPC (10.2.0.0/16)
```
┌─────────────────────────────────────────────────────────────┐
│                      Production VPC                          │
├─────────────────────────────────────────────────────────────┤
│ AZ          │ Public Subnet  │ Private Subnet  │ NAT GW    │
├─────────────┼────────────────┼─────────────────┼───────────┤
│ ap-southeast-2a  │ 10.2.1.0/24    │ 10.2.11.0/24    │ Yes       │
│ ap-southeast-2b  │ 10.2.2.0/24    │ 10.2.12.0/24    │ Yes       │
│ ap-southeast-2c  │ 10.2.3.0/24    │ 10.2.13.0/24    │ Yes       │
└─────────────┴────────────────┴─────────────────┴───────────┘
```

## Component Dependencies

```
GitHub OIDC Role
    (Independent - can deploy first)
    
Transit Gateway
    (Must deploy before VPCs)
    │
    ├─> Networking VPC
    │       (Can attach to TGW)
    │
    ├─> Non-Prod VPC
    │       (Depends on TGW)
    │
    └─> Production VPC
            (Depends on TGW)
```

## Deployment Sequence

```
Step 1: Prerequisites
├─> Create S3 Bucket (aws-networking-terraform)
└─> Create DynamoDB Table (terraform-locks)

Step 2: Deploy OIDC
└─> GitHub OIDC Role
    └─> Configure GitHub Secrets

Step 3: Deploy Networking
└─> Transit Gateway
    └─> Networking VPC
        └─> Attach to Transit Gateway

Step 4: Deploy Non-Prod
└─> Non-Prod VPC
    └─> Attach to Transit Gateway

Step 5: Deploy Production
└─> Production VPC
    └─> Attach to Transit Gateway
```

## CI/CD Flow

```
Developer               GitHub                AWS
    │                     │                    │
    │   Create PR         │                    │
    ├──────────────────>  │                    │
    │                     │                    │
    │                     │  Trigger Workflow  │
    │                     ├─────────────────>  │
    │                     │                    │
    │                     │   Request Token    │
    │                     │ (OIDC)             │
    │                     ├──────────────────> │
    │                     │                    │
    │                     │  Return Token      │
    │                     │ <────────────────┤ │
    │                     │                    │
    │                     │  Assume Role       │
    │                     ├──────────────────> │
    │                     │                    │
    │                     │  Run terraform plan│
    │                     │ <────────────────┤ │
    │                     │                    │
    │  Comment on PR      │                    │
    │ <──────────────────┤                    │
    │                     │                    │
```

## Route Table Configuration

### Public Subnet Route Table
```
┌─────────────────────────────────────────┐
│      Public Route Table                 │
├─────────────────────┬───────────────────┤
│ Destination         │ Target            │
├─────────────────────┼───────────────────┤
│ 10.X.0.0/16 (VPC)   │ local             │
│ 0.0.0.0/0           │ Internet Gateway  │
└─────────────────────┴───────────────────┘
```

### Private Subnet Route Table
```
┌─────────────────────────────────────────┐
│      Private Route Table                │
├─────────────────────┬───────────────────┤
│ Destination         │ Target            │
├─────────────────────┼───────────────────┤
│ 10.X.0.0/16 (VPC)   │ local             │
│ 0.0.0.0/0           │ NAT Gateway       │
│ 10.0.0.0/8          │ Transit Gateway   │
└─────────────────────┴───────────────────┘
```

## Monitoring & Logging

```
┌────────────────────────────────────────────────────────┐
│                    CloudWatch Logs                     │
├────────────────────────────────────────────────────────┤
│                                                        │
│  ┌──────────────────┐  ┌──────────────────┐          │
│  │  VPC Flow Logs   │  │  TGW Flow Logs   │          │
│  │  /aws/vpc/       │  │  /aws/tgw/       │          │
│  │  networking      │  │  networking      │          │
│  └──────────────────┘  └──────────────────┘          │
│                                                        │
│  ┌──────────────────┐  ┌──────────────────┐          │
│  │  VPC Flow Logs   │  │  VPC Flow Logs   │          │
│  │  /aws/vpc/       │  │  /aws/vpc/       │          │
│  │  non-prod        │  │  prod            │          │
│  └──────────────────┘  └──────────────────┘          │
│                                                        │
│  Retention: 30 days                                   │
└────────────────────────────────────────────────────────┘
```
