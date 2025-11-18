function Parse-SeceditOutput {
    <#
    .SYNOPSIS
        Parses secedit.exe output file into PowerShell object.

    .DESCRIPTION
        Reads a secedit configuration file and converts it into a structured
        PowerShell object with properties for each policy section.

    .PARAMETER Path
        Path to secedit output file (.cfg or .inf format).

    .OUTPUTS
        PSCustomObject with policy sections
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [string]$Path
    )

    try {
        $content = Get-Content -Path $Path -Encoding Unicode
        $policyObject = [PSCustomObject]@{
            SystemAccess = @{}
            EventAudit = @{}
            RegistryValues = @{}
            PrivilegeRights = @{}
            ServiceGeneral = @{}
            Other = @{}
        }

        $currentSection = $null

        foreach ($line in $content) {
            $line = $line.Trim()

            # Skip empty lines and comments
            if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith(';')) {
                continue
            }

            # Check for section headers
            if ($line -match '^\[(.+)\]$') {
                $currentSection = $matches[1]
                Write-Verbose "Parsing section: $currentSection"
                continue
            }

            # Parse key-value pairs
            if ($line -match '^(.+?)\s*=\s*(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()

                # Map sections to properties
                switch ($currentSection) {
                    'System Access' {
                        # Parse numeric values
                        if ($value -match '^\d+$') {
                            $policyObject.SystemAccess[$key] = [int]$value
                        } else {
                            $policyObject.SystemAccess[$key] = $value
                        }
                    }
                    'Event Audit' {
                        $policyObject.EventAudit[$key] = $value
                    }
                    'Registry Values' {
                        $policyObject.RegistryValues[$key] = $value
                    }
                    'Privilege Rights' {
                        # Parse SID lists
                        $policyObject.PrivilegeRights[$key] = $value -split ','
                    }
                    'Service General Setting' {
                        $policyObject.ServiceGeneral[$key] = $value
                    }
                    default {
                        if (-not $policyObject.Other.ContainsKey($currentSection)) {
                            $policyObject.Other[$currentSection] = @{}
                        }
                        $policyObject.Other[$currentSection][$key] = $value
                    }
                }
            }
        }

        # Add human-readable property names for common settings
        $policyObject | Add-Member -NotePropertyName 'PasswordPolicies' -NotePropertyValue ([PSCustomObject]@{
            MinimumPasswordLength = $policyObject.SystemAccess['MinimumPasswordLength']
            PasswordComplexity = $policyObject.SystemAccess['PasswordComplexity']
            MinimumPasswordAge = $policyObject.SystemAccess['MinimumPasswordAge']
            MaximumPasswordAge = $policyObject.SystemAccess['MaximumPasswordAge']
            PasswordHistorySize = $policyObject.SystemAccess['PasswordHistorySize']
            ClearTextPassword = $policyObject.SystemAccess['ClearTextPassword']
        }) -Force

        $policyObject | Add-Member -NotePropertyName 'AccountLockoutPolicies' -NotePropertyValue ([PSCustomObject]@{
            LockoutBadCount = $policyObject.SystemAccess['LockoutBadCount']
            LockoutDuration = $policyObject.SystemAccess['LockoutDuration']
            ResetLockoutCount = $policyObject.SystemAccess['ResetLockoutCount']
        }) -Force

        return $policyObject
    }
    catch {
        Write-Error "Failed to parse secedit output: $_"
        throw
    }
}
