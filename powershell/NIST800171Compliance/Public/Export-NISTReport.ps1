function Export-NISTReport {
    <#
    .SYNOPSIS
        Exports NIST 800-171 compliance assessment to various formats.

    .DESCRIPTION
        Generates compliance reports in multiple formats (JSON, HTML, CSV)
        from compliance assessment results.

    .PARAMETER ComplianceData
        Compliance assessment object from Get-NISTCompliance.

    .PARAMETER OutputPath
        Path where report file will be saved.

    .PARAMETER Format
        Report format: JSON, HTML, CSV, or Console.

    .EXAMPLE
        $compliance = Get-NISTCompliance
        Export-NISTReport -ComplianceData $compliance -OutputPath ".\report.html" -Format HTML

    .EXAMPLE
        Get-NISTCompliance | Export-NISTReport -OutputPath ".\report.json" -Format JSON
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Low')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject]$ComplianceData,

        [Parameter()]
        [string]$OutputPath,

        [Parameter()]
        [ValidateSet('JSON', 'HTML', 'CSV', 'Console')]
        [string]$Format = 'Console'
    )

    process {
        try {
            switch ($Format) {
                'JSON' {
                    if (-not $OutputPath) {
                        $OutputPath = "NIST_800-171_Compliance_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                    }

                    # Resolve to absolute path
                    $OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)

                    # Ensure directory exists
                    $outputDir = Split-Path -Path $OutputPath -Parent
                    if ($outputDir -and -not (Test-Path $outputDir)) {
                        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
                    }

                    if ($PSCmdlet.ShouldProcess($OutputPath, "Export JSON compliance report")) {
                        $json = $ComplianceData | ConvertTo-Json -Depth 10
                        # Use Set-Content for consistent UTF8 encoding across PS versions
                        Set-Content -Path $OutputPath -Value $json -Encoding UTF8
                        Write-Host "JSON report exported to: $OutputPath" -ForegroundColor Green
                    }
                }

                'CSV' {
                    if (-not $OutputPath) {
                        $OutputPath = "NIST_800-171_Compliance_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
                    }

                    # Resolve to absolute path
                    $OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)

                    # Ensure directory exists
                    $outputDir = Split-Path -Path $OutputPath -Parent
                    if ($outputDir -and -not (Test-Path $outputDir)) {
                        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
                    }

                    $csvData = $ComplianceData.Controls | Select-Object `
                        ControlId, ControlTitle, ControlFamily, AutomationLevel, Status, Severity, `
                        @{Name='FindingsCount';Expression={$_.Findings.Count}}, `
                        @{Name='RecommendationsCount';Expression={$_.Recommendations.Count}}, `
                        Timestamp

                    if ($PSCmdlet.ShouldProcess($OutputPath, "Export CSV compliance report")) {
                        $csvData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                        Write-Host "CSV report exported to: $OutputPath" -ForegroundColor Green
                    }
                }

                'HTML' {
                    if (-not $OutputPath) {
                        $OutputPath = "NIST_800-171_Compliance_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
                    }

                    # Resolve to absolute path
                    $OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)

                    # Ensure directory exists
                    $outputDir = Split-Path -Path $OutputPath -Parent
                    if ($outputDir -and -not (Test-Path $outputDir)) {
                        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
                    }

                    $html = Generate-HTMLReport -ComplianceData $ComplianceData

                    if ($PSCmdlet.ShouldProcess($OutputPath, "Export HTML compliance report")) {
                        # Use Set-Content for consistent UTF8 encoding across PS versions
                        Set-Content -Path $OutputPath -Value $html -Encoding UTF8
                        Write-Host "HTML report exported to: $OutputPath" -ForegroundColor Green
                    }
                }

                'Console' {
                    Write-ComplianceToConsole -ComplianceData $ComplianceData
                }
            }
        }
        catch {
            Write-Error "Failed to export report: $_"
            throw
        }
    }
}

