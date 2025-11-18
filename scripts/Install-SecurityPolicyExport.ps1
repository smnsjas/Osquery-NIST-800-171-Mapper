#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs scheduled task to export Windows security policy for osquery.

.DESCRIPTION
    Creates a Windows scheduled task that runs Export-SecurityPolicy.ps1 every hour,
    making policy data available to osquery via the file table.

.PARAMETER ScriptPath
    Path to Export-SecurityPolicy.ps1 script.

.PARAMETER IntervalHours
    How often to run the export (in hours). Default: 1

.EXAMPLE
    .\Install-SecurityPolicyExport.ps1

.EXAMPLE
    .\Install-SecurityPolicyExport.ps1 -IntervalHours 2
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$ScriptPath = "C:\Scripts\Export-SecurityPolicy.ps1",

    [Parameter()]
    [ValidateRange(1, 24)]
    [int]$IntervalHours = 1
)

begin {
    Write-Host "Installing Security Policy Export Task" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host ""
}

process {
    try {
        # Ensure script exists or copy it
        if (-not (Test-Path $ScriptPath)) {
            Write-Host "Script not found at: $ScriptPath" -ForegroundColor Yellow

            # Create directory
            $scriptDir = Split-Path -Path $ScriptPath -Parent
            if (-not (Test-Path $scriptDir)) {
                Write-Host "Creating directory: $scriptDir" -ForegroundColor Yellow
                New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null
            }

            # Copy from current directory if available
            $localScript = Join-Path -Path $PSScriptRoot -ChildPath "Export-SecurityPolicy.ps1"
            if (Test-Path $localScript) {
                Write-Host "Copying script to: $ScriptPath" -ForegroundColor Green
                Copy-Item -Path $localScript -Destination $ScriptPath -Force
            } else {
                throw "Export-SecurityPolicy.ps1 not found. Please specify -ScriptPath"
            }
        }

        Write-Host "[1/4] Creating scheduled task action..." -ForegroundColor Yellow

        # Create task action
        $action = New-ScheduledTaskAction `
            -Execute "PowerShell.exe" `
            -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$ScriptPath`""

        Write-Host "  ✓ Action created" -ForegroundColor Green

        Write-Host "[2/4] Creating scheduled task trigger..." -ForegroundColor Yellow

        # Create trigger - run immediately, then repeat every X hours
        $trigger = New-ScheduledTaskTrigger `
            -Once `
            -At (Get-Date).AddMinutes(1) `
            -RepetitionInterval (New-TimeSpan -Hours $IntervalHours)

        Write-Host "  ✓ Trigger created (every $IntervalHours hour(s))" -ForegroundColor Green

        Write-Host "[3/4] Configuring task principal..." -ForegroundColor Yellow

        # Run as SYSTEM with highest privileges
        $principal = New-ScheduledTaskPrincipal `
            -UserId "SYSTEM" `
            -LogonType ServiceAccount `
            -RunLevel Highest

        Write-Host "  ✓ Principal configured (SYSTEM)" -ForegroundColor Green

        Write-Host "[4/4] Registering scheduled task..." -ForegroundColor Yellow

        # Task settings
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -StartWhenAvailable `
            -RunOnlyIfNetworkAvailable:$false `
            -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

        # Register task
        $taskName = "Export Security Policy for osquery"

        if ($PSCmdlet.ShouldProcess($taskName, "Register scheduled task")) {
            # Remove existing task if present
            $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
            if ($existingTask) {
                Write-Host "  Removing existing task..." -ForegroundColor Yellow
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            }

            # Register new task
            Register-ScheduledTask `
                -TaskName $taskName `
                -Action $action `
                -Trigger $trigger `
                -Principal $principal `
                -Settings $settings `
                -Description "Exports Windows security policy to JSON for osquery consumption (NIST 800-171 compliance monitoring)" | Out-Null

            Write-Host "  ✓ Task registered successfully" -ForegroundColor Green
        }

        Write-Host ""
        Write-Host "Installation Complete!" -ForegroundColor Green
        Write-Host "=====================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Task Name: $taskName" -ForegroundColor Cyan
        Write-Host "Script: $ScriptPath" -ForegroundColor Cyan
        Write-Host "Interval: Every $IntervalHours hour(s)" -ForegroundColor Cyan
        Write-Host "Output: C:\ProgramData\osquery\security_policy.json" -ForegroundColor Cyan
        Write-Host ""

        # Run immediately for testing
        Write-Host "Running initial export..." -ForegroundColor Yellow
        Start-ScheduledTask -TaskName $taskName
        Start-Sleep -Seconds 3

        # Check if output file was created
        $outputFile = "C:\ProgramData\osquery\security_policy.json"
        if (Test-Path $outputFile) {
            Write-Host "✓ Export successful! File created: $outputFile" -ForegroundColor Green

            # Show file contents
            $policyData = Get-Content $outputFile | ConvertFrom-Json
            Write-Host ""
            Write-Host "Current Policy Settings:" -ForegroundColor Cyan
            Write-Host "  Lockout Threshold: $($policyData.account_lockout.lockout_threshold)" -ForegroundColor White
            Write-Host "  Min Password Length: $($policyData.password_policy.min_password_length)" -ForegroundColor White
            Write-Host "  Password Complexity: $($policyData.password_policy.password_complexity)" -ForegroundColor White
            Write-Host "  Overall Compliant: $($policyData.compliance.overall_compliant)" -ForegroundColor $(if ($policyData.compliance.overall_compliant) { 'Green' } else { 'Red' })
        } else {
            Write-Warning "Export file not created. Check task history for errors."
        }

        Write-Host ""
        Write-Host "Next Steps:" -ForegroundColor Yellow
        Write-Host "  1. Verify osquery is installed" -ForegroundColor White
        Write-Host "  2. Add policy queries to osquery packs (see packs/ directory)" -ForegroundColor White
        Write-Host "  3. Test with: osqueryi 'SELECT * FROM file WHERE path LIKE `"%security_policy.json%`"'" -ForegroundColor White
        Write-Host ""

    }
    catch {
        Write-Error "Failed to install scheduled task: $_"
        throw
    }
}

end {
    Write-Host "Setup completed." -ForegroundColor Cyan
}
