---
name: security-governance
description: Snowflake Security & Governance guidance for role management, privilege auditing, access control, login monitoring, and compliance enforcement.
---

# Security & Governance Guide

## Scope

Use this skill for:

- Role hierarchy and inheritance analysis
- Privilege grant tracking and auditing
- Failed login attempt monitoring
- Login anomaly detection (potential attacks)
- Excessive privilege identification
- Data access pattern analysis
- Unauthorized access attempt tracking
- User and role audit compliance
- Network policy violation monitoring

## Generic Object Pattern

Replace placeholders in this template:

- `<APP_DB>.<APP_SCHEMA>.<SECURITY_AGENT_NAME>`
- `<APP_DB>.<APP_SCHEMA>.SV_*` (Security semantic views)
- `<APP_DB>.<APP_SCHEMA>.V_*` (Security base views)

## Common Questions & Approaches

### Role Management
**Question:** "Show me the role hierarchy"
**Agent Response:** Displays parent-child role relationships and inheritance structure.

### Privilege Auditing
**Question:** "Who has ACCOUNTADMIN privileges?"
**Agent Response:** Lists users with sensitive role assignments and their usage patterns.

### Failed Login Monitoring
**Question:** "Are there any failed login attempts?"
**Agent Response:** Shows failed login attempts with error codes and client IPs.

### Anomaly Detection
**Question:** "Detect any suspicious login activity"
**Agent Response:** Identifies patterns indicating brute force attacks or credential compromise.

### Excessive Privileges
**Question:** "Which users have unused privileged roles?"
**Agent Response:** Finds ACCOUNTADMIN/SECURITYADMIN assignments with no recent usage.

### Data Access Patterns
**Question:** "Who is accessing sensitive tables?"
**Agent Response:** Tracks read/write access to specific tables by user and role.

### Unauthorized Access
**Question:** "Show unauthorized access attempts"
**Agent Response:** Lists queries that failed due to insufficient privileges.

### User Audit
**Question:** "Which users are inactive but still have access?"
**Agent Response:** Identifies user accounts with role assignments but no recent activity.

## Security Best Practices

### Privilege Management
- Review ACCOUNTADMIN and SECURITYADMIN assignments quarterly
- Revoke unused privileged roles (no activity in 60+ days)
- Implement least-privilege access model
- Use custom roles instead of default roles where possible

### Access Monitoring
- Monitor failed login attempts daily
- Investigate login anomalies flagged as "Critical" or "High"
- Review unauthorized access attempts weekly
- Track data access patterns for compliance

### Compliance & Auditing
- Conduct user/role audits monthly
- Document privileged role usage justification
- Maintain audit trail of privilege grants
- Monitor network policy violations

## Risk Levels

### Critical
- 10+ failed login attempts in an hour (brute force attack)
- Privileged role unused for 60+ days
- Multiple unauthorized access attempts from same user

### High
- 5-9 failed login attempts in an hour
- Privileged role used less than 5 times in 90 days
- Failed logins from multiple distinct IPs

### Medium
- 3-4 failed login attempts in an hour
- User with 5+ role assignments
- Occasional unauthorized access attempts

### Low
- Normal failed login patterns
- Standard role assignments
- Isolated authorization errors

## Compliance Frameworks

This agent supports compliance requirements for:
- SOC 2 (access control monitoring)
- GDPR (data access tracking)
- HIPAA (audit trail maintenance)
- SOX (privilege separation)
- PCI DSS (access restriction enforcement)

## Recommended Review Schedule

- **Daily**: Failed logins, login anomalies
- **Weekly**: Unauthorized access, privilege grants
- **Monthly**: User audits, role reviews
- **Quarterly**: Full security assessment, privileged role validation
