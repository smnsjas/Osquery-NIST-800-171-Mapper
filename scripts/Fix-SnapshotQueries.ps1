#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Fix snapshot queries by changing them to interval-based execution.

.DESCRIPTION
    Changes all queries with "snapshot": true to "snapshot": false so they
    execute on their defined intervals instead of only at startup.

    osquery 5.20.0 on Windows appears to have issues with snapshot queries.
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Fixing Snapshot Queries" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$packDir = "C:\Program Files\osquery\packs"

if (-not (Test-Path $packDir)) {
    Write-Host "[ERROR] Pack directory not found: $packDir" -ForegroundColor Red
    exit 1
}

$packFiles = Get-ChildItem -Path $packDir -Filter "*.conf"

foreach ($file in $packFiles) {
    Write-Host "Processing: $($file.Name)" -ForegroundColor Yellow

    $content = Get-Content $file.FullName -Raw
    $originalContent = $content

    # Replace "snapshot": true with "snapshot": false
    $content = $content -replace '"snapshot":\s*true', '"snapshot": false'

    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "  [✓] Updated snapshot queries" -ForegroundColor Green
    } else {
        Write-Host "  [•] No changes needed" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Restarting osquery" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Restart-Service osqueryd
Write-Host "[✓] osquery service restarted" -ForegroundColor Green

Write-Host ""
Write-Host "Wait 5-10 minutes for queries to execute on their intervals," -ForegroundColor Yellow
Write-Host "then check results:" -ForegroundColor Yellow
Write-Host "  .\scripts\Show-OsqueryResultsSummary.ps1" -ForegroundColor Cyan
Write-Host ""
