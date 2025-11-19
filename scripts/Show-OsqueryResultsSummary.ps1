<#
.SYNOPSIS
    Show summary of all osquery results collected so far.

.DESCRIPTION
    Parses the entire osquery results log and shows which queries have data.
#>

$logPath = "C:\ProgramData\osquery\log\osqueryd.results.log"

if (-not (Test-Path $logPath)) {
    Write-Host "[ERROR] Log file not found: $logPath" -ForegroundColor Red
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  osquery Results Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Log file: $logPath" -ForegroundColor Gray
Write-Host ""

# Parse all results
$queryStats = @{}

Get-Content $logPath | ForEach-Object {
    try {
        $json = $_ | ConvertFrom-Json -ErrorAction Stop
        if ($json.name) {
            $queryName = $json.name

            if (-not $queryStats.ContainsKey($queryName)) {
                $queryStats[$queryName] = @{
                    Count = 0
                    FirstSeen = $json.unixTime
                    LastSeen = $json.unixTime
                    RowCount = 0
                }
            }

            $queryStats[$queryName].Count++
            $queryStats[$queryName].LastSeen = $json.unixTime

            if ($json.columns) {
                $queryStats[$queryName].RowCount += 1
            }
        }
    } catch {
        # Skip invalid lines
    }
}

Write-Host "Found $($queryStats.Count) unique queries:" -ForegroundColor Yellow
Write-Host ""

$queryStats.GetEnumerator() | Sort-Object Name | ForEach-Object {
    $name = $_.Key
    $stats = $_.Value

    # Strip pack prefix for display
    # Query names always start with control family code: ac_, au_, cm_, ia_, ra_, sc_, si_
    $displayName = $name
    if ($name -match '((?:ac|au|cm|ia|ra|sc|si)_.+)$') {
        $displayName = $matches[1]
    }

    Write-Host "[✓] $displayName" -ForegroundColor Green
    Write-Host "    Full name: $name" -ForegroundColor Gray
    Write-Host "    Executions: $($stats.Count)" -ForegroundColor Gray
    Write-Host "    Result rows: $($stats.RowCount)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Compliance Report Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check which queries the mapping expects
$expectedQueries = @(
    "ac_local_users",
    "ac_admin_users",
    "ac_active_sessions",
    "ac_privileged_groups",
    "ac_uac_settings",
    "au_audit_policy_settings",
    "cm_installed_programs",
    "cm_system_baseline",
    "sc_firewall_enabled",
    "sc_open_ports",
    "si_windows_patches",
    "si_update_service_status",
    "si_antivirus_enabled",
    "si_defender_running",
    "si_active_connections",
    "si_remote_access"
)

Write-Host ""
Write-Host "Checking for queries needed by mapping.yaml..." -ForegroundColor Yellow
Write-Host ""

$foundQueries = @()
$missingQueries = @()

foreach ($expected in $expectedQueries) {
    # Check if we have this query (with or without pack prefix)
    $found = $false
    foreach ($actual in $queryStats.Keys) {
        # Normalize the actual query name same way parser does
        $normalizedName = $actual
        if ($actual -match '((?:ac|au|cm|ia|ra|sc|si)_.+)$') {
            $normalizedName = $matches[1]
        }

        if ($normalizedName -eq $expected) {
            $foundQueries += $expected
            $found = $true
            break
        }
    }

    if (-not $found) {
        $missingQueries += $expected
    }
}

if ($foundQueries.Count -gt 0) {
    Write-Host "Queries with data ($($foundQueries.Count)):" -ForegroundColor Green
    $foundQueries | Sort-Object | ForEach-Object {
        Write-Host "  [✓] $_" -ForegroundColor Green
    }
}

Write-Host ""

if ($missingQueries.Count -gt 0) {
    Write-Host "Queries still pending ($($missingQueries.Count)):" -ForegroundColor Yellow
    $missingQueries | Sort-Object | ForEach-Object {
        Write-Host "  [⏳] $_" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "These queries haven't executed yet. Reasons:" -ForegroundColor Gray
    Write-Host "  - Longer interval (some run every 2 hours)" -ForegroundColor Gray
    Write-Host "  - osquery service recently restarted" -ForegroundColor Gray
    Write-Host "  - Query may have failed (check osquery logs)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Recommendation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($foundQueries.Count -ge 8) {
    Write-Host "✓ Most queries have data! Try the compliance report:" -ForegroundColor Green
    Write-Host "  Get-NISTCompliance -OsqueryResultsPath '$logPath' | Export-NISTReport -Format Console" -ForegroundColor Cyan
} elseif ($foundQueries.Count -gt 0) {
    Write-Host "⏳ Some queries have data, but not all. Options:" -ForegroundColor Yellow
    Write-Host "  1. Wait 10-30 more minutes for all queries to execute" -ForegroundColor White
    Write-Host "  2. Run compliance report now (some controls will still show Inconclusive)" -ForegroundColor White
} else {
    Write-Host "⚠ No expected queries found in log yet. Check:" -ForegroundColor Yellow
    Write-Host "  1. Is osquery service running? Get-Service osqueryd" -ForegroundColor White
    Write-Host "  2. Check osquery error log for issues" -ForegroundColor White
    Write-Host "  3. Wait another 10 minutes and run this diagnostic again" -ForegroundColor White
}

Write-Host ""
