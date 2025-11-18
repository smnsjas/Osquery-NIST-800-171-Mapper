# Installing and Configuring osquery on Windows

## Overview

This guide covers installing osquery on Windows Server and Desktop systems, configuring it for NIST 800-171 compliance monitoring, and deploying the compliance query packs.

## Prerequisites

- Windows Server 2016+ or Windows 10/11
- Administrator privileges
- Network access for package downloads (or offline installer)
- PowerShell 5.1 or later

## Installation Methods

### Method 1: MSI Installer (Recommended)

**Step 1: Download osquery**

Download the latest stable MSI from [osquery downloads](https://osquery.io/downloads):

```powershell
# Using PowerShell to download (example for osquery 5.x)
$osqueryVersion = "5.11.0"
$downloadUrl = "https://pkg.osquery.io/windows/osquery-$osqueryVersion.msi"
$outputPath = "$env:TEMP\osquery-installer.msi"

Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath
```

**Step 2: Install osquery**

```powershell
# Install with default options
Start-Process msiexec.exe -Wait -ArgumentList "/i $outputPath /quiet /norestart"

# Verify installation
Get-Service osqueryd
```

Default installation path: `C:\Program Files\osquery\`

**Step 3: Verify Installation**

```powershell
# Check osquery version
& "C:\Program Files\osquery\osqueryi.exe" --version

# Test interactive query
& "C:\Program Files\osquery\osqueryi.exe" "SELECT * FROM system_info;"
```

### Method 2: Chocolatey

If using Chocolatey package manager:

```powershell
choco install osquery
```

### Method 3: Manual Deployment (Enterprise)

For mass deployment via GPO, SCCM, or other tools:

1. Extract MSI to shared location
2. Deploy via software distribution tool
3. Configure using Group Policy Preferences or configuration management

## Configuration

### Directory Structure

osquery configuration files on Windows:

```
C:\Program Files\osquery\
├── osqueryd\                   # Service configuration
│   ├── osquery.flags           # Runtime flags
│   └── osquery.conf            # Main configuration (if used)
├── packs\                      # Query packs directory
├── osqueryd.exe                # Service executable
├── osqueryi.exe                # Interactive shell
└── log\                        # Log output directory
```

### Basic Configuration

Create `C:\Program Files\osquery\osquery.flags`:

```
--config_path=C:\Program Files\osquery\osquery.conf
--logger_path=C:\Program Files\osquery\log
--pidfile=C:\Program Files\osquery\osqueryd.pidfile
--database_path=C:\Program Files\osquery\osquery.db
--verbose=false
--logger_plugin=filesystem
--disable_events=false
--disable_audit=false
```

Create `C:\Program Files\osquery\osquery.conf`:

```json
{
  "options": {
    "host_identifier": "hostname",
    "schedule_splay_percent": 10,
    "logger_snapshot_event_type": true
  },
  "schedule": {},
  "packs": {},
  "decorators": {
    "load": [
      "SELECT uuid AS host_uuid FROM system_info;",
      "SELECT user AS username FROM logged_in_users ORDER BY time DESC LIMIT 1;"
    ]
  }
}
```

### NIST 800-171 Compliance Configuration

**Step 1: Clone This Repository**

```powershell
# On the management workstation
git clone https://github.com/your-org/osquery-nist-mapper.git
cd osquery-nist-mapper
```

**Step 2: Deploy Packs to Windows Systems**

Copy the compliance packs to target systems:

```powershell
# Example: Copy packs to remote system
$targetSystem = "SERVER01"
$packSource = ".\packs\*"
$packDest = "\\$targetSystem\C$\Program Files\osquery\packs\"

Copy-Item -Path $packSource -Destination $packDest -Force
```

**Step 3: Update osquery.conf to Include Packs**

Modify `C:\Program Files\osquery\osquery.conf`:

```json
{
  "options": {
    "host_identifier": "hostname",
    "schedule_splay_percent": 10,
    "logger_snapshot_event_type": true,
    "logger_mode": "0640",
    "schedule_timeout": 300
  },
  "schedule": {},
  "packs": {
    "nist_access_control": "C:\\Program Files\\osquery\\packs\\ac_access_control.conf",
    "nist_audit_accountability": "C:\\Program Files\\osquery\\packs\\au_audit_accountability.conf",
    "nist_configuration_mgmt": "C:\\Program Files\\osquery\\packs\\cm_configuration_management.conf",
    "nist_identification_auth": "C:\\Program Files\\osquery\\packs\\ia_identification_authentication.conf",
    "nist_system_integrity": "C:\\Program Files\\osquery\\packs\\si_system_integrity.conf"
  },
  "decorators": {
    "load": [
      "SELECT uuid AS host_uuid FROM system_info;",
      "SELECT hostname AS hostname FROM system_info;",
      "SELECT cpu_brand AS cpu_type FROM system_info;",
      "SELECT physical_memory AS total_memory FROM system_info;"
    ]
  }
}
```

**Step 4: Start the osquery Service**

```powershell
# Start the service
Start-Service osqueryd

# Set to start automatically
Set-Service osqueryd -StartupType Automatic

# Verify running
Get-Service osqueryd
Get-Process osqueryd
```

## Verification and Testing

### Test Interactive Queries

```powershell
# Launch osqueryi
& "C:\Program Files\osquery\osqueryi.exe"
```

In osqueryi shell:

```sql
-- Test basic functionality
SELECT * FROM system_info;

-- Test compliance query
SELECT username, uid, type FROM users WHERE uid >= 1000;

-- Check loaded packs
SELECT * FROM osquery_packs;

-- View scheduled queries
SELECT * FROM osquery_schedule;
```

### Check Log Output

```powershell
# View recent results
Get-Content "C:\Program Files\osquery\log\osqueryd.results.log" -Tail 50

# Monitor in real-time
Get-Content "C:\Program Files\osquery\log\osqueryd.results.log" -Wait -Tail 20
```

## Log Management

### Log Rotation

osquery doesn't include native log rotation. Configure using Windows Task Scheduler or external tools:

**PowerShell Log Rotation Script** (`C:\Scripts\rotate-osquery-logs.ps1`):

```powershell
$logPath = "C:\Program Files\osquery\log"
$maxSize = 100MB
$archivePath = "$logPath\archive"

# Create archive directory
if (-not (Test-Path $archivePath)) {
    New-Item -ItemType Directory -Path $archivePath
}

# Rotate if exceeds size
Get-ChildItem $logPath -Filter "*.log" | ForEach-Object {
    if ($_.Length -gt $maxSize) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $archiveName = "$($_.BaseName)-$timestamp.log"
        Move-Item $_.FullName "$archivePath\$archiveName"

        # Restart osquery to create new log
        Restart-Service osqueryd
    }
}

