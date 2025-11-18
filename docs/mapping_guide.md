# NIST SP 800-171 Control Mapping Guide

## Overview

This guide explains how osquery queries are mapped to NIST SP 800-171 Rev 2 controls, including methodology, limitations, and interpretation guidelines.

## Mapping Methodology

### Control Assessment via osquery

osquery provides endpoint visibility by querying system state as a relational database. For NIST 800-171 compliance, we map controls to observable system artifacts:

1. **System Configuration** - Registry keys, file permissions, service states
2. **User & Account Management** - Local accounts, groups, privileges
3. **Audit & Logging** - Event log configuration, audit policies
4. **Software & Patches** - Installed applications, updates, vulnerabilities
5. **Network & Communication** - Firewall rules, listening ports, connections
6. **System Integrity** - File hashes, unsigned binaries, security software

### Automation Levels

Each control is categorized by automation feasibility:

#### Level 1: Fully Automated
Evidence collected and assessed automatically without human interpretation.

**Examples:**
- 3.1.1 - Limit system access to authorized users (query local accounts)
- 3.4.2 - Establish configuration baselines (query system settings)
- 3.14.1 - Identify flaws timely (query missing patches)

#### Level 2: Partially Automated
Evidence collected automatically, but requires human analysis or policy context.

**Examples:**
- 3.1.5 - Employ least privilege (query user permissions, but business context needed)
- 3.13.1 - Monitor boundary communications (collect connections, but requires baseline)
- 3.14.6 - Monitor organization systems (collect security events, but pattern analysis needed)

#### Level 3: Manual Only
Controls that cannot be assessed via endpoint telemetry.

**Examples:**
- 3.2.1 - Security awareness training (organizational process)
- 3.9.1 - Screen personnel (HR process)
- 3.10.1 - Physical access authorizations (facility management)

### Control Mapping Structure

Each mapping includes:

```yaml
control_id: "3.1.1"
control_title: "Limit system access to authorized users, processes acting on behalf of users, and devices"
control_family: "Access Control"
automation_level: "fully_automated"
osquery_tables:
  - users
  - groups
  - logged_in_users
queries:
  - query_id: "ac_3.1.1_local_users"
    description: "Enumerate all local user accounts"
    rationale: "Identifies unauthorized or unexpected local accounts"
    query: "SELECT uid, username, description, directory, shell FROM users WHERE uid >= 1000;"
    expected_result: "Only authorized users should be present"
    severity: "high"

remediation:
  - "Remove unauthorized accounts using: net user <username> /delete"
  - "Review account creation audit logs"
  - "Validate against authorized user list"

limitations:
  - "Does not validate domain accounts (requires AD integration)"
  - "Cannot determine if accounts are actively used"
  - "Business context required to define 'authorized'"

references:
  - "NIST SP 800-171 Rev 2 Section 3.1.1"
  - "CIS Benchmark for Windows Server - Control 1.1"
```

## NIST SP 800-171 Control Families

### 3.1 Access Control (AC)

**Focus:** Who can access what, and under what conditions.

**osquery Coverage:**
- User account enumeration
- Group membership
- Access control lists (file/registry permissions)
- Login session tracking
- Password policies

**Key Queries:**
- Local user accounts
- Administrative group members
- Remote desktop users
- Shared folder permissions
- Account lockout policies

### 3.3 Audit and Accountability (AU)

**Focus:** Creating, protecting, and retaining audit records.

**osquery Coverage:**
- Event log configuration
- Audit policy settings
- Log file locations and sizes
- Security event collection status

**Key Queries:**
- Audit policy configuration
- Event log settings (size, retention)
- Security event forwarding status
- PowerShell logging configuration

### 3.4 Configuration Management (CM)

**Focus:** Baseline configurations and change control.

**osquery Coverage:**
- Registry settings
- Security configurations
- Installed software inventory
- System update status

**Key Queries:**
- Security baselines (registry keys)
- Installed applications
- Windows Update configuration
- Service configurations

### 3.5 Identification and Authentication (IA)

**Focus:** User identity verification and credential management.

**osquery Coverage:**
- Password policy settings
- Account lockout policies
- Multi-factor authentication status
- Credential storage mechanisms

**Key Queries:**
- Password complexity requirements
- Account lockout thresholds
- Cached credential count
- Smart card configuration

### 3.13 System and Communications Protection (SC)

**Focus:** Network security and boundary protection.

