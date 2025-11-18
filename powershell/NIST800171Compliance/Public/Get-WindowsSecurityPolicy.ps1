function Get-WindowsSecurityPolicy {
    <#
    .SYNOPSIS
        Retrieves Windows local security policy settings using secedit.

    .DESCRIPTION
        Exports local security policy to a temporary file using secedit.exe and parses
        the configuration into a PowerShell object. This provides access to password
        policies, account lockout policies, and other SAM-based security settings that
        are not easily accessible via registry queries.

    .EXAMPLE
        $policy = Get-WindowsSecurityPolicy
        $policy.SystemAccess.MinimumPasswordLength

    .EXAMPLE
        Get-WindowsSecurityPolicy | Select-Object -ExpandProperty SystemAccess

    .OUTPUTS
        PSCustomObject with security policy settings
    #>

    [CmdletBinding()]
    param()

    begin {
        # Require elevated privileges
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw "This function requires elevated (Administrator) privileges to export security policy."
        }
    }

    process {
        try {
            # Create temporary file for secedit output
            $tempFile = [System.IO.Path]::GetTempFileName()
            $configFile = $tempFile -replace '\.tmp$', '.cfg'
            Move-Item $tempFile $configFile -Force

            Write-Verbose "Exporting security policy to: $configFile"

            # Export security policy using secedit
            $seceditArgs = @(
                '/export',
                '/cfg', $configFile,
                '/quiet'
            )

            $process = Start-Process -FilePath 'secedit.exe' -ArgumentList $seceditArgs `
                -NoNewWindow -Wait -PassThru -RedirectStandardError ([System.IO.Path]::GetTempFileName())

            if ($process.ExitCode -ne 0) {
                throw "secedit.exe failed with exit code: $($process.ExitCode)"
            }

            if (-not (Test-Path $configFile)) {
                throw "Security policy export file not created: $configFile"
            }

            # Parse the configuration file
            Write-Verbose "Parsing security policy configuration..."
            $policyObject = Parse-SeceditOutput -Path $configFile

            # Also get some settings via net accounts (provides a quick check)
            try {
                $netAccounts = net accounts 2>$null
                $policyObject | Add-Member -NotePropertyName 'NetAccountsRaw' -NotePropertyValue $netAccounts -Force
            }
            catch {
                Write-Verbose "Unable to retrieve net accounts output: $_"
            }

            return $policyObject
        }
        catch {
            Write-Error "Failed to retrieve Windows security policy: $_"
            throw
        }
        finally {
            # Cleanup temporary files
            if (Test-Path $configFile) {
                Remove-Item $configFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
