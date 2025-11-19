<#
.SYNOPSIS
    Manually test the 10 mapping.yaml queries that should be working.

.DESCRIPTION
    Runs the queries the PowerShell module expects, to diagnose why they
    aren't appearing in the osquery results log.
#>

$osqueryi = "C:\Program Files\osquery\osqueryi.exe"

if (-not (Test-Path $osqueryi)) {
    Write-Host "[ERROR] osqueryi not found at: $osqueryi" -ForegroundColor Red
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Testing Mapping Queries" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$queries = @{
    "ac_local_users" = "SELECT uid, username, description, type, shell FROM users WHERE uid >= 1000 AND username NOT IN ('Guest', 'DefaultAccount', 'WDAGUtilityAccount');"
    "ac_admin_users" = "SELECT u.username, u.uid, g.groupname FROM users u JOIN user_groups ug ON u.uid = ug.uid JOIN groups g ON ug.gid = g.gid WHERE g.groupname = 'Administrators';"
    "ac_active_sessions" = "SELECT user, host, time, type FROM logged_in_users WHERE type NOT IN ('system', 'boot');"
    "ac_privileged_groups" = "SELECT u.username, g.groupname, u.uid FROM users u JOIN user_groups ug ON u.uid = ug.uid JOIN groups g ON ug.gid = g.gid WHERE g.groupname IN ('Administrators', 'Power Users', 'Remote Desktop Users', 'Backup Operators', 'Server Operators');"
    "ac_uac_settings" = "SELECT key, name, type, data FROM registry WHERE path = 'HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System\\EnableLUA';"
    "au_audit_policy_settings" = "SELECT name, type, data FROM registry WHERE key LIKE 'HKEY_LOCAL_MACHINE\\Security\\Policy\\PolAdtEv\\%';"
    "cm_installed_programs" = "SELECT name, version, install_location, install_date, publisher FROM programs ORDER BY name;"
    "cm_system_baseline" = "SELECT hostname, uuid, cpu_brand, cpu_physical_cores, physical_memory, hardware_vendor, hardware_model FROM system_info;"
    "sc_firewall_enabled" = "SELECT type, name, state, signatures_up_to_date FROM windows_security_products WHERE type = 'Firewall';"
    "sc_open_ports" = "SELECT DISTINCT lp.port, lp.protocol, lp.address, lp.pid, p.name, p.path FROM listening_ports lp LEFT JOIN processes p ON lp.pid = p.pid WHERE lp.port NOT IN (135, 139, 445) ORDER BY lp.port;"
    "si_windows_patches" = "SELECT hotfix_id, description, installed_by, installed_on FROM patches ORDER BY installed_on DESC LIMIT 50;"
    "si_update_service_status" = "SELECT name, display_name, status, start_type FROM services WHERE name = 'wuauserv';"
    "si_antivirus_enabled" = "SELECT type, name, state, signatures_up_to_date FROM windows_security_products WHERE type IN ('Antivirus', 'Antispyware');"
    "si_defender_running" = "SELECT name, display_name, status, start_type, path FROM services WHERE name IN ('WinDefend', 'WdNisSvc', 'Sense');"
    "si_active_connections" = "SELECT pos.pid, p.name, pos.protocol, pos.local_address, pos.local_port, pos.remote_address, pos.remote_port, pos.state FROM process_open_sockets pos LEFT JOIN processes p ON pos.pid = p.pid WHERE pos.state = 'ESTABLISHED' AND pos.remote_address NOT LIKE '127.%' AND pos.remote_address NOT LIKE '::1';"
    "si_remote_access" = "SELECT user, host, time, type, sid FROM logged_in_users WHERE host IS NOT NULL AND host != 'localhost' AND host != '127.0.0.1';"
}

$working = @()
$failing = @()

foreach ($name in $queries.Keys | Sort-Object) {
    $query = $queries[$name]

    Write-Host "Testing: $name" -ForegroundColor Yellow

    try {
        $result = & $osqueryi --json $query 2>$null
        $jsonLines = $result | Where-Object { $_ -match '^\s*[\[\{]' }

        if ($jsonLines) {
            $jsonOutput = $jsonLines -join "`n"
            $data = $jsonOutput | ConvertFrom-Json -ErrorAction Stop

            Write-Host "  [✓] Success - $($data.Count) rows" -ForegroundColor Green
            $working += $name
        } else {
            Write-Host "  [✓] Success - 0 rows" -ForegroundColor Green
            $working += $name
        }
    } catch {
        Write-Host "  [✗] Failed: $_" -ForegroundColor Red
        $failing += $name
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Working: $($working.Count)/16" -ForegroundColor Green
Write-Host "Failing: $($failing.Count)/16" -ForegroundColor $(if ($failing.Count -gt 0) { "Red" } else { "Green" })

if ($failing.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed queries:" -ForegroundColor Red
    $failing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "These queries may not work in scheduled mode either." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Next Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($working.Count -eq 16) {
    Write-Host "✓ All queries work!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Since queries work manually but not in logs, the issue is likely:" -ForegroundColor Yellow
    Write-Host "  1. osquery service needs restart to load new config" -ForegroundColor White
    Write-Host "  2. Snapshot queries only run at startup" -ForegroundColor White
    Write-Host ""
    Write-Host "Restart osquery service:" -ForegroundColor Cyan
    Write-Host "  Restart-Service osqueryd" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Then wait 5 minutes and check results:" -ForegroundColor Cyan
    Write-Host "  .\scripts\Show-OsqueryResultsSummary.ps1" -ForegroundColor Gray
} elseif ($working.Count -ge 14) {
    Write-Host "⚠ Most queries work, but some are failing." -ForegroundColor Yellow
    Write-Host "  Restart osquery and check logs for the working queries." -ForegroundColor White
} else {
    Write-Host "⚠ Many queries are failing." -ForegroundColor Red
    Write-Host "  There may be osquery version compatibility issues." -ForegroundColor White
}

Write-Host ""
