#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Deploy NIST 800-171 compliance monitoring to osquery.

.DESCRIPTION
    This script configures osquery with all compliance query packs and
    sets up the security policy export mechanism.

.EXAMPLE
    .\Deploy-OsqueryCompliance.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  NIST 800-171 osquery Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Detect osquery installation
$osqueryPaths = @(
    "C:\Program Files\osquery",
    "C:\ProgramData\osquery"
)

$osqueryRoot = $null
foreach ($path in $osqueryPaths) {
    if (Test-Path "$path\osqueryd.exe") {
        $osqueryRoot = $path
        break
    }
}

if (-not $osqueryRoot) {
    Write-Error "osquery not found. Please install osquery first: https://osquery.io/downloads"
    exit 1
}

Write-Host "[OK] osquery found at: $osqueryRoot" -ForegroundColor Green

# Step 1: Deploy query packs
Write-Host ""
Write-Host "Step 1: Deploying query packs..." -ForegroundColor Yellow

$packsSource = Join-Path $PSScriptRoot "..\packs"
$packsDest = "C:\Program Files\osquery\packs"

if (-not (Test-Path $packsDest)) {
    New-Item -ItemType Directory -Path $packsDest -Force | Out-Null
}

$packFiles = Get-ChildItem -Path $packsSource -Filter "*.conf"
foreach ($pack in $packFiles) {
    Copy-Item -Path $pack.FullName -Destination $packsDest -Force
    Write-Host "  [+] Deployed: $($pack.Name)" -ForegroundColor Gray
}

Write-Host "[OK] Deployed $($packFiles.Count) query packs" -ForegroundColor Green

# Step 2: Create osquery configuration
Write-Host ""
Write-Host "Step 2: Creating osquery configuration..." -ForegroundColor Yellow

$osqueryConf = @{
    options = @{
        config_plugin = "filesystem"
        logger_plugin = "filesystem"
        logger_path = "C:\ProgramData\osquery\log"
        database_path = "C:\ProgramData\osquery\osquery.db"
        utc = $true
    }
    schedule = @{}
    packs = @{
        "nist_access_control" = "C:\Program Files\osquery\packs\ac_access_control.conf"
        "nist_audit_accountability" = "C:\Program Files\osquery\packs\au_audit_accountability.conf"
        "nist_configuration_management" = "C:\Program Files\osquery\packs\cm_configuration_management.conf"
        "nist_identification_authentication" = "C:\Program Files\osquery\packs\ia_identification_authentication.conf"
        "nist_risk_assessment" = "C:\Program Files\osquery\packs\ra_risk_assessment.conf"
        "nist_system_communications" = "C:\Program Files\osquery\packs\sc_system_communications.conf"
        "nist_system_integrity" = "C:\Program Files\osquery\packs\si_system_integrity.conf"
    }
}

$confPath = "C:\Program Files\osquery\osquery.conf"
$osqueryConf | ConvertTo-Json -Depth 10 | Set-Content -Path $confPath -Encoding UTF8

Write-Host "[OK] Configuration written to: $confPath" -ForegroundColor Green

# Step 3: Create log directory
$logPath = "C:\ProgramData\osquery\log"
if (-not (Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null
    Write-Host "[OK] Created log directory: $logPath" -ForegroundColor Green
}

# Step 4: Install security policy export
Write-Host ""
Write-Host "Step 3: Installing security policy export..." -ForegroundColor Yellow

$installScript = Join-Path $PSScriptRoot "Install-SecurityPolicyExport.ps1"
if (Test-Path $installScript) {
    & $installScript
} else {
    Write-Warning "Install-SecurityPolicyExport.ps1 not found - skipping"
}

# Step 5: Restart osquery service
Write-Host ""
Write-Host "Step 4: Restarting osquery service..." -ForegroundColor Yellow

$service = Get-Service -Name "osqueryd" -ErrorAction SilentlyContinue
if ($service) {
    if ($service.Status -eq "Running") {
        Stop-Service -Name "osqueryd" -Force
        Write-Host "  [+] Stopped osqueryd service" -ForegroundColor Gray
    }

    Start-Service -Name "osqueryd"
    Set-Service -Name "osqueryd" -StartupType Automatic

    Start-Sleep -Seconds 3

    $status = (Get-Service -Name "osqueryd").Status
    if ($status -eq "Running") {
        Write-Host "[OK] osqueryd service is running" -ForegroundColor Green
    } else {
        Write-Warning "osqueryd service failed to start. Status: $status"
    }
} else {
    Write-Warning "osqueryd service not found. You may need to install osquery as a service."
}

# Step 6: Display next steps
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deployment Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Wait 5-10 minutes for osquery to collect data" -ForegroundColor White
Write-Host "2. Run: Get-NISTCompliance | Export-NISTReport -Format Console" -ForegroundColor White
Write-Host "3. Check logs: Get-Content 'C:\ProgramData\osquery\log\osqueryd.results.log' -Tail 50" -ForegroundColor White
Write-Host ""
Write-Host "Configuration files:" -ForegroundColor Yellow
Write-Host "  osquery config:  C:\Program Files\osquery\osquery.conf" -ForegroundColor Gray
Write-Host "  Query packs:     C:\Program Files\osquery\packs\" -ForegroundColor Gray
Write-Host "  Logs:            C:\ProgramData\osquery\log\" -ForegroundColor Gray
Write-Host ""
