# NIST 800-171 Compliance Module for Windows
# PowerShell module for checking NIST SP 800-171 Rev 2 compliance using osquery results

# Import all public and private functions
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.Basename

# Module variables
$script:ModuleRoot = $PSScriptRoot
$script:MappingsPath = Join-Path (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) "mappings\nist800171_mapping.yaml"
