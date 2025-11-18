# CLAUDE.md

## Development Guidelines for Osquery-NIST-800-171 Mapper

This document provides guidelines for AI assistants (Claude) and contributors working on this project.

## Core Principles

### Validation and Correctness
- Always validate that a query maps logically to a NIST control objective
- Critique missing mappings and highlight ambiguous control interpretations
- Cross-reference NIST SP 800-171 Rev 2 official documentation for control requirements
- Verify osquery table schemas against official documentation before writing queries
- Test queries for syntax validity and expected output format

### References and Standards
- Use reputable references:
  - [NIST SP 800-171 Rev 2](https://csrc.nist.gov/publications/detail/sp/800-171/rev-2/final)
  - [osquery Schema Documentation](https://osquery.io/schema/)
  - [CISA Guidance](https://www.cisa.gov/)
  - [CIS Benchmarks for Windows](https://www.cisecurity.org/cis-benchmarks/)
- Document sources for compliance interpretations
- Include rationale for technical decisions in code comments

### DRY and Reuse
- Leverage existing packs and tables before writing new ones
- Don't reinvent compliance logic—reuse and extend
- Share common query patterns across control families
- Use decorators for consistent metadata enrichment

### Documentation
- Keep repo-specific documentation in `/docs`
- Maintain clear mapping between queries and controls
- Document query purpose, expected output, and remediation guidance
- Include installation and configuration instructions for Windows environments

### Development Workflow
- Commit often using conventional commits format:
  - `feat:` for new features/queries
  - `fix:` for bug fixes
  - `docs:` for documentation updates
  - `refactor:` for code restructuring
  - `test:` for test additions
- Approach as skeptical architect → plan → implement → test
- Question assumptions about control interpretations
- Validate technical feasibility before committing to a design

### Testing and Validation
- Run integration and end-to-end tests
- Stub or mock unavailable systems during development
- Use Dockerized Windows environments for validation if available
- Test queries against real Windows systems when possible
- Validate JSON/YAML syntax for all configuration files

## Project Structure

```
osquery-nist-mapper/
├── packs/                      # osquery query packs by control family
│   ├── ac_access_control.conf
│   ├── au_audit_accountability.conf
│   └── ...
├── mappings/                   # Control-to-query mappings
│   └── nist800171_mapping.yaml
├── scripts/                    # Reporting and automation scripts
│   └── generate_report.py
├── docs/                       # Documentation
│   ├── mapping_guide.md
│   ├── osquery_install_windows.md
│   └── control_coverage.md
├── tests/                      # Test files
├── CLAUDE.md                   # This file
└── README.md                   # Project overview
```

## Control Mapping Guidelines

### NIST SP 800-171 Control Families
1. **3.1** Access Control (22 controls)
2. **3.2** Awareness and Training (3 controls)
3. **3.3** Audit and Accountability (9 controls)
4. **3.4** Configuration Management (9 controls)
5. **3.5** Identification and Authentication (11 controls)
6. **3.6** Incident Response (3 controls)
7. **3.7** Maintenance (6 controls)
8. **3.8** Media Protection (9 controls)
9. **3.9** Personnel Security (3 controls)
10. **3.10** Physical Protection (6 controls)
11. **3.11** Risk Assessment (4 controls)
12. **3.12** Security Assessment (4 controls)
13. **3.13** System and Communications Protection (16 controls)
14. **3.14** System and Information Integrity (13 controls)

### Query Development Process
1. Identify the control requirement and objective
2. Determine what evidence osquery can collect
3. Map to appropriate osquery tables
4. Write the query with clear selection criteria
5. Define pass/fail logic
6. Document limitations and manual verification needs
7. Test against representative systems

### Control Mapping Realism
Not all controls are fully automatable via osquery:
- **Fully Automated**: System configuration, user accounts, installed software, running processes
- **Partially Automated**: Evidence collection possible, but human interpretation required
- **Manual Only**: Policy, training, physical controls (document as "not applicable")

## Technical Considerations

### Windows-Specific Notes
- Target Windows Server 2016+ and Windows 10/11
- Consider PowerShell integration for extended data collection
- Be aware of permission requirements for certain queries
- Test on both domain-joined and standalone systems

### Performance
- Optimize queries for periodic execution (avoid resource-intensive operations)
- Use appropriate intervals in pack configurations
- Consider impact on endpoint performance

### Output Format
- Standardize on JSON for machine-readable output
- Include timestamps and system context
- Enable integration with SIEM, SOAR, and compliance tools

## Contribution Expectations
- PRs should include query validation evidence
- New control mappings require rationale documentation
- Breaking changes need migration documentation
- All queries must be tested on Windows systems

## Questions to Ask
When implementing new queries or mappings:
- Does this query actually validate the control requirement?
- What are the false positive/negative scenarios?
- Can this be gamed or bypassed?
- What manual steps remain after data collection?
- Is this query performant at scale?
- Does this work across Windows versions?
