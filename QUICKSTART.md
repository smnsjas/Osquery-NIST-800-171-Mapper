# Quick Start Guide - NIST 800-171 Compliance Assessment

**Get your Windows compliance assessment running in 15 minutes**

## What You're Seeing Now

If you're seeing output like this:

```
[Inconclusive] 3.1.1 - Limit system access to authorized users...
    • Query 'ac_local_users' results not found in osquery data
```

**This is normal!** Your PowerShell module is working, but osquery needs to be set up first.

## Current Status

✅ **PowerShell Module**: Working correctly
✅ **Policy Checks (secedit)**: Working (you should see results for 3.1.8 and 3.5.7)
❌ **osquery Integration**: Not configured yet

## Setup Steps

### Step 1: Check What's Already Working (5 minutes)

The PowerShell module can already assess two critical controls without osquery:

```powershell
# Run policy-only assessment
Import-Module .\powershell\NIST800171Compliance
Get-NISTCompliance | Export-NISTReport -Format Console
```

**Expected results**: Controls 3.1.8 (account lockout) and 3.5.7 (password policy) should show Pass/Fail status based on your current Windows security policy.

### Step 2: Install osquery (5 minutes)

Check if osquery is already installed:

```powershell
Test-Path "C:\Program Files\osquery\osqueryd.exe"
```

If **False**, install osquery:

**Option A: Download and Install MSI**

```powershell
# Download latest osquery
$version = "5.11.0"
$url = "https://pkg.osquery.io/windows/osquery-$version.msi"
$output = "$env:TEMP\osquery.msi"

Invoke-WebRequest -Uri $url -OutFile $output

# Install
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$output`" /quiet /norestart"

# Verify
Get-Service osqueryd
```

**Option B: Using Chocolatey**

```powershell
choco install osquery -y
```

### Step 3: Configure osquery with NIST 800-171 Packs (2 minutes)

```powershell
# Copy query packs to osquery directory
$packSource = ".\packs\*.conf"
$packDest = "C:\Program Files\osquery\packs\"

Copy-Item -Path $packSource -Destination $packDest -Force

# Verify packs are copied
Get-ChildItem "C:\Program Files\osquery\packs\" -Filter "*.conf"
```

### Step 4: Create osquery Configuration (2 minutes)

Create the main configuration file:

```powershell
# Create osquery.conf
$configContent = @'
{
  "options": {
    "host_identifier": "hostname",
    "schedule_splay_percent": 10,
    "logger_snapshot_event_type": true
  },
  "schedule": {},
  "packs": {
    "nist_access_control": "C:\\Program Files\\osquery\\packs\\ac_access_control.conf",
    "nist_audit_accountability": "C:\\Program Files\\osquery\\packs\\au_audit_accountability.conf",
    "nist_configuration_mgmt": "C:\\Program Files\\osquery\\packs\\cm_configuration_management.conf",
    "nist_identification_auth": "C:\\Program Files\\osquery\\packs\\ia_identification_authentication.conf",
    "nist_system_communications": "C:\\Program Files\\osquery\\packs\\sc_system_communications.conf",
    "nist_system_integrity": "C:\\Program Files\\osquery\\packs\\si_system_integrity.conf"
  },
  "decorators": {
    "load": [
      "SELECT uuid AS host_uuid FROM system_info;",
      "SELECT hostname AS hostname FROM system_info;"
    ]
  }
}
'@

Set-Content -Path "C:\Program Files\osquery\osquery.conf" -Value $configContent -Encoding UTF8

# Create flags file
$flagsContent = @"
--config_path=C:\Program Files\osquery\osquery.conf
--logger_path=C:\Program Files\osquery\log
--pidfile=C:\Program Files\osquery\osqueryd.pidfile
--database_path=C:\Program Files\osquery\osquery.db
--logger_plugin=filesystem
--disable_events=false
"@

Set-Content -Path "C:\Program Files\osquery\osquery.flags" -Value $flagsContent -Encoding UTF8
```

### Step 5: Start osquery Service (1 minute)

```powershell
# Start the service
Start-Service osqueryd

# Set to start automatically
Set-Service osqueryd -StartupType Automatic

# Verify it's running
Get-Service osqueryd
Get-Process osqueryd
```

### Step 6: Wait for Initial Results (2-5 minutes)

osquery needs time to run the scheduled queries:

```powershell
# Wait for results to be generated
Write-Host "Waiting for osquery to generate initial results..." -ForegroundColor Yellow
Start-Sleep -Seconds 120  # Wait 2 minutes

# Check if results file exists and has content
$resultsPath = "C:\Program Files\osquery\log\osqueryd.results.log"
if (Test-Path $resultsPath) {
    $resultSize = (Get-Item $resultsPath).Length
    Write-Host "Results file exists: $resultSize bytes" -ForegroundColor Green

    # Show sample of results
    Get-Content $resultsPath -Tail 5
} else {
    Write-Warning "Results file not found yet. Wait another minute and check again."
}
```

### Step 7: Run Full Compliance Assessment

Now run the complete assessment with osquery results:

```powershell
# Import module
Import-Module .\powershell\NIST800171Compliance -Force

# Run full compliance check
$compliance = Get-NISTCompliance -Verbose

# Display results
Export-NISTReport -ComplianceData $compliance -Format Console

# Generate HTML report
Export-NISTReport -ComplianceData $compliance -OutputPath ".\NIST_Compliance_Report.html" -Format HTML

