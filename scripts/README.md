# NIST 800-171 Compliance Scripts

This directory contains scripts for integrating Windows security policy data into osquery and generating compliance reports.

## Current Scripts (PowerShell - Production Ready)

### Export-SecurityPolicy.ps1

**Exports Windows security policy to JSON for osquery consumption.**

Makes password and account lockout policies (stored in SAM database) available to osquery via the `file` table. This enables backend-agnostic compliance monitoring that works with Fleet, osctrl, or standalone osquery.

**What it does:**
- Runs `secedit /export` to extract SAM policies
- Parses account lockout settings (threshold, duration, window)
- Parses password policy settings (length, complexity, age, history)
- Adds NIST 800-171 compliance flags
- Outputs to `C:\ProgramData\osquery\security_policy.json`

**Usage:**
```powershell
# Run manually
.\Export-SecurityPolicy.ps1

# Run with custom output path
.\Export-SecurityPolicy.ps1 -OutputPath "C:\Custom\Path\policy.json"

# Run with verbose output
.\Export-SecurityPolicy.ps1 -Verbose
```

**Output Example:**
```json
{
  "account_lockout": {
    "lockout_threshold": 5,
    "lockout_duration": 30,
    "lockout_window": 30,
    "configured": true
  },
  "password_policy": {
    "min_password_length": 14,
    "password_complexity": 1,
    "min_password_age": 1,
    "max_password_age": 90,
    "password_history": 24,
    "reversible_encryption": 0,
    "configured": true
  },
  "compliance": {
    "nist_3_1_8_lockout_configured": true,
    "nist_3_5_7_password_length_ok": true,
    "nist_3_5_7_password_length_recommended": true,
    "nist_3_5_7_complexity_enabled": true,
    "overall_compliant": true
  },
  "metadata": {
    "timestamp": "2025-11-18T18:30:00Z",
    "hostname": "SERVER01",
    "export_method": "secedit",
    "version": "1.0"
  }
}
```

### Install-SecurityPolicyExport.ps1

**Installs Windows scheduled task to automate policy export.**

Creates a scheduled task that runs `Export-SecurityPolicy.ps1` every hour, ensuring osquery always has fresh policy data.

**Usage:**
```powershell
# Install with default settings (every 1 hour)
.\Install-SecurityPolicyExport.ps1

# Install with 2-hour interval
.\Install-SecurityPolicyExport.ps1 -IntervalHours 2

# Use custom script location
.\Install-SecurityPolicyExport.ps1 -ScriptPath "C:\Custom\Export-SecurityPolicy.ps1"
```

**Verification:**
```powershell
# Check task exists
Get-ScheduledTask -TaskName "Export Security Policy for osquery"

# Run manually
Start-ScheduledTask -TaskName "Export Security Policy for osquery"

# Check output file
Get-Content C:\ProgramData\osquery\security_policy.json | ConvertFrom-Json
```

---

## Quick Start

### Step 1: Install the Scheduled Task

```powershell
# Run as Administrator
cd scripts
.\Install-SecurityPolicyExport.ps1
```

**Expected output:**
```
Installing Security Policy Export Task
=======================================

[1/4] Creating scheduled task action...
  ✓ Action created
[2/4] Creating scheduled task trigger...
  ✓ Trigger created (every 1 hour(s))
[3/4] Configuring task principal...
  ✓ Principal configured (SYSTEM)
[4/4] Registering scheduled task...
  ✓ Task registered successfully

Installation Complete!

Current Policy Settings:
  Lockout Threshold: 5
  Min Password Length: 14
  Password Complexity: 1
  Overall Compliant: True
```

### Step 2: Query via osquery

The policy data is now available to osquery. Query packs have been updated with file-based queries.

**Test with osqueryi:**
```powershell
& "C:\Program Files\osquery\osqueryi.exe" @"
SELECT
  JSON_EXTRACT(data, '$.account_lockout.lockout_threshold') AS lockout_threshold,
  JSON_EXTRACT(data, '$.compliance.nist_3_1_8_lockout_configured') AS compliant
FROM (SELECT file.data AS data FROM file WHERE path = 'C:\ProgramData\osquery\security_policy.json');
"@
```

### Step 3: Enable in osquery Configuration

Ensure packs are loaded in `osquery.conf`:

```json
{
  "packs": {
    "nist_access_control": "C:\\Program Files\\osquery\\packs\\ac_access_control.conf",
    "nist_identification_auth": "C:\\Program Files\\osquery\\packs\\ia_identification_authentication.conf"
  }
}
```

The packs include:
- `ac_lockout_policy_file` - NIST 3.1.8 compliance check
- `ia_password_policy_file` - NIST 3.5.7 compliance check

### Step 4: View in Fleet/osctrl

Policy data flows through osquery logs to any backend:

**Fleet:**
- Queries → Run live queries on endpoints
- Policies → Create compliance policies
- Dashboards → View aggregated results

**osctrl:**
- Queries → Add to environment queries
- View results in dashboard

---

## Architecture

```
Windows Task Scheduler (hourly)
    └─> Export-SecurityPolicy.ps1
        └─> secedit /export
        └─> Parse & add compliance flags
        └─> Write JSON
            ▼
C:\ProgramData\osquery\security_policy.json
            ▼
osquery (file table)
    └─> Scheduled queries read JSON
    └─> Extract compliance data
    └─> Log to osqueryd.results.log
            ▼
Backend (Fleet / osctrl / SIEM)
    └─> Consume osquery logs
    └─> Display dashboards
    └─> Alert on violations
```

---

## Planned Scripts (Python - Future Enhancement)

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
