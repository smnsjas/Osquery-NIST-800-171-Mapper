function Get-ControlMapping {
    <#
    .SYNOPSIS
        Loads NIST 800-171 control mappings from YAML file.

    .DESCRIPTION
        Parses the nist800171_mapping.yaml file and returns control definitions.
        Requires PowerShell-Yaml module or uses basic parsing for simple YAML.

    .PARAMETER Path
        Path to mappings YAML file.

    .PARAMETER ControlFamily
        Optional filter for specific control family (e.g., "3.1").

    .OUTPUTS
        PSCustomObject with control mappings
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [string]$Path,

        [Parameter()]
        [string]$ControlFamily
    )

    try {
        Write-Verbose "Loading control mappings from: $Path"

        # Try to use PowerShell-Yaml if available
        $yamlModule = Get-Module -ListAvailable -Name 'powershell-yaml' | Select-Object -First 1

        if ($yamlModule) {
            Import-Module 'powershell-yaml' -ErrorAction Stop
            $content = Get-Content -Path $Path -Raw
            $mappings = ConvertFrom-Yaml -Yaml $content

            # Filter by control family if specified
            if ($ControlFamily) {
                $mappings.controls = $mappings.controls | Where-Object {
                    $_.control_id -like "$ControlFamily.*"
                }
            }

            return $mappings
        }
        else {
            Write-Warning "PowerShell-Yaml module not found. Using basic YAML parsing."
            Write-Warning "For full functionality, install: Install-Module -Name powershell-yaml"

            # Basic YAML parsing for our specific structure
            return Parse-BasicYaml -Path $Path -ControlFamily $ControlFamily
        }
    }
    catch {
        Write-Error "Failed to load control mappings: $_"
        throw
    }
}

function Parse-BasicYaml {
    <#
    .SYNOPSIS
        Basic YAML parser for control mappings (fallback when powershell-yaml not available).
    #>

    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$ControlFamily
    )

    $content = Get-Content -Path $Path
    $controls = @()
    $currentControl = $null
    $inControlBlock = $false

    foreach ($line in $content) {
        $trimmed = $line.TrimStart()

        # Detect new control
        if ($trimmed -match '^\s*- control_id:\s*"(.+)"') {
            if ($currentControl) {
                # Apply filter if needed
                if (-not $ControlFamily -or $currentControl.control_id -like "$ControlFamily.*") {
                    $controls += $currentControl
                }
            }

            $currentControl = [PSCustomObject]@{
                control_id = $matches[1]
                control_title = ""
                control_family = ""
                automation_level = ""
                queries = @()
            }
            $inControlBlock = $true
        }
        elseif ($inControlBlock) {
            if ($trimmed -match 'control_title:\s*"(.+)"') {
                $currentControl.control_title = $matches[1]
            }
            elseif ($trimmed -match 'control_family:\s*"(.+)"') {
                $currentControl.control_family = $matches[1]
            }
            elseif ($trimmed -match 'automation_level:\s*"(.+)"') {
                $currentControl.automation_level = $matches[1]
            }
            elseif ($trimmed -match 'query_name:\s*"(.+)"') {
                $currentControl.queries += @{query_name = $matches[1]}
            }
        }
    }

    # Add last control
    if ($currentControl) {
        if (-not $ControlFamily -or $currentControl.control_id -like "$ControlFamily.*") {
            $controls += $currentControl
        }
    }

    return [PSCustomObject]@{
        version = "1.0.0"
        controls = $controls
    }
}
