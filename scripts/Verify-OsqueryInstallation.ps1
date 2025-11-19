<#
.SYNOPSIS
    Verify osquery installation and test basic functionality.

.DESCRIPTION
    Quick diagnostic script to ensure osquery is installed and working
    before running compliance deployment.

.EXAMPLE
    .\Verify-OsqueryInstallation.ps1
#>

[CmdletBinding()]
param()

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  osquery Installation Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for osquery executables
$osqueryExePaths = @(
    "C:\Program Files\osquery\osqueryi.exe",
    "C:\Program Files\osquery\osqueryd.exe",
    "C:\ProgramData\osquery\osqueryi.exe",
    "C:\ProgramData\osquery\osqueryd.exe"
)

$foundOsqueryi = $null
$foundOsqueryd = $null

Write-Host "Searching for osquery executables..." -ForegroundColor Yellow

foreach ($path in $osqueryExePaths) {
    if (Test-Path $path) {
        if ($path -like "*osqueryi.exe") {
            $foundOsqueryi = $path
            Write-Host "[OK] Found osqueryi: $path" -ForegroundColor Green
        } elseif ($path -like "*osqueryd.exe") {
            $foundOsqueryd = $path
            Write-Host "[OK] Found osqueryd: $path" -ForegroundColor Green
        }
    }
}

if (-not $foundOsqueryi -and -not $foundOsqueryd) {
    Write-Host "[FAIL] osquery not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install osquery from: https://osquery.io/downloads" -ForegroundColor Yellow
    Write-Host "Or run: choco install osquery" -ForegroundColor Yellow
    exit 1
}

# Test osqueryi functionality
if ($foundOsqueryi) {
    Write-Host ""
    Write-Host "Testing osqueryi with simple query..." -ForegroundColor Yellow

    try {
        $testQuery = "SELECT version FROM osquery_info;"
        $result = & $foundOsqueryi --json $testQuery 2>&1

        if ($LASTEXITCODE -eq 0) {
            $data = $result | ConvertFrom-Json -ErrorAction Stop
            $version = $data[0].version
            Write-Host "[OK] osquery version: $version" -ForegroundColor Green
        } else {
            Write-Host "[WARN] osqueryi returned error: $result" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[WARN] Could not parse osquery output: $_" -ForegroundColor Yellow
    }
}

# Check osquery service
Write-Host ""
Write-Host "Checking osquery service status..." -ForegroundColor Yellow

$service = Get-Service -Name "osqueryd" -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "[OK] Service found: osqueryd" -ForegroundColor Green
    Write-Host "    Status: $($service.Status)" -ForegroundColor Gray
    Write-Host "    Startup Type: $($service.StartType)" -ForegroundColor Gray

    if ($service.Status -ne "Running") {
        Write-Host "[WARN] Service is not running" -ForegroundColor Yellow
    }
} else {
    Write-Host "[WARN] osqueryd service not found" -ForegroundColor Yellow
    Write-Host "       You may need to install osquery as a service" -ForegroundColor Gray
}

# Check configuration
Write-Host ""
Write-Host "Checking for configuration files..." -ForegroundColor Yellow

$configPaths = @(
    "C:\Program Files\osquery\osquery.conf",
    "C:\ProgramData\osquery\osquery.conf"
)

$foundConfig = $false
foreach ($confPath in $configPaths) {
    if (Test-Path $confPath) {
        Write-Host "[OK] Found config: $confPath" -ForegroundColor Green
        $foundConfig = $true

        try {
            $conf = Get-Content $confPath -Raw | ConvertFrom-Json
            if ($conf.packs) {
                $packCount = ($conf.packs | Get-Member -MemberType NoteProperty).Count
                Write-Host "    Configured packs: $packCount" -ForegroundColor Gray
            }
        } catch {
            Write-Host "[WARN] Could not parse config file" -ForegroundColor Yellow
        }
    }
}

if (-not $foundConfig) {
    Write-Host "[INFO] No configuration file found - run Deploy-OsqueryCompliance.ps1" -ForegroundColor Cyan
}

# Check for query packs
Write-Host ""
Write-Host "Checking for NIST compliance packs..." -ForegroundColor Yellow

$packDir = "C:\Program Files\osquery\packs"
if (Test-Path $packDir) {
    $nistPacks = @(
        "ac_access_control.conf",
        "au_audit_accountability.conf",
        "cm_configuration_management.conf",
        "ia_identification_authentication.conf",
        "ra_risk_assessment.conf",
        "sc_system_communications.conf",
        "si_system_integrity.conf"
    )

    $foundPacks = 0
    foreach ($pack in $nistPacks) {
        if (Test-Path (Join-Path $packDir $pack)) {
            $foundPacks++
        }
    }

    if ($foundPacks -eq 7) {
        Write-Host "[OK] All 7 NIST packs deployed" -ForegroundColor Green
    } elseif ($foundPacks -gt 0) {
        Write-Host "[WARN] Only $foundPacks/7 packs found" -ForegroundColor Yellow
    } else {
        Write-Host "[INFO] No NIST packs deployed yet - run Deploy-OsqueryCompliance.ps1" -ForegroundColor Cyan
    }
} else {
    Write-Host "[INFO] Pack directory not found - run Deploy-OsqueryCompliance.ps1" -ForegroundColor Cyan
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($foundOsqueryi -and $foundOsqueryd) {
    Write-Host "[OK] osquery is installed and functional" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Run: .\Deploy-OsqueryCompliance.ps1" -ForegroundColor White
    Write-Host "2. Wait 5-10 minutes for queries to execute" -ForegroundColor White
    Write-Host "3. Run: Get-NISTCompliance | Export-NISTReport -Format Console" -ForegroundColor White
} else {
    Write-Host "[ACTION REQUIRED] Install osquery to continue" -ForegroundColor Red
    Write-Host "Download from: https://osquery.io/downloads" -ForegroundColor Yellow
}
Write-Host ""
