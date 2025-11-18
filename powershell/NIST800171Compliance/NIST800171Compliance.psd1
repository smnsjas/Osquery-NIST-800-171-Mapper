@{
    # Module information
    RootModule = 'NIST800171Compliance.psm1'
    ModuleVersion = '1.0.0'
    GUID = '8f4a7c3e-2b5d-4e9a-8c1f-6d3e5b7a9c2f'
    Author = 'NIST 800-171 Compliance Team'
    CompanyName = 'Open Source'
    Copyright = '(c) 2025. MIT License.'
    Description = 'PowerShell module for assessing NIST SP 800-171 Rev 2 compliance on Windows systems using osquery results and native Windows tools.'

    # Minimum PowerShell version
    PowerShellVersion = '5.1'

    # Compatible editions
    CompatiblePSEditions = @('Desktop', 'Core')

    # Supported OS
    # WindowsPowerShellCompatible = $true

    # Functions to export
    FunctionsToExport = @(
        'Get-NISTCompliance',
        'Get-NISTControlStatus',
        'Export-NISTReport',
        'Test-NISTControl',
        'Get-WindowsSecurityPolicy'
    )

    # Cmdlets to export
    CmdletsToExport = @()

    # Variables to export
    VariablesToExport = @()

    # Aliases to export
    AliasesToExport = @()

    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('NIST', '800-171', 'Compliance', 'Security', 'osquery', 'Windows', 'Audit')
            LicenseUri = 'https://github.com/your-org/osquery-nist-mapper/blob/main/LICENSE'
            ProjectUri = 'https://github.com/your-org/osquery-nist-mapper'
            ReleaseNotes = @'
# Version 1.0.0
- Initial release
- Support for NIST SP 800-171 Rev 2 compliance checking
- Integration with osquery results
- Native Windows policy parsing (secedit)
- Multiple report formats (JSON, HTML, CSV)
'@
        }
    }
}
