<#
.SYNOPSIS
    Diagnose osquery results log issues.

.DESCRIPTION
    Checks where osquery is logging results and if scheduled queries are running.
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  osquery Results Diagnostic" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check potential log locations
$logPaths = @(
    "C:\Program Files\osquery\log\osqueryd.results.log",
    "C:\ProgramData\osquery\log\osqueryd.results.log",
    "C:\Program Files\osquery\osqueryd.results.log",
    "C:\ProgramData\osquery\osqueryd.results.log"
)

Write-Host "Checking for osquery results log..." -ForegroundColor Yellow
$foundLog = $null

foreach ($path in $logPaths) {
    if (Test-Path $path) {
        $file = Get-Item $path
        Write-Host "[FOUND] $path" -ForegroundColor Green
        Write-Host "        Size: $($file.Length) bytes" -ForegroundColor Gray
        Write-Host "        Modified: $($file.LastWriteTime)" -ForegroundColor Gray
        $foundLog = $path
    } else {
        Write-Host "[NOT FOUND] $path" -ForegroundColor Gray
    }
}

Write-Host ""

if ($foundLog) {
    Write-Host "Checking log contents (last 20 lines)..." -ForegroundColor Yellow
    Write-Host ""

    $lines = Get-Content $foundLog -Tail 20 -ErrorAction SilentlyContinue

    if ($lines) {
        foreach ($line in $lines) {
            try {
                $json = $line | ConvertFrom-Json -ErrorAction Stop
                if ($json.name) {
                    Write-Host "[✓] Query: $($json.name) - Rows: $(if ($json.columns) { $json.columns.Count } else { 0 })" -ForegroundColor Green
                }
            } catch {
                Write-Host "[?] $line" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "[EMPTY] Log file exists but has no content yet" -ForegroundColor Yellow
        Write-Host "        Scheduled queries haven't run yet - wait 5-10 minutes" -ForegroundColor Gray
    }
} else {
    Write-Host "[ERROR] No osquery results log found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible causes:" -ForegroundColor Yellow
    Write-Host "  1. osquery service not running" -ForegroundColor Gray
    Write-Host "  2. Queries not configured yet" -ForegroundColor Gray
    Write-Host "  3. Insufficient time has passed (queries run on schedule)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Checking osquery configuration..." -ForegroundColor Yellow

$confPath = "C:\Program Files\osquery\osquery.conf"
if (Test-Path $confPath) {
    try {
        $conf = Get-Content $confPath -Raw | ConvertFrom-Json
        Write-Host "[✓] Configuration found" -ForegroundColor Green

        if ($conf.options.logger_path) {
            Write-Host "    Configured log path: $($conf.options.logger_path)" -ForegroundColor Cyan
        }

        if ($conf.packs) {
            $packCount = ($conf.packs | Get-Member -MemberType NoteProperty).Count
            Write-Host "    Configured packs: $packCount" -ForegroundColor Gray
        }
    } catch {
        Write-Host "[WARN] Could not parse configuration" -ForegroundColor Yellow
    }
} else {
    Write-Host "[NOT FOUND] No configuration at $confPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Recommendation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (-not $foundLog) {
    Write-Host "Wait 5-10 minutes for scheduled queries to run, then:" -ForegroundColor Yellow
    Write-Host "  1. Run this diagnostic again" -ForegroundColor White
    Write-Host "  2. Check service: Get-Service osqueryd" -ForegroundColor White
    Write-Host "  3. Check event viewer for osquery errors" -ForegroundColor White
} elseif ($lines -and $lines.Count -gt 0) {
    Write-Host "osquery is working! Try compliance report with correct path:" -ForegroundColor Green
    Write-Host "  Get-NISTCompliance -OsqueryResultsPath '$foundLog'" -ForegroundColor Cyan
} else {
    Write-Host "Log file exists but is empty. Wait 5-10 minutes for queries to run." -ForegroundColor Yellow
}

Write-Host ""
