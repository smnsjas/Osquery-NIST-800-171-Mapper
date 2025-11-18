function Get-NISTCompliance {
    <#
    .SYNOPSIS
        Performs comprehensive NIST SP 800-171 Rev 2 compliance assessment on Windows systems.

    .DESCRIPTION
        Combines osquery results with native Windows security policy checks to assess
        NIST SP 800-171 Rev 2 compliance. Returns detailed compliance status for each control.

    .PARAMETER OsqueryResultsPath
        Path to osquery results log file (osqueryd.results.log) or JSON file.
        If not specified, will attempt to find at default location.

    .PARAMETER MappingsPath
        Path to NIST 800-171 mappings YAML file.
        Defaults to ../mappings/nist800171_mapping.yaml relative to module.

    .PARAMETER ControlFamily
        Optional filter to assess only specific control family (e.g., "3.1", "3.14").

    .PARAMETER IncludeEvidence
        Include raw evidence data in output (osquery results, policy settings).

    .EXAMPLE
        Get-NISTCompliance
        Performs full compliance assessment using default paths.

    .EXAMPLE
        Get-NISTCompliance -ControlFamily "3.1" -IncludeEvidence
        Assesses only Access Control (3.1) family with detailed evidence.

    .EXAMPLE
        Get-NISTCompliance -OsqueryResultsPath "C:\logs\osquery_results.json"
        Uses custom osquery results file.

    .OUTPUTS
        PSCustomObject with compliance assessment results
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$OsqueryResultsPath,

        [Parameter()]
        [string]$MappingsPath,

        [Parameter()]
        [ValidateSet("3.1", "3.2", "3.3", "3.4", "3.5", "3.6", "3.7", "3.8", "3.9", "3.10", "3.11", "3.12", "3.13", "3.14")]
        [string]$ControlFamily,

        [Parameter()]
        [switch]$IncludeEvidence
    )

    begin {
        Write-Verbose "Starting NIST 800-171 compliance assessment..."

        # Set default paths if not specified
        if (-not $OsqueryResultsPath) {
            $defaultPath = "C:\Program Files\osquery\log\osqueryd.results.log"
            if (Test-Path $defaultPath) {
                $OsqueryResultsPath = $defaultPath
                Write-Verbose "Using default osquery results: $defaultPath"
            }
        }

        if (-not $MappingsPath) {
            $MappingsPath = $script:MappingsPath
            Write-Verbose "Using default mappings: $MappingsPath"
        }

        # Validate paths
        if ($OsqueryResultsPath -and -not (Test-Path $OsqueryResultsPath)) {
            Write-Warning "osquery results not found at: $OsqueryResultsPath"
            Write-Warning "Will perform policy-based checks only."
            $OsqueryResultsPath = $null
        }

        if (-not (Test-Path $MappingsPath)) {
            throw "Mappings file not found: $MappingsPath"
        }
    }

    process {
        try {
            # Load control mappings
            Write-Verbose "Loading NIST 800-171 control mappings..."
            $mappings = Get-ControlMapping -Path $MappingsPath -ControlFamily $ControlFamily

            # Parse osquery results if available
            $osqueryData = $null
            if ($OsqueryResultsPath) {
                Write-Verbose "Parsing osquery results..."
                $osqueryData = Parse-OsqueryResults -Path $OsqueryResultsPath
            }

            # Get Windows security policies (for SAM-based controls)
            Write-Verbose "Retrieving Windows security policies..."
            $securityPolicy = Get-WindowsSecurityPolicy

            # Assess each control
            $results = @()
            $totalControls = $mappings.controls.Count
            $currentControl = 0

            foreach ($control in $mappings.controls) {
                $currentControl++
                $percentComplete = ($currentControl / $totalControls) * 100
                Write-Progress -Activity "Assessing NIST 800-171 Controls" `
                    -Status "Control $($control.control_id): $($control.control_title)" `
                    -PercentComplete $percentComplete

                Write-Verbose "Assessing control $($control.control_id)..."

                $assessment = Test-ControlCriteria `
                    -Control $control `
                    -OsqueryData $osqueryData `
                    -SecurityPolicy $securityPolicy `
                    -IncludeEvidence:$IncludeEvidence

                $results += $assessment
            }

            Write-Progress -Activity "Assessing NIST 800-171 Controls" -Completed

            # Generate summary
            $summary = @{
                AssessmentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Hostname = $env:COMPUTERNAME
                TotalControls = $results.Count
                Passed = ($results | Where-Object Status -eq "Pass").Count
                Failed = ($results | Where-Object Status -eq "Fail").Count
                Inconclusive = ($results | Where-Object Status -eq "Inconclusive").Count
                NotAssessed = ($results | Where-Object Status -eq "NotAssessed").Count
                ComplianceScore = 0.0
            }

            if ($summary.TotalControls -gt 0) {
                $assessedControls = $summary.Passed + $summary.Failed
                if ($assessedControls -gt 0) {
                    $summary.ComplianceScore = [math]::Round(($summary.Passed / $assessedControls) * 100, 2)
                }
            }

            # Return results
            [PSCustomObject]@{
                Summary = [PSCustomObject]$summary
                Controls = $results
                Metadata = @{
                    NISTVersion = "SP 800-171 Rev 2"
                    MappingsVersion = $mappings.version
                    OsqueryResultsUsed = ($null -ne $OsqueryResultsPath)
                    SecurityPolicyChecked = $true
                }
            }
        }
        catch {
            Write-Error "Error during compliance assessment: $_"
            throw
        }
    }

    end {
        Write-Verbose "Compliance assessment completed."
    }
}