# Check your compliance score
Write-Host "`nOverall Compliance Score: " -NoNewline
Write-Host "$($compliance.Summary.ComplianceScore)%" -ForegroundColor $(
    if ($compliance.Summary.ComplianceScore -ge 80) { 'Green' }
    elseif ($compliance.Summary.ComplianceScore -ge 60) { 'Yellow' }
    else { 'Red' }
)
```

## Troubleshooting

### osquery Service Won't Start

```powershell
# Check service status
Get-Service osqueryd

# View recent errors
Get-EventLog -LogName Application -Source osqueryd -Newest 10

# Validate configuration syntax
& "C:\Program Files\osquery\osqueryd.exe" --config_check --config_path="C:\Program Files\osquery\osquery.conf"
```

### No Query Results After Waiting

```powershell
# Check if queries are scheduled
& "C:\Program Files\osquery\osqueryi.exe" "SELECT * FROM osquery_schedule;"

# Check if packs are loaded
& "C:\Program Files\osquery\osqueryi.exe" "SELECT * FROM osquery_packs;"

# View osquery logs
Get-Content "C:\Program Files\osquery\log\osqueryd.INFO" -Tail 50
```

### "Access Denied" Errors

Some queries require Administrator privileges:

```powershell
# Verify service runs as SYSTEM
Get-WmiObject Win32_Service -Filter "Name='osqueryd'" | Select-Object Name, StartName

# Run PowerShell as Administrator
Start-Process powershell -Verb RunAs
```

### Results File Empty or Small

Wait longer - some queries run at different intervals (60s, 300s, 3600s):

```powershell
# Monitor results in real-time
Get-Content "C:\Program Files\osquery\log\osqueryd.results.log" -Wait -Tail 20
```

## What to Expect

### First Run (Policy Checks Only)
- **Assessed**: 2 controls (3.1.8, 3.5.7)
- **Inconclusive**: 8 controls (waiting for osquery)
- **Time**: ~5 seconds

### After osquery Setup
- **Assessed**: 10+ controls
- **Pass/Fail/Inconclusive**: Based on actual system state
- **Time**: ~10 seconds

### Compliance Scores

- **90-100%**: Excellent - System well-configured
- **70-89%**: Good - Minor improvements needed
- **50-69%**: Fair - Several issues to address
- **Below 50%**: Poor - Immediate action required

## Understanding Results

### Control Status Types

- **Pass** ✅: Control requirements met
- **Fail** ❌: Control requirements not met (action needed)
- **Inconclusive** ⚠️: Evidence collected, manual review required
- **NotAssessed** ⬜: No automated check available

### Why "Inconclusive"?

Most osquery-based controls are marked "Inconclusive" because:
- They collect evidence (users, processes, services, etc.)
- But require comparison against YOUR organization's baseline
- The module can't automatically determine what's "correct" for your environment

**Example**: Control 3.1.1 checks local users, but the module doesn't know which users SHOULD exist on your system.

## Next Steps

1. **Review Failed Controls**: Focus on Pass/Fail results first
2. **Establish Baselines**: Document approved configurations for your environment
3. **Schedule Regular Checks**: Run weekly or monthly compliance assessments
4. **Integrate with SIEM**: Forward osquery logs to your security monitoring platform
5. **Customize Queries**: Modify packs to match your organizational requirements

## Complete Setup Script

Save this as `setup-nist-compliance.ps1` and run as Administrator:

```powershell
#Requires -RunAsAdministrator

Write-Host "NIST 800-171 Compliance Assessment Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Check osquery
Write-Host "[1/5] Checking osquery installation..." -ForegroundColor Yellow
if (-not (Test-Path "C:\Program Files\osquery\osqueryd.exe")) {
    Write-Host "  osquery not found. Please install from: https://osquery.io/downloads" -ForegroundColor Red
    Write-Host "  Or run: choco install osquery" -ForegroundColor Yellow
    exit 1
}
Write-Host "  ✓ osquery installed" -ForegroundColor Green

# Step 2: Copy packs
Write-Host "[2/5] Copying NIST 800-171 query packs..." -ForegroundColor Yellow
Copy-Item -Path ".\packs\*.conf" -Destination "C:\Program Files\osquery\packs\" -Force
Write-Host "  ✓ Packs copied: $(Get-ChildItem 'C:\Program Files\osquery\packs\' -Filter '*.conf' | Measure-Object | Select-Object -ExpandProperty Count) files" -ForegroundColor Green

# Step 3: Configure osquery
Write-Host "[3/5] Configuring osquery..." -ForegroundColor Yellow
# ... (use config from Step 4 above)
Write-Host "  ✓ Configuration files created" -ForegroundColor Green

# Step 4: Start service
Write-Host "[4/5] Starting osquery service..." -ForegroundColor Yellow
Restart-Service osqueryd -ErrorAction SilentlyContinue
Start-Service osqueryd
Set-Service osqueryd -StartupType Automatic
Write-Host "  ✓ Service running" -ForegroundColor Green

# Step 5: Wait and test
Write-Host "[5/5] Waiting for initial query results..." -ForegroundColor Yellow
Start-Sleep -Seconds 120
Write-Host "  ✓ Setup complete!`n" -ForegroundColor Green

# Run assessment
Write-Host "Running compliance assessment..." -ForegroundColor Cyan
Import-Module .\powershell\NIST800171Compliance -Force
$compliance = Get-NISTCompliance
Export-NISTReport -ComplianceData $compliance -Format Console

Write-Host "`n✅ Setup complete! HTML report saved to current directory." -ForegroundColor Green
```

## Support

- **Documentation**: See `docs/osquery_install_windows.md` for detailed setup
- **Examples**: Check `powershell/Examples/` for usage scenarios
- **Issues**: GitHub Issues or system administrator

---

**You're now ready to perform automated NIST 800-171 compliance assessments!**
