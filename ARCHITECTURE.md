# Architecture Decision Records

## ADR-001: Use Terragrunt for Multi-Account Management

**Date**: 2025-11-08

**Status**: Accepted

**Context**: 
We need to manage infrastructure across multiple AWS accounts (networking, non-prod, prod) with similar but slightly different configurations.

**Decision**: 
Use Terragrunt to wrap Terraform modules and provide:
- DRY (Don't Repeat Yourself) configuration
- Environment-specific overrides
- Dependency management between components
- Remote state management

**Consequences**:
- Additional tool to learn and maintain
- Better code reuse across environments
- Easier to maintain consistent configurations
- Clear dependency chain between resources

---

## ADR-002: Transit Gateway as Central Hub

**Date**: 2025-11-08

**Status**: Accepted

**Context**: 
Need to enable communication between VPCs across different AWS accounts while maintaining network isolation and security.

**Decision**: 
Implement AWS Transit Gateway in the networking account as a central hub for all inter-VPC traffic.

**Consequences**:
- Centralized network management
- Simplified routing between VPCs
- Easier to add new VPCs to the network
- Additional cost for Transit Gateway
- Single point of failure (mitigated by AWS SLA)

---

## ADR-003: Single AZ for Non-Prod, Multi-AZ for Prod

**Date**: 2025-11-08

**Status**: Accepted

**Context**: 
Balance between high availability requirements and cost optimization.

**Decision**: 
- Non-prod: Single AZ deployment with one NAT Gateway
- Prod: Multi-AZ deployment with NAT Gateway per AZ
- Networking: Multi-AZ for infrastructure resilience

**Consequences**:
- Reduced costs in non-prod environment
- High availability in production
- Some risk of downtime in non-prod during AZ failures
- Clear separation between environments

---

## ADR-004: OIDC for GitHub Actions Authentication

**Date**: 2025-11-08

**Status**: Accepted

**Context**: 
Need secure CI/CD integration without storing long-lived AWS credentials in GitHub.

**Decision**: 
Use GitHub OIDC provider to authenticate GitHub Actions workflows with AWS.

**Consequences**:
- No AWS credentials stored in GitHub
- Short-lived tokens for each workflow run
- Better security posture
- Slightly more complex initial setup
- Dependent on GitHub OIDC availability

---

## ADR-005: Separate State Files per Component

**Date**: 2025-11-08

**Status**: Accepted

**Context**: 
Need to manage state for multiple components across different accounts and regions.

**Decision**: 
Use separate state files organized by account/region/component path:
- `networking/ap-southeast-2/transit-gateway/terraform.tfstate`
- `networking/ap-southeast-2/vpc/terraform.tfstate`
- etc.

**Consequences**:
- Isolated blast radius for state corruption
- Parallel operations on different components
- Clearer component boundaries
- More state files to manage
- Requires dependency management between components

---

## ADR-006: VPC Flow Logs for All VPCs

**Date**: 2025-11-08

**Status**: Accepted

**Context**: 
Need visibility into network traffic for security and troubleshooting.

**Decision**: 
Enable VPC Flow Logs for all VPCs, storing logs in CloudWatch Logs with 30-day retention.

**Consequences**:
- Better security monitoring
- Easier troubleshooting of network issues
- Additional CloudWatch Logs costs
- Data retention for compliance
- Ability to analyze traffic patterns

---

## ADR-007: Makefile for Developer Experience

**Date**: 2025-11-08

**Status**: Accepted

**Context**: 
Terragrunt commands can be verbose and repetitive for common operations.

**Decision**: 
Provide a Makefile with convenient shortcuts for common operations (plan, apply, format).

**Consequences**:
- Easier onboarding for new team members
- Consistent command usage across team
- Reduced typing for common operations
- One more file to maintain
- Team needs to learn Make syntax for modifications

---

## ADR-008: Public and Private Subnets in All VPCs

**Date**: 2025-11-08

**Status**: Accepted

**Context**: 
Need to support both internet-facing and internal workloads.

**Decision**: 
Create both public and private subnets in all VPCs:
- Public: Direct route to Internet Gateway
- Private: Route through NAT Gateway for outbound traffic

**Consequences**:
- Flexibility to deploy different workload types
- Better security by default (workloads in private subnets)
- Increased complexity in routing
- Additional costs for NAT Gateways
- Standard AWS best practice architecture

---

## Future Considerations

### Under Consideration

1. **VPC Peering vs Transit Gateway**
   - Current: Transit Gateway
   - Alternative: Direct VPC peering
   - Trade-off: Cost vs simplicity

2. **Centralized Egress VPC**
   - Current: NAT Gateway per VPC
   - Alternative: Single egress VPC with NAT
   - Trade-off: Cost vs latency

3. **PrivateLink for AWS Services**
   - Current: Public endpoints through NAT
   - Alternative: VPC endpoints
   - Trade-off: Cost vs security/performance

4. **Network Firewall**
   - Current: Security groups and NACLs
   - Alternative: AWS Network Firewall
   - Trade-off: Cost vs advanced inspection
