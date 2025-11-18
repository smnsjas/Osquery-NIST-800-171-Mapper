# NIST 800-171 Compliance PowerShell Module

**Windows-native compliance checking for NIST SP 800-171 Rev 2**

This PowerShell module provides quick, dependency-free compliance assessment for Windows systems. It combines osquery results with native Windows security policy checks (secedit) to evaluate NIST SP 800-171 Rev 2 compliance.

> **🚀 First Time Setup?** See [QUICKSTART.md](../QUICKSTART.md) for complete osquery installation and configuration in 15 minutes.
>
> **⚠️ Seeing "Inconclusive" Results?** This means osquery isn't configured yet. The module IS working - follow the [Quick Start Guide](../QUICKSTART.md).

## Features

- ✅ **Windows Native** - No dependencies, runs on any Windows system with PowerShell 5.1+
- ✅ **secedit Integration** - Parses password and account lockout policies from SAM
- ✅ **osquery Results** - Analyzes osquery output for comprehensive checks
- ✅ **Multiple Report Formats** - JSON, HTML, CSV, and colorful console output
- ✅ **Elevated Privileges** - Handles UAC requirements automatically
- ✅ **Fast Assessment** - Quick checks for sysadmins and security teams

## Requirements

- **Windows**: Server 2016+, Windows 10/11
- **PowerShell**: 5.1 or later (PowerShell 7+ supported)
- **Privileges**: Administrator (for secedit and full osquery results)
- **Optional**: osquery installed (for endpoint telemetry checks)

## Quick Start

### 1. Install the Module

```powershell
# Option A: Copy to PowerShell modules directory
Copy-Item -Path ".\NIST800171Compliance" -Destination "$env:ProgramFiles\WindowsPowerShell\Modules\" -Recurse

# Option B: Import directly from repository
Import-Module ".\NIST800171Compliance" -Force
```

### 2. Run Basic Compliance Check

```powershell
# Quick assessment with console output
Get-NISTCompliance | Export-NISTReport -Format Console
```

### 3. Generate HTML Report

```powershell
# Full compliance report
$compliance = Get-NISTCompliance
Export-NISTReport -ComplianceData $compliance -OutputPath ".\report.html" -Format HTML
```

## Commands

### Get-NISTCompliance

Performs comprehensive NIST SP 800-171 Rev 2 compliance assessment.

**Parameters:**
- `-OsqueryResultsPath` - Path to osquery results log (optional)
- `-MappingsPath` - Path to YAML mappings file (defaults to ../mappings/)
- `-ControlFamily` - Filter specific family: "3.1", "3.14", etc.
- `-IncludeEvidence` - Include raw evidence in results

**Examples:**

```powershell
# Full assessment
Get-NISTCompliance

# Check specific family
Get-NISTCompliance -ControlFamily "3.1"

# With evidence
Get-NISTCompliance -IncludeEvidence

# Custom osquery results
Get-NISTCompliance -OsqueryResultsPath "C:\logs\osquery.json"
```

### Get-WindowsSecurityPolicy

Retrieves Windows local security policy using secedit.

**Examples:**

```powershell
# Get all policies
$policy = Get-WindowsSecurityPolicy

# View password policies
$policy.PasswordPolicies

# View lockout policies
$policy.AccountLockoutPolicies

# Check minimum password length
$policy.PasswordPolicies.MinimumPasswordLength
```

### Export-NISTReport

Exports compliance reports in various formats.

**Parameters:**
- `-ComplianceData` - Results from Get-NISTCompliance (pipeline supported)
- `-OutputPath` - File path for report (optional, auto-generated if not specified)
- `-Format` - Report format: JSON, HTML, CSV, or Console

**Examples:**

