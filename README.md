# Osquery-NIST-800-171 Mapper

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows-blue.svg)
![osquery](https://img.shields.io/badge/osquery-5.0%2B-green.svg)

Automated compliance assessment framework that maps osquery queries to NIST SP 800-171 Rev 2 security controls for Windows servers and desktops.

## Overview

This project provides a structured, auditable, and repeatable approach to validating NIST SP 800-171 compliance on Windows endpoints using osquery. It includes:

- **Query Packs**: Pre-built osquery configurations organized by control family
- **Control Mappings**: Structured YAML mappings between queries and NIST 800-171 controls
- **Reporting Scripts**: Python tools to generate compliance reports from osquery data
- **Documentation**: Comprehensive guides for implementation and mapping methodology

## Problem Statement

- Manual compliance validation for NIST 800-171 is time-consuming and error-prone
- Windows systems lack transparent, queryable compliance mapping without expensive commercial tools
- Organizations need automated, auditable evidence collection for security controls
- Security teams require repeatable processes for gap analysis and policy validation

## Solution

Leverage osquery's endpoint visibility to automatically collect technical evidence for NIST 800-171 controls, transforming endpoint data into compliance insights.

## Features

- **110 Control Coverage**: Mapping framework for all NIST SP 800-171 Rev 2 controls
- **Windows-Focused**: Optimized for Windows Server 2016+ and Windows 10/11
- **Automation Levels**: Controls classified as fully automated, partially automated, or manual
- **Multiple Output Formats**: JSON, YAML, HTML, and CSV compliance reports
- **Open Source**: Transparent methodology, community-driven improvements
- **SIEM Integration**: Compatible with Splunk, Elastic, and other log aggregation platforms

## Quick Start

### 1. Install osquery on Windows

```powershell
# Download and install osquery
Invoke-WebRequest -Uri https://pkg.osquery.io/windows/osquery-5.11.0.msi -OutFile osquery.msi
Start-Process msiexec.exe -Wait -ArgumentList "/i osquery.msi /quiet /norestart"
```

See [osquery installation guide](docs/osquery_install_windows.md) for detailed instructions.

### 2. Clone This Repository

```bash
git clone https://github.com/your-org/osquery-nist-mapper.git
cd osquery-nist-mapper
```

### 3. Deploy Query Packs

```powershell
# Copy packs to osquery installation
Copy-Item .\packs\*.conf "C:\Program Files\osquery\packs\"

# Configure osquery to use packs (edit osquery.conf)
```

### 4. Run osquery and Collect Results

```powershell
# Start osquery service
Start-Service osqueryd

# Monitor results
Get-Content "C:\Program Files\osquery\log\osqueryd.results.log" -Wait
```

### 5. Generate Compliance Report

```bash
# Install Python dependencies
pip install -r scripts/requirements.txt

# Generate report
python scripts/generate_report.py \
  --results "C:\Program Files\osquery\log\osqueryd.results.log" \
  --output compliance_report.json \
  --format json
```

## Project Structure

```
osquery-nist-mapper/
├── packs/                      # osquery query packs by control family
│   ├── ac_access_control.conf
│   ├── au_audit_accountability.conf
│   ├── cm_configuration_management.conf
│   ├── ia_identification_authentication.conf
│   ├── sc_system_communications.conf
│   ├── si_system_integrity.conf
│   └── README.md
├── mappings/                   # Control-to-query mappings
│   ├── nist800171_mapping.yaml
│   └── README.md
├── scripts/                    # Reporting and automation
│   ├── generate_report.py
│   ├── validate_mappings.py
│   ├── test_queries.py
│   ├── requirements.txt
│   └── README.md
├── docs/                       # Documentation
│   ├── mapping_guide.md
│   ├── osquery_install_windows.md
│   └── README.md
├── CLAUDE.md                   # AI assistant guidelines
├── .gitignore
└── README.md                   # This file
```

## Key Concepts

### osquery
Open-source endpoint instrumentation tool that exposes operating system data as a relational database. Query system state using SQL.

### NIST SP 800-171
U.S. federal cybersecurity standard defining 110 security controls for protecting Controlled Unclassified Information (CUI) in non-federal systems.

### Control Mapping
Correlating technical telemetry from osquery to specific NIST control requirements, enabling automated compliance assessment.

### Automation Levels

- **Fully Automated**: Technical evidence collected and assessed without human interpretation
- **Partially Automated**: Evidence collected, but requires business context or manual analysis
- **Manual Only**: Controls that cannot be assessed via endpoint telemetry (e.g., training, physical security)

## Documentation

- **[Mapping Guide](docs/mapping_guide.md)**: Methodology for mapping queries to controls
- **[osquery Installation](docs/osquery_install_windows.md)**: Complete Windows deployment guide
- **[Packs README](packs/README.md)**: Query pack structure and usage
- **[Mappings README](mappings/README.md)**: Control mapping specifications
- **[Scripts README](scripts/README.md)**: Reporting tool documentation

## Example Output

```json
{
  "summary": {
    "total_controls": 110,
    "controls_assessed": 45,
    "controls_passed": 38,
    "controls_failed": 7,
    "compliance_score": 84.4
  },
  "findings": [
    {
      "control_id": "3.1.1",
      "status": "fail",
      "severity": "high",
      "finding": "Unauthorized local account 'testadmin' detected",
      "remediation": "Remove account: net user testadmin /delete"
    }
  ]
}
```

## Use Cases

### Security Engineers
- Automatically map osquery data to NIST 800-171 controls
- Identify compliance gaps across Windows estate
- Generate evidence for security assessments
- Validate security baseline configurations

### Compliance Managers
- Produce machine-readable audit evidence
- Track compliance posture over time
- Demonstrate control coverage to auditors
- Document control implementation

### System Administrators
- Deploy pre-built compliance query packs
- Integrate with existing osquery infrastructure
- Monitor configuration drift
- Validate security hardening

## Contributing

Contributions are welcome! Please:

1. Review [CLAUDE.md](CLAUDE.md) for development guidelines
2. Test queries on Windows systems before submitting
3. Document rationale and limitations
4. Follow conventional commit format
5. Submit PRs with validation evidence

## Limitations

- **Endpoint Scope**: osquery provides endpoint-level visibility; network and cloud controls require different approaches
- **Business Context**: Some controls require organizational policies or baselines not available to osquery
- **Windows Only**: Current focus is Windows; Linux/macOS mappings are future enhancements
- **Point-in-Time**: osquery provides snapshots; continuous monitoring requires scheduled execution
- **Interpretation Required**: Automated checks provide evidence, but human judgment is needed for final compliance determination

## Roadmap

- [ ] Complete control mappings for all 14 NIST 800-171 families
- [ ] Develop baseline query packs for common control families
- [ ] Build reporting dashboard with trend analysis
- [ ] Add integration templates for popular SIEM platforms
- [ ] Create Docker-based test environment
- [ ] Expand to Linux and macOS systems
- [ ] Add CIS Benchmark mappings

## References

- [NIST SP 800-171 Rev 2](https://csrc.nist.gov/publications/detail/sp/800-171/rev-2/final)
- [osquery Documentation](https://osquery.readthedocs.io/)
- [osquery Schema Reference](https://osquery.io/schema/)
- [CISA NIST 800-171 Resources](https://www.cisa.gov/nist-800-171)

## License

MIT License - see LICENSE file for details

## Contact

For questions, issues, or contributions, please open an issue on GitHub.

---

**Disclaimer**: This tool provides automated evidence collection to support NIST 800-171 compliance efforts. It does not guarantee compliance and should be used as part of a comprehensive security program. Always consult with qualified security professionals and auditors for compliance validation.
