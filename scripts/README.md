# Compliance Reporting Scripts

This directory contains Python scripts for processing osquery results and generating NIST 800-171 compliance reports.

## Scripts

### generate_report.py

Main compliance reporting script that:
- Parses osquery result logs
- Compares results against control mappings
- Generates compliance assessment reports
- Outputs in multiple formats (JSON, YAML, HTML, CSV)

**Usage:**
```bash
python generate_report.py \
  --results /path/to/osqueryd.results.log \
  --mappings ../mappings/nist800171_mapping.yaml \
  --output ./compliance_report.json \
  --format json
```

**Output Formats:**
- `json` - Machine-readable compliance data
- `yaml` - Human-readable compliance data
- `html` - Executive summary dashboard
- `csv` - Spreadsheet for analysis

### validate_mappings.py

Validation script to ensure mapping consistency:
- Verifies YAML syntax
- Checks query references exist in packs
- Validates control ID format
- Reports coverage gaps

**Usage:**
```bash
python validate_mappings.py \
  --mappings ../mappings/nist800171_mapping.yaml \
  --packs ../packs/
```

### test_queries.py

Query testing utility:
- Validates osquery SQL syntax
- Tests queries against sample data
- Checks performance impact
- Generates test results

**Usage:**
```bash
python test_queries.py \
  --pack ../packs/ac_access_control.conf \
  --osquery-path "C:\Program Files\osquery\osqueryi.exe"
```

## Requirements

Create a Python virtual environment and install dependencies:

```bash
# Create virtual environment
python -m venv venv

# Activate (Windows)
.\venv\Scripts\activate

# Activate (Linux/Mac)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### requirements.txt

```
pyyaml>=6.0
jsonschema>=4.0
jinja2>=3.0
pandas>=1.5.0
click>=8.0
```

## Report Output Example

### JSON Format

```json
{
  "report_metadata": {
    "generated_at": "2025-11-18T10:30:00Z",
    "system": "SERVER01",
    "osquery_version": "5.11.0",
    "mapping_version": "1.0.0"
  },
  "summary": {
    "total_controls": 110,
    "controls_assessed": 45,
    "controls_passed": 38,
    "controls_failed": 7,
    "controls_manual": 65,
    "compliance_score": 84.4
  },
  "findings": [
    {
      "control_id": "3.1.1",
      "control_title": "Limit system access to authorized users",
      "status": "fail",
      "severity": "high",
      "finding": "Unauthorized local account 'testadmin' detected",
      "evidence": {
        "query": "ac_local_users",
        "result": [
          {
            "username": "testadmin",
            "uid": 1005,
            "type": "local"
          }
        ]
      },
      "remediation": [
        "Remove unauthorized account: net user testadmin /delete",
        "Review account creation audit logs"
      ]
    }
  ]
}
```

### HTML Dashboard

Generates executive summary with:
- Compliance score and trend
- Control family breakdown
- Top findings by severity
- Remediation priority matrix
- System coverage statistics

## Integration Examples

### CI/CD Pipeline

```yaml
# GitHub Actions example
name: Compliance Check
on: [push, pull_request]

jobs:
  compliance:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2

      - name: Run osquery
        run: |
          osqueryi --config_path=osquery.conf --pack=packs/*.conf --json

      - name: Generate Report
        run: |
          python scripts/generate_report.py \
            --results osquery_results.json \
            --format json \
            --output compliance_report.json

      - name: Upload Artifact
        uses: actions/upload-artifact@v2
        with:
          name: compliance-report
          path: compliance_report.json
```

### Scheduled Assessment

```powershell
# Windows Task Scheduler script
$osqueryResults = "C:\Program Files\osquery\log\osqueryd.results.log"
$reportOutput = "C:\Reports\compliance_$(Get-Date -Format 'yyyyMMdd').json"

python C:\osquery-nist-mapper\scripts\generate_report.py `
  --results $osqueryResults `
  --output $reportOutput `
  --format json

# Email report
Send-MailMessage `
  -To "security@company.com" `
  -Subject "Daily NIST 800-171 Compliance Report" `
  -Body "See attached compliance report" `
  -Attachments $reportOutput
```

### SIEM Integration

```python
# Example: Push to Splunk
import requests
import json

with open('compliance_report.json') as f:
    report = json.load(f)

splunk_hec = "https://splunk:8088/services/collector"
splunk_token = "YOUR-HEC-TOKEN"

for finding in report['findings']:
    event = {
        "sourcetype": "nist800171:compliance",
        "event": finding
    }

    requests.post(
        splunk_hec,
        headers={"Authorization": f"Splunk {splunk_token}"},
        json=event,
        verify=False
    )
```

## Development

### Adding New Scripts

When creating new scripts:

1. Follow Python best practices (PEP 8)
2. Include docstrings and type hints
3. Add command-line argument parsing (use `click` or `argparse`)
4. Handle errors gracefully
5. Log operations for debugging
6. Update this README with usage examples

### Testing Scripts

```bash
# Run tests
pytest tests/

# With coverage
pytest --cov=scripts tests/

# Specific test
pytest tests/test_generate_report.py
```

## Troubleshooting

### osquery Log Parsing Errors

```bash
# Validate log format
head -n 10 /path/to/osqueryd.results.log

# Should be JSON lines format
{"name":"query_name","hostIdentifier":"hostname",...}
```

### Missing Dependencies

```bash
# Reinstall requirements
pip install -r requirements.txt --force-reinstall
```

### Mapping Validation Failures

```bash
# Validate YAML syntax
python -c "import yaml; yaml.safe_load(open('../mappings/nist800171_mapping.yaml'))"

# Run validation script
python validate_mappings.py --mappings ../mappings/nist800171_mapping.yaml
```

## References

- Python argparse: https://docs.python.org/3/library/argparse.html
- YAML in Python: https://pyyaml.org/
- Jinja2 Templates: https://jinja.palletsprojects.com/
- pandas Documentation: https://pandas.pydata.org/docs/

## Future Enhancements

- [ ] Real-time compliance monitoring dashboard
- [ ] Trend analysis and historical comparison
- [ ] Risk scoring based on control criticality
- [ ] Integration with ticketing systems (Jira, ServiceNow)
- [ ] Custom report templates
- [ ] Multi-system aggregation