```powershell
# Console output (colorful, interactive)
Get-NISTCompliance | Export-NISTReport -Format Console

# HTML report with dashboard
Get-NISTCompliance | Export-NISTReport -OutputPath ".\report.html" -Format HTML

# JSON for API integration
Get-NISTCompliance | Export-NISTReport -OutputPath ".\data.json" -Format JSON

# CSV for Excel analysis
Get-NISTCompliance | Export-NISTReport -OutputPath ".\controls.csv" -Format CSV
```

## Usage Scenarios

### Scenario 1: Quick Security Check

```powershell
# Run before system deployment or after security updates
Import-Module NIST800171Compliance
Get-NISTCompliance | Export-NISTReport -Format Console
```

### Scenario 2: Detailed Audit Report

```powershell
# Generate comprehensive HTML report for auditors
$compliance = Get-NISTCompliance -IncludeEvidence
Export-NISTReport -ComplianceData $compliance -OutputPath ".\NIST_Audit_$(Get-Date -Format 'yyyyMMdd').html" -Format HTML

# Also export raw data
Export-NISTReport -ComplianceData $compliance -OutputPath ".\NIST_Data_$(Get-Date -Format 'yyyyMMdd').json" -Format JSON
```

### Scenario 3: Scheduled Assessment

```powershell
# Run via Windows Task Scheduler (daily at 2 AM)
$compliance = Get-NISTCompliance
$reportPath = "C:\ComplianceReports\NIST_$(Get-Date -Format 'yyyyMMdd').html"
Export-NISTReport -ComplianceData $compliance -OutputPath $reportPath -Format HTML

# Email report to security team
Send-MailMessage -To "security@company.com" `
    -Subject "Daily NIST 800-171 Compliance Report - $env:COMPUTERNAME" `
    -Body "See attached compliance report." `
    -Attachments $reportPath `
    -SmtpServer "smtp.company.com"
```

### Scenario 4: Integration with osquery

```powershell
# Ensure osquery is running
if ((Get-Service osqueryd).Status -ne 'Running') {
    Start-Service osqueryd
    Start-Sleep -Seconds 30  # Wait for initial queries
}

# Run compliance check with osquery results
$compliance = Get-NISTCompliance -OsqueryResultsPath "C:\Program Files\osquery\log\osqueryd.results.log"
Export-NISTReport -ComplianceData $compliance -Format Console
```

### Scenario 5: CI/CD Pipeline Integration

```powershell
# Example: Azure DevOps pipeline task
$compliance = Get-NISTCompliance
$score = $compliance.Summary.ComplianceScore

if ($score -lt 80) {
    Write-Error "Compliance score below threshold: $score% (require >= 80%)"
    exit 1
}

Write-Host "Compliance check passed: $score%" -ForegroundColor Green
Export-NISTReport -ComplianceData $compliance -OutputPath "$(Build.ArtifactStagingDirectory)\compliance.html" -Format HTML
```

## Report Output Examples

### Console Output

```
========================================
  NIST SP 800-171 Rev 2 Compliance Report
========================================

Assessment Date: 2025-11-18 15:30:00
Hostname: SERVER01

Summary:
  Total Controls:    10
  Passed:            6
  Failed:            2
  Inconclusive:      2
  Not Assessed:      0
  Compliance Score:  75.0%

Control Details:

[Pass         ] 3.1.1 - Limit system access to authorized users
    • Query 'ac_local_users' returned 8 result(s)
    • Manual review required - compare results against organizational baselines

[Fail         ] 3.1.8 - Limit unsuccessful logon attempts
    • Account lockout is not configured (LockoutBadCount = 0 or not set)
    → Configure account lockout: Set-LocalSecurityPolicy -LockoutBadCount 5
```

### HTML Report

Beautiful, executive-ready dashboard with:
- Summary cards with compliance score
- Color-coded status badges
- Detailed findings table
- Remediation recommendations
- Metadata footer

### JSON Output

