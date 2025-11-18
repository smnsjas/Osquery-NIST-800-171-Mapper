# Documentation

This directory contains documentation for the Osquery-NIST-800-171 Mapper project.

## Available Documentation

### [mapping_guide.md](mapping_guide.md)
Comprehensive guide explaining how osquery queries map to NIST SP 800-171 controls, including:
- Mapping methodology and automation levels
- Control family breakdowns
- Query development guidelines
- Example mappings and workflows
- Assessment logic and limitations

### [osquery_install_windows.md](osquery_install_windows.md)
Step-by-step installation and configuration guide for osquery on Windows systems:
- Installation methods (MSI, Chocolatey, enterprise deployment)
- Configuration for NIST 800-171 compliance monitoring
- Log management and SIEM integration
- Troubleshooting and security considerations
- Mass deployment via GPO and PowerShell DSC

## Quick Start

1. **Understand the Mapping**: Read [mapping_guide.md](mapping_guide.md) to learn how controls are assessed
2. **Install osquery**: Follow [osquery_install_windows.md](osquery_install_windows.md) to deploy on Windows
3. **Deploy Packs**: Copy query packs from `/packs` to target systems
4. **Run Reports**: Use `/scripts/generate_report.py` to assess compliance
5. **Review Findings**: Analyze results and remediate gaps

## Additional Resources

- [NIST SP 800-171 Rev 2 Official Publication](https://csrc.nist.gov/publications/detail/sp/800-171/rev-2/final)
- [osquery Documentation](https://osquery.readthedocs.io/)
- [osquery Schema Reference](https://osquery.io/schema/)
- [CISA NIST 800-171 Resources](https://www.cisa.gov/nist-800-171)

## Contributing to Documentation

When adding new documentation:
- Use clear, descriptive headings
- Include code examples where applicable
- Reference official sources (NIST, osquery docs)
- Test commands and configurations before documenting
- Update this README with new document descriptions
