# Quick NIST 800-171 Compliance Check Example
# This script demonstrates basic usage of the NIST800171Compliance module

# Import the module
Import-Module "$PSScriptRoot\..\NIST800171Compliance" -Force

# Example 1: Quick compliance check with console output
Write-Host "`n=== Example 1: Quick Compliance Check ===" -ForegroundColor Cyan
$compliance = Get-NISTCompliance -Verbose
Export-NISTReport -ComplianceData $compliance -Format Console

# Example 2: Full assessment with HTML report
Write-Host "`n=== Example 2: Generate HTML Report ===" -ForegroundColor Cyan
$compliance = Get-NISTCompliance
Export-NISTReport -ComplianceData $compliance -OutputPath ".\NIST_Compliance_Report.html" -Format HTML

# Example 3: Check specific control family
Write-Host "`n=== Example 3: Check Access Control (3.1) Only ===" -ForegroundColor Cyan
$accessControl = Get-NISTCompliance -ControlFamily "3.1" -IncludeEvidence
Export-NISTReport -ComplianceData $accessControl -Format Console

# Example 4: Get Windows Security Policy details
Write-Host "`n=== Example 4: View Security Policy Settings ===" -ForegroundColor Cyan
$policy = Get-WindowsSecurityPolicy
Write-Host "Password Policies:" -ForegroundColor Yellow
$policy.PasswordPolicies | Format-List

Write-Host "`nAccount Lockout Policies:" -ForegroundColor Yellow
$policy.AccountLockoutPolicies | Format-List

# Example 5: Export to JSON for integration with other tools
Write-Host "`n=== Example 5: Export JSON for API Integration ===" -ForegroundColor Cyan
$compliance = Get-NISTCompliance
Export-NISTReport -ComplianceData $compliance -OutputPath ".\compliance.json" -Format JSON

# Example 6: Export to CSV for spreadsheet analysis
Write-Host "`n=== Example 6: Export CSV for Analysis ===" -ForegroundColor Cyan
Export-NISTReport -ComplianceData $compliance -OutputPath ".\compliance.csv" -Format CSV

Write-Host "`n=== All Examples Completed ===" -ForegroundColor Green
Write-Host "Check the current directory for generated reports.`n"