# Clean old archives (older than 90 days)
Get-ChildItem $archivePath -Filter "*.log" |
    Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-90)} |
    Remove-Item
```

**Schedule via Task Scheduler:**

```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File C:\Scripts\rotate-osquery-logs.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At 2am

Register-ScheduledTask -TaskName "osquery Log Rotation" `
    -Action $action -Trigger $trigger -User "SYSTEM" -RunLevel Highest
```

### Forwarding to SIEM

**Example: Forward to Splunk**

Configure Splunk Universal Forwarder to monitor osquery logs:

```ini
# inputs.conf
[monitor://C:\Program Files\osquery\log\osqueryd.results.log]
disabled = false
index = osquery
sourcetype = osquery:results

[monitor://C:\Program Files\osquery\log\osqueryd.INFO]
disabled = false
index = osquery
sourcetype = osquery:info
```

**Example: Forward to Elastic/Logstash**

Use Filebeat to ship logs:

```yaml
# filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - C:\Program Files\osquery\log\*.log
  fields:
    log_type: osquery
  json.keys_under_root: true

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  index: "osquery-%{+yyyy.MM.dd}"
```

## Troubleshooting

### Service Won't Start

```powershell
# Check service status
Get-Service osqueryd

# Check event logs
Get-EventLog -LogName Application -Source osqueryd -Newest 20

# Verify config syntax
& "C:\Program Files\osquery\osqueryd.exe" --config_check `
    --config_path="C:\Program Files\osquery\osquery.conf"
```

### No Query Results

```powershell
# Verify packs are loaded
& "C:\Program Files\osquery\osqueryi.exe" "SELECT * FROM osquery_packs;"

# Check schedule
& "C:\Program Files\osquery\osqueryi.exe" "SELECT * FROM osquery_schedule;"

# Review info logs
Get-Content "C:\Program Files\osquery\log\osqueryd.INFO" -Tail 50
```

### High CPU/Memory Usage

```powershell
# Check query intervals (reduce frequency)
# Edit pack files to increase interval values