```json
{
  "Summary": {
    "AssessmentDate": "2025-11-18 15:30:00",
    "Hostname": "SERVER01",
    "TotalControls": 10,
    "Passed": 6,
    "Failed": 2,
    "ComplianceScore": 75.0
  },
  "Controls": [
    {
      "ControlId": "3.1.8",
      "Status": "Fail",
      "Findings": ["Account lockout is not configured"],
      "Recommendations": ["Configure account lockout policy"]
    }
  ]
}
```

## Troubleshooting

### "This function requires elevated privileges"

**Solution**: Run PowerShell as Administrator

```powershell
# Check if running as admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# If False, restart PowerShell as Administrator
Start-Process powershell -Verb RunAs
```

### "PowerShell-Yaml module not found"

This is a warning, not an error. The module will use basic YAML parsing.

**Solution** (optional): Install PowerShell-Yaml for enhanced features

```powershell
Install-Module -Name powershell-yaml -Scope CurrentUser
```

### "osquery results not found"

The module will still perform policy-based checks without osquery.

**Solution**: Install osquery or specify custom results path

```powershell
# Check if osquery is installed
Test-Path "C:\Program Files\osquery\osqueryd.exe"

# Specify custom path
Get-NISTCompliance -OsqueryResultsPath "C:\CustomPath\osquery_results.log"
```

### secedit fails on Windows Server Core

**Solution**: Use alternative method for Server Core

```powershell
# Fallback: Use net accounts
net accounts

# Or: Remote to full Windows Server and run there
Invoke-Command -ComputerName ServerCore01 -ScriptBlock {
    Get-NISTCompliance
}
```

## Technical Details

### Security Policy Parsing

The module uses `secedit.exe /export` to extract SAM-based policies:
- Password complexity requirements
- Minimum password length
- Account lockout threshold
- Lockout duration settings

These settings are NOT accessible via simple registry queries because they're stored in binary format in the SAM database.

### osquery Integration

The module parses osquery JSON lines format:
- Reads `osqueryd.results.log`
- Indexes results by query name
- Matches against control mappings

### Control Assessment Logic

Each control is assessed using:
1. **Fully Automated** - Pass/Fail determined programmatically
2. **Partially Automated** - Evidence collected, manual review flagged
3. **Manual Only** - Noted as "Not Assessed"

Current automated assessments:
- **3.1.8** - Account lockout policy (secedit)
- **3.5.7** - Password complexity policy (secedit)
- **osquery-based** - Marked as Inconclusive pending baseline comparison

## Performance

- **Fast Execution**: ~5-10 seconds for full assessment
- **Low Overhead**: Uses native Windows tools
- **No Network**: All checks are local
- **Lightweight**: No external dependencies

## Limitations

- **SAM Policies Only**: Password and lockout policies fully automated
- **osquery Evidence**: Results marked as Inconclusive (requires baseline)
- **Local Scope**: Does not assess domain-level policies
- **Windows Only**: Not compatible with Linux/macOS

## Roadmap

- [ ] Add baseline configuration file support
- [ ] Implement custom pass/fail criteria per control
- [ ] Add support for domain policy checks (Get-ADDefaultDomainPasswordPolicy)
- [ ] Create scheduled task automation script
- [ ] Add email notification template
- [ ] Build graphical dashboard (WPF/WinForms)

## Contributing

Contributions welcome! Please:
1. Test on Windows Server and Desktop versions
2. Document any new functions
3. Follow PowerShell best practices (approved verbs, help documentation)
4. Submit PRs with examples

## License

MIT License - See main repository LICENSE file

## Support

For issues or questions:
- GitHub Issues: https://github.com/your-org/osquery-nist-mapper/issues
- Documentation: See ../docs/ directory

## Related Projects

- Main Repository: NIST 800-171 osquery Mapper
- Control Mappings: ../mappings/nist800171_mapping.yaml
- osquery Packs: ../packs/
- Documentation: ../docs/

---

**Made with ❤️ for the Windows security community**