function Generate-HTMLReport {
    param([PSCustomObject]$ComplianceData)

    $summary = $ComplianceData.Summary
    $passedPercent = if ($summary.TotalControls -gt 0) {
        [math]::Round(($summary.Passed / $summary.TotalControls) * 100, 1)
    } else { 0 }
    $failedPercent = if ($summary.TotalControls -gt 0) {
        [math]::Round(($summary.Failed / $summary.TotalControls) * 100, 1)
    } else { 0 }

    $statusColor = @{
        'Pass' = '#28a745'
        'Fail' = '#dc3545'
        'Inconclusive' = '#ffc107'
        'NotAssessed' = '#6c757d'
    }

    $controlRows = $ComplianceData.Controls | ForEach-Object {
        $color = $statusColor[$_.Status]
        $findingsList = ($_.Findings | ForEach-Object { "<li>$_</li>" }) -join "`n"
        $recList = ($_.Recommendations | ForEach-Object { "<li>$_</li>" }) -join "`n"

        @"
        <tr>
            <td>$($_.ControlId)</td>
            <td>$($_.ControlTitle)</td>
            <td>$($_.ControlFamily)</td>
            <td><span class="badge" style="background-color: $color; color: white;">$($_.Status)</span></td>
            <td>$($_.Severity)</td>
            <td><ul style="margin: 0; padding-left: 20px;">$findingsList</ul></td>
            <td><ul style="margin: 0; padding-left: 20px;">$recList</ul></td>
        </tr>
"@
    } -join "`n"

    return @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NIST SP 800-171 Rev 2 Compliance Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1400px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #007bff; padding-bottom: 10px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 30px 0; }
        .summary-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .summary-card h3 { margin: 0 0 10px 0; font-size: 14px; opacity: 0.9; }
        .summary-card .value { font-size: 32px; font-weight: bold; }
        .summary-card.score { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #007bff; color: white; font-weight: 600; }
        tr:hover { background-color: #f8f9fa; }
        .badge { padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: 600; }
        ul { margin: 5px 0; }
        .metadata { background: #e9ecef; padding: 15px; border-radius: 4px; margin-top: 30px; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>NIST SP 800-171 Rev 2 Compliance Report</h1>

        <div class="summary">
            <div class="summary-card">
                <h3>Total Controls</h3>
                <div class="value">$($summary.TotalControls)</div>
            </div>
            <div class="summary-card" style="background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);">
                <h3>Passed</h3>
                <div class="value">$($summary.Passed) ($passedPercent%)</div>
            </div>
            <div class="summary-card" style="background: linear-gradient(135deg, #eb3349 0%, #f45c43 100%);">
                <h3>Failed</h3>
                <div class="value">$($summary.Failed) ($failedPercent%)</div>
            </div>
            <div class="summary-card score">
                <h3>Compliance Score</h3>
                <div class="value">$($summary.ComplianceScore)%</div>
            </div>
        </div>

        <h2>Control Assessment Details</h2>
        <table>
            <thead>
                <tr>
                    <th>Control ID</th>
                    <th>Control Title</th>
                    <th>Family</th>
                    <th>Status</th>
                    <th>Severity</th>
                    <th>Findings</th>
                    <th>Recommendations</th>
                </tr>
            </thead>
            <tbody>
                $controlRows
            </tbody>
        </table>

        <div class="metadata">
            <strong>Report Metadata</strong><br>
            Assessment Date: $($summary.AssessmentDate)<br>
            Hostname: $($summary.Hostname)<br>
            NIST Version: $($ComplianceData.Metadata.NISTVersion)<br>
            Mappings Version: $($ComplianceData.Metadata.MappingsVersion)<br>
            osquery Results Used: $($ComplianceData.Metadata.OsqueryResultsUsed)<br>
            Security Policy Checked: $($ComplianceData.Metadata.SecurityPolicyChecked)
        </div>
    </div>
</body>
</html>
"@
}

function Write-ComplianceToConsole {
    param([PSCustomObject]$ComplianceData)

    $summary = $ComplianceData.Summary

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  NIST SP 800-171 Rev 2 Compliance Report" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Host "Assessment Date: " -NoNewline
    Write-Host $summary.AssessmentDate -ForegroundColor White
    Write-Host "Hostname: " -NoNewline
    Write-Host $summary.Hostname -ForegroundColor White
    Write-Host ""

    Write-Host "Summary:" -ForegroundColor Yellow
    Write-Host "  Total Controls:    $($summary.TotalControls)" -ForegroundColor White
    Write-Host "  Passed:            " -NoNewline -ForegroundColor White
    Write-Host "$($summary.Passed)" -ForegroundColor Green
    Write-Host "  Failed:            " -NoNewline -ForegroundColor White
    Write-Host "$($summary.Failed)" -ForegroundColor Red
    Write-Host "  Inconclusive:      $($summary.Inconclusive)" -ForegroundColor White
    Write-Host "  Not Assessed:      $($summary.NotAssessed)" -ForegroundColor White
    Write-Host "  Compliance Score:  " -NoNewline -ForegroundColor White
    Write-Host "$($summary.ComplianceScore)%" -ForegroundColor $(if($summary.ComplianceScore -ge 80){'Green'}elseif($summary.ComplianceScore -ge 60){'Yellow'}else{'Red'})

    Write-Host "`nControl Details:`n" -ForegroundColor Yellow

    foreach ($control in $ComplianceData.Controls) {
        $statusColor = switch ($control.Status) {
            'Pass' { 'Green' }
            'Fail' { 'Red' }
            'Inconclusive' { 'Yellow' }
            default { 'Gray' }
        }

        Write-Host "[$($control.Status.PadRight(13))]" -NoNewline -ForegroundColor $statusColor
        Write-Host " $($control.ControlId) - $($control.ControlTitle)" -ForegroundColor White

        if ($control.Findings.Count -gt 0) {
            foreach ($finding in $control.Findings) {
                Write-Host "    • $finding" -ForegroundColor Gray
            }
        }

        if ($control.Recommendations.Count -gt 0 -and $control.Status -eq 'Fail') {
            foreach ($rec in $control.Recommendations) {
                Write-Host "    → $rec" -ForegroundColor Cyan
            }
        }

        # Display evidence if present
        if ($control.Evidence) {
            Write-Host "    Evidence:" -ForegroundColor DarkCyan
            foreach ($queryName in $control.Evidence.Keys) {
                $results = $control.Evidence[$queryName]
                if ($results -is [Array] -and $results.Count -gt 0) {
                    Write-Host "      Query: $queryName ($($results.Count) rows)" -ForegroundColor DarkGray
                    # Show first 5 rows
                    $displayCount = [Math]::Min(5, $results.Count)
                    for ($i = 0; $i -lt $displayCount; $i++) {
                        $row = $results[$i]
                        $rowStr = ($row.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ", "
                        Write-Host "        [$($i+1)] $rowStr" -ForegroundColor DarkGray
                    }
                    if ($results.Count -gt 5) {
                        Write-Host "        ... and $($results.Count - 5) more rows" -ForegroundColor DarkGray
                    }
                } elseif ($results) {
                    Write-Host "      Query: $queryName" -ForegroundColor DarkGray
                    Write-Host "        $results" -ForegroundColor DarkGray
                }
            }
        }

        Write-Host ""
    }

    Write-Host "========================================`n" -ForegroundColor Cyan
}
