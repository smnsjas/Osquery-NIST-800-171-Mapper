# NIST 800-171 Control Mappings

This directory contains structured mappings between NIST SP 800-171 controls and osquery queries.

## Mapping Files

### nist800171_mapping.yaml

Primary mapping file that correlates:
- NIST 800-171 control requirements
- osquery tables and queries
- Assessment criteria (pass/fail logic)
- Automation level classification
- Remediation guidance

## Mapping Structure

Each control mapping includes:

```yaml
controls:
  - control_id: "3.1.1"
    control_title: "Limit system access to authorized users"
    control_family: "Access Control"
    nist_description: "Full control text from NIST SP 800-171"

    automation_level: "fully_automated" | "partially_automated" | "manual_only"

    osquery_tables:
      - users
      - groups
      - logged_in_users

    queries:
      - query_id: "ac_3.1.1_local_users"
        pack: "ac_access_control.conf"
        query_name: "ac_local_users"
        description: "Enumerate local user accounts"
        rationale: "Identifies unauthorized accounts"
        severity: "high" | "medium" | "low"

        expected_result:
          type: "whitelist" | "blacklist" | "threshold" | "existence"
          description: "Only authorized users present"

    assessment_criteria:
      pass: "All discovered accounts are on authorized list"
      fail: "Unauthorized accounts detected"
      inconclusive: "Unable to compare against authorized baseline"

    remediation:
      - "Remove unauthorized accounts: net user <username> /delete"
      - "Review account creation logs"
      - "Update authorized user baseline"

    limitations:
      - "Requires external authorized user list"
      - "Does not assess domain accounts"
      - "Point-in-time snapshot only"

    references:
      - url: "https://csrc.nist.gov/publications/detail/sp/800-171/rev-2/final"
        title: "NIST SP 800-171 Rev 2"
      - url: "https://osquery.io/schema/current#users"
        title: "osquery users table"
```

## Automation Levels

### Fully Automated
Technical evidence collected and assessed without human interpretation.
- System configurations
- Installed software
- User accounts
- Service states

### Partially Automated
Evidence collected automatically, but requires human analysis or policy context.
- Least privilege assessment (requires business context)
- Network monitoring (requires baseline)
- Security event analysis (requires pattern identification)

### Manual Only
Controls that cannot be assessed via endpoint telemetry.
- Security awareness training
- Personnel screening
- Physical access controls
- Organizational policies

## Control Family Coverage

| Family | Code | Total Controls | Automated | Partial | Manual |
|--------|------|----------------|-----------|---------|--------|
| Access Control | AC (3.1) | 22 | TBD | TBD | TBD |
| Awareness & Training | AT (3.2) | 3 | 0 | 0 | 3 |
| Audit & Accountability | AU (3.3) | 9 | TBD | TBD | TBD |
| Config Management | CM (3.4) | 9 | TBD | TBD | TBD |
| Identification & Auth | IA (3.5) | 11 | TBD | TBD | TBD |
| Incident Response | IR (3.6) | 3 | TBD | TBD | TBD |
| Maintenance | MA (3.7) | 6 | TBD | TBD | TBD |
| Media Protection | MP (3.8) | 9 | TBD | TBD | TBD |
| Personnel Security | PS (3.9) | 3 | 0 | 0 | 3 |
| Physical Protection | PE (3.10) | 6 | TBD | TBD | TBD |
| Risk Assessment | RA (3.11) | 4 | TBD | TBD | TBD |
| Security Assessment | CA (3.12) | 4 | TBD | TBD | TBD |
| System & Comm Protection | SC (3.13) | 16 | TBD | TBD | TBD |
| System & Info Integrity | SI (3.14) | 13 | TBD | TBD | TBD |
| **Total** | | **110** | **TBD** | **TBD** | **TBD** |

*Coverage metrics will be updated as mappings are developed*

## Usage

### For Developers

Reference this mapping when creating new queries:

1. Identify the control you want to map
2. Review the control requirements in NIST SP 800-171
3. Determine what evidence osquery can collect
4. Update the mapping file with query details
5. Create corresponding query in the appropriate pack

### For Security Teams

Use mappings to:
- Understand what controls are covered by automation
- Identify gaps requiring manual assessment
- Review assessment criteria for each control
- Access remediation guidance for findings

### For Compliance Managers

Leverage mappings to:
- Document control implementation
- Generate coverage reports
- Provide audit evidence
- Track compliance posture over time

## Validation

Before finalizing mappings:

1. **Control Accuracy**: Verify interpretation matches NIST intent
2. **Query Validity**: Test queries return expected data
3. **Assessment Logic**: Validate pass/fail criteria are sound
4. **Completeness**: Ensure all control aspects are addressed
5. **Limitations**: Document what cannot be automated

## Contributing

When adding new control mappings:

1. Follow the YAML structure above
2. Test queries on Windows systems
3. Document automation limitations
4. Include remediation steps
5. Reference authoritative sources
6. Update coverage table

## References

- [NIST SP 800-171 Rev 2](https://csrc.nist.gov/publications/detail/sp/800-171/rev-2/final)
- [osquery Schema](https://osquery.io/schema/)
- Project mapping guide: `/docs/mapping_guide.md`
