# osquery Query Packs

This directory contains osquery query packs organized by NIST SP 800-171 control families.

## Pack Structure

Each pack file is a JSON configuration containing queries related to a specific control family:

```json
{
  "platform": "windows",
  "version": "1.0.0",
  "queries": {
    "query_name": {
      "query": "SELECT ... FROM ... WHERE ...;",
      "interval": 3600,
      "description": "Description of what this query does",
      "value": "Why this query matters for compliance",
      "snapshot": true
    }
  }
}
```

## Available Packs

| Pack File | Control Family | Description |
|-----------|----------------|-------------|
| `ac_access_control.conf` | 3.1 Access Control | User accounts, permissions, session management |
| `au_audit_accountability.conf` | 3.3 Audit & Accountability | Logging configuration, audit policies |
| `cm_configuration_management.conf` | 3.4 Configuration Management | System baselines, software inventory |
| `ia_identification_authentication.conf` | 3.5 Identification & Authentication | Password policies, authentication mechanisms |
| `sc_system_communications.conf` | 3.13 System & Communications Protection | Firewall, network configuration, encryption |
| `si_system_integrity.conf` | 3.14 System & Information Integrity | Antivirus, patches, file integrity |

## Pack Naming Convention

Format: `{control_family}_{family_name}.conf`

Examples:
- `ac_access_control.conf` - Access Control (AC)
- `au_audit_accountability.conf` - Audit and Accountability (AU)
- `cm_configuration_management.conf` - Configuration Management (CM)

## Query Intervals

Recommended intervals based on data volatility:

- **Static configuration** (3600s / 1 hour): Password policies, audit configuration
- **Semi-static** (1800s / 30 min): Installed software, user accounts
- **Dynamic** (900s / 15 min): Active sessions, running processes
- **Highly dynamic** (300s / 5 min): Network connections, login events

## Using Packs

### Deploy to osquery

Copy packs to the osquery installation:

```powershell
Copy-Item .\packs\*.conf "C:\Program Files\osquery\packs\"
```

### Configure in osquery.conf

Reference packs in the main configuration:

```json
{
  "packs": {
    "nist_access_control": "C:\\Program Files\\osquery\\packs\\ac_access_control.conf",
    "nist_audit": "C:\\Program Files\\osquery\\packs\\au_audit_accountability.conf"
  }
}
```

### Verify Pack Loading

```sql
-- In osqueryi
SELECT * FROM osquery_packs;
SELECT * FROM osquery_schedule WHERE name LIKE 'pack_%';
```

## Development Guidelines

When creating new packs:

1. **Test queries** in osqueryi before adding to packs
2. **Validate JSON** syntax (use a linter)
3. **Document rationale** for each query
4. **Consider performance** impact of query intervals
5. **Map to controls** in `/mappings/nist800171_mapping.yaml`
6. **Include metadata**: platform, version, description

## Example Pack

```json
{
  "platform": "windows",
  "version": "1.0.0",
  "queries": {
    "ac_local_users": {
      "query": "SELECT uid, username, description, type FROM users WHERE uid >= 1000;",
      "interval": 3600,
      "description": "Enumerate local user accounts (excluding system accounts)",
      "value": "Maps to NIST 800-171 control 3.1.1 - Limit system access to authorized users",
      "snapshot": true
    },
    "ac_admin_users": {
      "query": "SELECT u.username, u.uid, g.groupname FROM users u JOIN user_groups ug ON u.uid = ug.uid JOIN groups g ON ug.gid = g.gid WHERE g.groupname = 'Administrators';",
      "interval": 1800,
      "description": "List all members of the local Administrators group",
      "value": "Maps to NIST 800-171 control 3.1.5 - Employ the principle of least privilege",
      "snapshot": true
    }
  }
}
```

## References

- [osquery Pack Documentation](https://osquery.readthedocs.io/en/stable/deployment/configuration/#packs)
- [osquery Query Scheduling](https://osquery.readthedocs.io/en/stable/deployment/configuration/#schedule)
- NIST SP 800-171 mapping guide: `/docs/mapping_guide.md`
