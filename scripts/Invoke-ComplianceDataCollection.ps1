#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Collects Windows security compliance data for NIST 800-171 assessment.

.DESCRIPTION
    This script serves as the single source of truth for data collection.
    1. Exports local security policy using secedit.exe
    2. Parses the policy into a structured object
    3. Calculates compliance status for supported controls
    4. Saves output to JSON for consumption by:
       - osquery (via file table)
       - Local PowerShell compliance module

.PARAMETER OutputPath
    Path where JSON output will be written. Default: C:\ProgramData\osquery\nist_compliance_data.json

.EXAMPLE
    .\Invoke-ComplianceDataCollection.ps1
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath = "C:\ProgramData\osquery\nist_compliance_data.json"
)

begin {
    # Verify admin privileges
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This script requires Administrator privileges."
    }

    Write-Verbose "Starting compliance data collection..."
}

process {
    try {
        # Ensure output directory exists
        $outputDir = Split-Path -Path $OutputPath -Parent
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # --- Step 1: Export Security Policy ---
        $tempCfg = "$env:TEMP\secpol_export_$(Get-Date -Format 'yyyyMMddHHmmss').cfg"
        Write-Verbose "Exporting security policy to $tempCfg..."

        $seceditArgs = @('/export', '/cfg', $tempCfg, '/quiet')
        $process = Start-Process -FilePath 'secedit.exe' -ArgumentList $seceditArgs `
            -NoNewWindow -Wait -PassThru

        if ($process.ExitCode -ne 0) {
            throw "secedit.exe failed with exit code: $($process.ExitCode)"
        }

        # --- Step 2: Parse Configuration ---
        Write-Verbose "Parsing configuration..."
        $content = Get-Content -Path $tempCfg -Encoding Unicode
        
        # Initialize data structure (matches osquery pack expectations)
        $data = [PSCustomObject]@{
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
            # Store raw parsed sections for advanced usage
            raw_policy = @{}
            metadata = [PSCustomObject]@{
                timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                hostname = $env:COMPUTERNAME
                version = "2.0"
            }
        }

        $currentSection = $null

        foreach ($line in $content) {
            $line = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith(';')) { continue }

            if ($line -match '^\[(.+)\]$') {
                $currentSection = $matches[1]
                $data.raw_policy[$currentSection] = @{}
                continue
            }

            if ($line -match '^(.+?)\s*=\s*(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()

                # Store in raw policy
                if ($currentSection) {
                    $data.raw_policy[$currentSection][$key] = $value
                }

                # Map specific fields for osquery compatibility
                if ($key -eq 'LockoutBadCount') {
                    $data.account_lockout.lockout_threshold = [int]$value
                    $data.account_lockout.configured = $true
                }
                elseif ($key -eq 'LockoutDuration') { $data.account_lockout.lockout_duration = [int]$value }
                elseif ($key -eq 'ResetLockoutCount') { $data.account_lockout.lockout_window = [int]$value }
                elseif ($key -eq 'MinimumPasswordLength') { 
                    $data.password_policy.min_password_length = [int]$value 
                    $data.password_policy.configured = $true
                }
                elseif ($key -eq 'PasswordComplexity') { $data.password_policy.password_complexity = [int]$value }
                elseif ($key -eq 'MinimumPasswordAge') { $data.password_policy.min_password_age = [int]$value }
                elseif ($key -eq 'MaximumPasswordAge') { $data.password_policy.max_password_age = [int]$value }
                elseif ($key -eq 'PasswordHistorySize') { $data.password_policy.password_history = [int]$value }
                elseif ($key -eq 'ClearTextPassword') { $data.password_policy.reversible_encryption = [int]$value }
            }
        }

        # --- Step 3: Assess Compliance ---
        # Logic moved from Export-SecurityPolicy.ps1
        $data | Add-Member -NotePropertyName 'compliance' -NotePropertyValue ([PSCustomObject]@{
            nist_3_1_8_lockout_configured = ($data.account_lockout.lockout_threshold -gt 0 -and $data.account_lockout.lockout_threshold -le 10)
            nist_3_5_7_password_length_ok = ($data.password_policy.min_password_length -ge 8)
            nist_3_5_7_password_length_recommended = ($data.password_policy.min_password_length -ge 14)
            nist_3_5_7_complexity_enabled = ($data.password_policy.password_complexity -eq 1)
            overall_compliant = $false
        })

        $data.compliance.overall_compliant = (
            $data.compliance.nist_3_1_8_lockout_configured -and
            $data.compliance.nist_3_5_7_password_length_ok -and
            $data.compliance.nist_3_5_7_complexity_enabled
        )

        # --- Step 4: Save Output ---
        Write-Verbose "Saving to $OutputPath..."
        $json = $data | ConvertTo-Json -Depth 5 -Compress
        Set-Content -Path $OutputPath -Value $json -Encoding UTF8 -Force

        Write-Output "Data collection complete. Saved to $OutputPath"
        Write-Output "Compliance Score: $(if($data.compliance.overall_compliant){'PASS'}else{'FAIL'})"

    }
    catch {
        Write-Error "Data collection failed: $_"
        throw
    }
    finally {
        if (Test-Path $tempCfg) { Remove-Item $tempCfg -Force -ErrorAction SilentlyContinue }
    }
}