# Monitor resource usage
Get-Process osqueryd | Select-Object CPU, WorkingSet, Threads
```

### Permission Errors

Some queries require elevated privileges. Ensure osquery service runs as SYSTEM:

```powershell
Get-WmiObject Win32_Service -Filter "Name='osqueryd'" |
    Select-Object Name, StartName, State
```

## Security Considerations

### File System Permissions

Restrict access to osquery directory:

```powershell
$osqueryPath = "C:\Program Files\osquery"

# Remove inheritance
$acl = Get-Acl $osqueryPath
$acl.SetAccessRuleProtection($true, $false)

# Grant SYSTEM full control
$systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($systemRule)

# Grant Administrators read access
$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Administrators", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($adminRule)

Set-Acl $osqueryPath $acl
```

### Network Security

osquery runs locally; no inbound ports required. If using remote configuration:

- Use HTTPS for configuration retrieval
- Implement certificate pinning
- Restrict outbound connections via firewall

### Data Protection

Results may contain sensitive information:

- Encrypt logs at rest (BitLocker)
- Use secure transport for log forwarding (TLS)
- Implement access controls on log aggregation systems
- Redact sensitive data in queries when possible

## Mass Deployment

### Group Policy Object (GPO) Deployment

**Step 1: Create GPO**

1. Open Group Policy Management
2. Create new GPO: "osquery Deployment"
3. Link to target OUs

**Step 2: Configure Software Installation**

1. Edit GPO → Computer Configuration → Policies → Software Settings → Software Installation
2. Right-click → New → Package
3. Browse to network share with osquery MSI
4. Select "Assigned"

**Step 3: Deploy Configuration Files**

1. Edit GPO → Computer Configuration → Preferences → Windows Settings → Files
2. Create file copy items for:
   - osquery.conf
   - osquery.flags
   - Pack files

**Step 4: Configure Service**

1. Edit GPO → Computer Configuration → Preferences → Control Panel Settings → Services
2. Create new service item:
   - Service name: osqueryd
   - Startup: Automatic
   - Service action: Start service

### PowerShell DSC

Example DSC configuration:

```powershell
Configuration OsqueryDeployment {
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node localhost {
        Package osquery {
            Ensure = "Present"
            Name = "osquery"
            Path = "\\fileserver\packages\osquery-5.11.0.msi"
            ProductId = "YOUR-PRODUCT-ID"
        }

        File OsqueryConfig {
            Ensure = "Present"
            DestinationPath = "C:\Program Files\osquery\osquery.conf"
            SourcePath = "\\fileserver\configs\osquery.conf"
            DependsOn = "[Package]osquery"
        }

        Service OsqueryService {
            Name = "osqueryd"
            State = "Running"
            StartupType = "Automatic"
            DependsOn = "[File]OsqueryConfig"
        }
    }
}
```

## Monitoring and Maintenance

### Health Checks

Create monitoring script (`C:\Scripts\check-osquery-health.ps1`):

```powershell
$service = Get-Service osqueryd -ErrorAction SilentlyContinue

if ($service.Status -ne 'Running') {
    Write-Error "osquery service not running"
    Start-Service osqueryd
}

$logAge = (Get-Item "C:\Program Files\osquery\log\osqueryd.results.log").LastWriteTime
if ((Get-Date) - $logAge -gt (New-TimeSpan -Hours 1)) {
    Write-Warning "No recent query results"
}

Write-Output "osquery health check passed"
```

### Updates

Monitor [osquery releases](https://github.com/osquery/osquery/releases) for updates:

```powershell
# Check current version
& "C:\Program Files\osquery\osqueryi.exe" --version

# Update via MSI (test in dev first)
Start-Process msiexec.exe -Wait -ArgumentList "/i $newMsiPath /quiet /norestart"
```

## References

- [osquery Official Documentation](https://osquery.readthedocs.io/)
- [osquery Windows Deployment](https://osquery.readthedocs.io/en/stable/deployment/deployment-guide/)
- [osquery Schema - Windows Tables](https://osquery.io/schema/)
- [osquery Slack Community](https://osquery.slack.com)

## Next Steps

1. Test osquery installation on a representative Windows system
2. Deploy NIST 800-171 compliance packs
3. Configure log forwarding to your SIEM/log aggregation platform
4. Run initial compliance assessment using `generate_report.py`
5. Establish baseline configurations and monitoring