**osquery Coverage:**
- Firewall status and rules
- Network interfaces and routing
- Listening ports and connections
- Encryption protocols

**Key Queries:**
- Windows Firewall status
- Open ports and listening services
- Active network connections
- SMB/RDP encryption settings

### 3.14 System and Information Integrity (SI)

**Focus:** Flaw remediation, malware protection, monitoring.

**osquery Coverage:**
- Antivirus status
- Missing patches
- Unsigned executables
- System file integrity

**Key Queries:**
- Windows Defender status
- Installed patches and missing updates
- Running services (security software)
- Startup items and persistence

## Query Development Guidelines

### 1. Control Interpretation

Before writing queries, understand the control requirement:
- Read the NIST SP 800-171 control description
- Review derived requirements if applicable
- Identify what evidence demonstrates compliance
- Determine what osquery can observe

### 2. Table Selection

Choose appropriate osquery tables:
- Review [osquery schema documentation](https://osquery.io/schema/)
- Prefer stable, cross-version compatible tables
- Test on target Windows versions (Server 2016+, Win10/11)
- Consider performance impact

### 3. Query Construction

Write clear, efficient queries:
- Use explicit column selection (avoid `SELECT *`)
- Add WHERE clauses to filter results
- Include meaningful column aliases
- Comment complex logic
- Test for syntax errors

### 4. Pass/Fail Logic

Define success criteria:
- What result indicates compliance?
- What result indicates non-compliance?
- What result is inconclusive?
- How to handle null/empty results?

### 5. False Positives/Negatives

Consider edge cases:
- Legitimate exceptions (service accounts, admin tools)
- Environment-specific configurations
- Temporary states vs. persistent issues
- Business context requirements

## Example Mapping Workflow

Let's map **3.1.1 - Limit system access to authorized users**:

**Step 1: Understand the Control**
> "Limit information system access to authorized users, processes acting on behalf of users, or devices (including other information systems)."

**Step 2: Identify Evidence**
- List of user accounts on the system
- Active login sessions
- Remote access permissions

**Step 3: Select osquery Tables**
- `users` - Local user accounts
- `logged_in_users` - Active sessions
- `groups` - Group membership (e.g., Remote Desktop Users)

**Step 4: Write Queries**

```sql
-- Query 1: Enumerate local user accounts
SELECT
  uid,
  username,
  description,
  type,
  shell
FROM users
WHERE uid >= 1000  -- Exclude system accounts
ORDER BY uid;

-- Query 2: Check administrative accounts
SELECT
  u.username,
  u.uid,
  g.groupname
FROM users u
JOIN user_groups ug ON u.uid = ug.uid
JOIN groups g ON ug.gid = g.gid
WHERE g.groupname IN ('Administrators', 'Domain Admins')
ORDER BY u.username;

-- Query 3: Active login sessions
SELECT
  user,
  host,
  time,
  type
FROM logged_in_users;
```

**Step 5: Define Assessment Logic**

Compliance check:
1. Compare discovered accounts against authorized user list (external input required)
2. Flag any unexpected administrative accounts
3. Review active sessions for unauthorized access

**Step 6: Document Limitations**
- Requires external authorized user list for comparison
- Does not cover domain accounts (AD-level control)
- Point-in-time snapshot (not continuous monitoring)

## Using the Mappings

### For Security Engineers

1. Review control mappings in `/mappings/nist800171_mapping.yaml`
2. Deploy osquery packs to Windows endpoints
3. Run `scripts/generate_report.py` to assess compliance
4. Analyze findings and remediate gaps
5. Maintain authorized baseline configurations

### For Compliance Managers

1. Understand automation levels (what's automated vs. manual)
2. Use reports for evidence collection during audits
3. Track control coverage metrics
4. Identify controls requiring compensating measures
5. Document exceptions and risk acceptance

### For Contributors

1. Follow this mapping methodology for new controls
2. Test queries on representative Windows systems
3. Document rationale and limitations
4. Submit PRs with mapping validation evidence
5. Update coverage metrics

## References

- [NIST SP 800-171 Rev 2](https://csrc.nist.gov/publications/detail/sp/800-171/rev-2/final)
- [osquery Documentation](https://osquery.io/)
- [osquery Schema](https://osquery.io/schema/)
- [Windows Security Baselines](https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-security-baselines)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

## Next Steps

1. Review the initial control mappings
2. Test queries on your Windows environment
3. Customize queries for your organization's policies
4. Integrate with your compliance reporting workflow
5. Contribute back improvements and new mappings
