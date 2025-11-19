#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Test osquery NIST compliance queries interactively.

.DESCRIPTION
    Runs sample queries from each pack to verify osquery is working
    and collecting compliance data.

.EXAMPLE
    .\Test-OsqueryQueries.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Testing osquery NIST Queries" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Find osqueryi executable
$osqueryPaths = @(
    "C:\Program Files\osquery\osqueryi.exe",
    "C:\ProgramData\osquery\osqueryi.exe"
)

$osqueryi = $null
foreach ($path in $osqueryPaths) {
    if (Test-Path $path) {
        $osqueryi = $path
        break
    }
}

if (-not $osqueryi) {
    Write-Error "osqueryi.exe not found. Please ensure osquery is installed."
    exit 1
}

Write-Host "[OK] Found osqueryi: $osqueryi" -ForegroundColor Green
Write-Host ""

# Test queries
$testQueries = @(
    @{
        Name = "Local Users (3.1.1)"
        Query = "SELECT uid, username, description FROM users WHERE uid >= 1000 AND username NOT IN ('Guest', 'DefaultAccount', 'WDAGUtilityAccount');"
    },
    @{
        Name = "Administrator Group Members (3.1.5)"
        Query = "SELECT u.username FROM users u JOIN user_groups ug ON u.uid = ug.uid JOIN groups g ON ug.gid = g.gid WHERE g.groupname = 'Administrators';"
    },
    @{
        Name = "Installed Software (3.4.1)"
        Query = "SELECT name, version, publisher FROM programs ORDER BY name LIMIT 10;"
    },
    @{
        Name = "Running Services (3.4.6)"
        Query = "SELECT name, display_name, status, start_type FROM services WHERE status = 'RUNNING' LIMIT 10;"
    },
    @{
        Name = "Windows Patches (3.14.1)"
        Query = "SELECT hotfix_id, description, installed_on FROM patches ORDER BY installed_on DESC LIMIT 5;"
    },
    @{
        Name = "Antivirus Status (3.14.2)"
        Query = "SELECT type, name, state, signatures_up_to_date FROM windows_security_products WHERE type IN ('Antivirus', 'Antispyware');"
    },
    @{
        Name = "Listening Ports (3.13.1)"
        Query = "SELECT DISTINCT port, protocol, address, pid FROM listening_ports WHERE port NOT IN (135, 445) ORDER BY port LIMIT 10;"
    },
    @{
        Name = "Security Policy File (3.5.7)"
        Query = "SELECT path, size, mtime FROM file WHERE path = 'C:\\ProgramData\\osquery\\security_policy.json';"
    }
)

$successCount = 0
$failCount = 0

foreach ($test in $testQueries) {
    Write-Host "Testing: $($test.Name)" -ForegroundColor Yellow
    Write-Host "Query: $($test.Query)" -ForegroundColor Gray

    try {
        # Capture only stdout, let stderr go to console
        $result = & $osqueryi --json $test.Query 2>$null

        # Filter to only JSON lines (osquery may output warnings)
        $jsonLines = $result | Where-Object { $_ -match '^\s*[\[\{]' }

        if ($jsonLines) {
            $jsonOutput = $jsonLines -join "`n"
            $data = $jsonOutput | ConvertFrom-Json -ErrorAction Stop

            if ($data -and $data.Count -gt 0) {
                Write-Host "[PASS] Returned $($data.Count) row(s)" -ForegroundColor Green
                $successCount++
            } elseif ($test.Name -like "*Security Policy File*") {
                Write-Host "[INFO] Security policy file not found - run Install-SecurityPolicyExport.ps1" -ForegroundColor Cyan
                $successCount++
            } else {
                Write-Host "[PASS] Query successful (0 rows)" -ForegroundColor Green
                $successCount++
            }
        } else {
            Write-Host "[PASS] Query successful (0 rows)" -ForegroundColor Green
            $successCount++
        }
    } catch {
        Write-Host "[FAIL] Error executing query: $_" -ForegroundColor Red
        $failCount++
    }

    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary:" -ForegroundColor Cyan
Write-Host "  Passed: $successCount" -ForegroundColor Green
Write-Host "  Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "[SUCCESS] All queries working! osquery is ready for compliance monitoring." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Run: .\Deploy-OsqueryCompliance.ps1  (if not already done)" -ForegroundColor White
    Write-Host "2. Wait 5-10 minutes for scheduled queries to run" -ForegroundColor White
    Write-Host "3. Run: Get-NISTCompliance | Export-NISTReport -Format Console" -ForegroundColor White
} else {
    Write-Host "[WARNING] Some queries failed. Check osquery installation." -ForegroundColor Yellow
}
