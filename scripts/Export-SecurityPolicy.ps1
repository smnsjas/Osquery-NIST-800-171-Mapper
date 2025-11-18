#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Exports Windows security policy to JSON for osquery consumption.

.DESCRIPTION
    Uses secedit to export password and account lockout policies, then converts
    to JSON format that osquery can read via the file table. Designed to run
    as a scheduled task to provide real-time policy data to osquery.

.PARAMETER OutputPath
    Path where JSON output will be written. Default: C:\ProgramData\osquery\security_policy.json

.EXAMPLE
    .\Export-SecurityPolicy.ps1

.EXAMPLE
    .\Export-SecurityPolicy.ps1 -OutputPath "C:\Custom\Path\policy.json"

.NOTES
    - Requires Administrator privileges
    - Should be scheduled to run hourly via Windows Task Scheduler
    - Output consumed by osquery via file table
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath = "C:\ProgramData\osquery\security_policy.json"
)

begin {
    # Verify admin privileges
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This script requires Administrator privileges to export security policy."
    }

    Write-Verbose "Starting security policy export for osquery..."
}

process {
    try {
        # Ensure output directory exists
        $outputDir = Split-Path -Path $OutputPath -Parent
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Create temporary file for secedit output
        $tempCfg = "$env:TEMP\secpol_export_$(Get-Date -Format 'yyyyMMddHHmmss').cfg"

        Write-Verbose "Exporting security policy using secedit..."

        # Export security policy
        $seceditArgs = @('/export', '/cfg', $tempCfg, '/quiet')
        $process = Start-Process -FilePath 'secedit.exe' -ArgumentList $seceditArgs `
            -NoNewWindow -Wait -PassThru

        if ($process.ExitCode -ne 0) {
            throw "secedit.exe failed with exit code: $($process.ExitCode)"
        }

        if (-not (Test-Path $tempCfg)) {
            throw "Security policy export file not created: $tempCfg"
        }

        # Initialize policy object
        $policy = [PSCustomObject]@{
            account_lockout = [PSCustomObject]@{
                lockout_threshold = 0
                lockout_duration = 0
                lockout_window = 0
                configured = $false
            }
            password_policy = [PSCustomObject]@{
                min_password_length = 0
                password_complexity = 0
                min_password_age = 0
                max_password_age = 0
                password_history = 0
                reversible_encryption = 0
                configured = $false
            }
            metadata = [PSCustomObject]@{
                timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                hostname = $env:COMPUTERNAME
                export_method = "secedit"
                version = "1.0"
            }
        }

        Write-Verbose "Parsing security policy configuration..."

        # Parse secedit output
        $content = Get-Content -Path $tempCfg -Encoding Unicode

        foreach ($line in $content) {
            $line = $line.Trim()

            # Account lockout settings
            if ($line -match '^LockoutBadCount\s*=\s*(\d+)') {
                $policy.account_lockout.lockout_threshold = [int]$matches[1]
                $policy.account_lockout.configured = $true
            }
            elseif ($line -match '^LockoutDuration\s*=\s*(-?\d+)') {
                $policy.account_lockout.lockout_duration = [int]$matches[1]
            }
            elseif ($line -match '^ResetLockoutCount\s*=\s*(\d+)') {
                $policy.account_lockout.lockout_window = [int]$matches[1]
            }
            # Password policy settings
            elseif ($line -match '^MinimumPasswordLength\s*=\s*(\d+)') {
                $policy.password_policy.min_password_length = [int]$matches[1]
                $policy.password_policy.configured = $true
            }
            elseif ($line -match '^PasswordComplexity\s*=\s*(\d+)') {
                $policy.password_policy.password_complexity = [int]$matches[1]
            }
            elseif ($line -match '^MinimumPasswordAge\s*=\s*(\d+)') {
                $policy.password_policy.min_password_age = [int]$matches[1]
            }
            elseif ($line -match '^MaximumPasswordAge\s*=\s*(\d+)') {
                $policy.password_policy.max_password_age = [int]$matches[1]
            }
            elseif ($line -match '^PasswordHistorySize\s*=\s*(\d+)') {
                $policy.password_policy.password_history = [int]$matches[1]
            }
            elseif ($line -match '^ClearTextPassword\s*=\s*(\d+)') {
                $policy.password_policy.reversible_encryption = [int]$matches[1]
            }
        }

        # Add compliance assessment flags
        $policy | Add-Member -NotePropertyName 'compliance' -NotePropertyValue ([PSCustomObject]@{
            nist_3_1_8_lockout_configured = ($policy.account_lockout.lockout_threshold -gt 0 -and $policy.account_lockout.lockout_threshold -le 10)
            nist_3_5_7_password_length_ok = ($policy.password_policy.min_password_length -ge 8)
            nist_3_5_7_password_length_recommended = ($policy.password_policy.min_password_length -ge 14)
            nist_3_5_7_complexity_enabled = ($policy.password_policy.password_complexity -eq 1)
            overall_compliant = $false
        })

        # Calculate overall compliance
        $policy.compliance.overall_compliant = (
            $policy.compliance.nist_3_1_8_lockout_configured -and
            $policy.compliance.nist_3_5_7_password_length_ok -and
            $policy.compliance.nist_3_5_7_complexity_enabled
        )

        Write-Verbose "Exporting to JSON: $OutputPath"

        # Export as JSON
        $json = $policy | ConvertTo-Json -Depth 5 -Compress
        Set-Content -Path $OutputPath -Value $json -Encoding UTF8 -Force

        Write-Verbose "Security policy exported successfully"

        # Output summary for logging
        Write-Output @"
Security Policy Export Complete
================================
Timestamp: $($policy.metadata.timestamp)
Hostname: $($policy.metadata.hostname)
Output: $OutputPath

Account Lockout:
  Threshold: $($policy.account_lockout.lockout_threshold)
  Duration: $($policy.account_lockout.lockout_duration) minutes
  Window: $($policy.account_lockout.lockout_window) minutes
  NIST 3.1.8 Compliant: $($policy.compliance.nist_3_1_8_lockout_configured)

Password Policy:
  Min Length: $($policy.password_policy.min_password_length)
  Complexity: $($policy.password_policy.password_complexity)
  NIST 3.5.7 Compliant: $($policy.compliance.nist_3_5_7_password_length_ok -and $policy.compliance.nist_3_5_7_complexity_enabled)

Overall Compliance: $($policy.compliance.overall_compliant)
"@

    }
    catch {
        Write-Error "Failed to export security policy: $_"
        throw
    }
    finally {
        # Cleanup temporary files
        if (Test-Path $tempCfg) {
            Remove-Item $tempCfg -Force -ErrorAction SilentlyContinue
        }
    }
}

end {
    Write-Verbose "Export process completed."
}
