function Test-NISTControl {
    <#
    .SYNOPSIS
        Tests a single NIST 800-171 control for compliance.

    .DESCRIPTION
        Performs a quick check of a specific control without running full assessment.
        Useful for targeted validation and troubleshooting.

    .PARAMETER ControlId
        NIST control ID to test (e.g., "3.1.8", "3.5.7").

    .PARAMETER OsqueryResultsPath
        Path to osquery results log file (optional).

    .PARAMETER IncludeRemediation
        Show remediation steps for failed controls.

    .EXAMPLE
        Test-NISTControl -ControlId "3.1.8"
        Tests account lockout policy compliance.

    .EXAMPLE
        Test-NISTControl -ControlId "3.5.7" -IncludeRemediation
        Tests password policy and shows remediation steps.

    .OUTPUTS
        PSCustomObject with control test result
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$ControlId,

        [Parameter()]
        [string]$OsqueryResultsPath,

        [Parameter()]
        [switch]$IncludeRemediation
    )

    try {
        Write-Verbose "Testing control $ControlId..."

        # Load mappings
        $mappings = Get-ControlMapping -Path $script:MappingsPath

        # Find the specific control
        $control = $mappings.controls | Where-Object { $_.control_id -eq $ControlId }

        if (-not $control) {
            throw "Control $ControlId not found in mappings"
        }

        # Get security policy if needed
        $securityPolicy = $null
        if ($ControlId -in @("3.1.8", "3.5.7")) {
            Write-Verbose "Retrieving Windows security policy..."
            $securityPolicy = Get-WindowsSecurityPolicy
        }

        # Parse osquery results if provided
        $osqueryData = $null
        if ($OsqueryResultsPath -and (Test-Path $OsqueryResultsPath)) {
            Write-Verbose "Parsing osquery results..."
            $osqueryData = Parse-OsqueryResults -Path $OsqueryResultsPath
        }

        # Test the control
        $assessment = Test-ControlCriteria `
            -Control $control `
            -OsqueryData $osqueryData `
            -SecurityPolicy $securityPolicy `
            -IncludeEvidence

        # Display results
        $statusColor = switch ($assessment.Status) {
            'Pass' { 'Green' }
            'Fail' { 'Red' }
            'Inconclusive' { 'Yellow' }
            default { 'Gray' }
        }

        Write-Host "`nControl: " -NoNewline
        Write-Host "$($control.control_id) - $($control.control_title)" -ForegroundColor Cyan

        Write-Host "Status:  " -NoNewline
        Write-Host $assessment.Status -ForegroundColor $statusColor

        Write-Host "Severity: $($assessment.Severity)" -ForegroundColor White

        if ($assessment.Findings.Count -gt 0) {
            Write-Host "`nFindings:" -ForegroundColor Yellow
            foreach ($finding in $assessment.Findings) {
                Write-Host "  • $finding" -ForegroundColor Gray
            }
        }

        if ($IncludeRemediation -and $assessment.Recommendations.Count -gt 0) {
            Write-Host "`nRemediation Steps:" -ForegroundColor Yellow
            foreach ($rec in $assessment.Recommendations) {
                Write-Host "  → $rec" -ForegroundColor Cyan
            }
        }

        Write-Host ""

        return $assessment
    }
    catch {
        Write-Error "Failed to test control ${ControlId}: $_"
        throw
    }
}
