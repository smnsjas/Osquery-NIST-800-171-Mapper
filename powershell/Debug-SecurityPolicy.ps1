#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Debug script to check what security policies the module is detecting.

.DESCRIPTION
    This script shows the raw policy data being collected by the NIST compliance
    module to help diagnose why GPO-configured policies might not be detected.
#>

Write-Host "=== Security Policy Diagnostic ===" -ForegroundColor Cyan
Write-Host ""

# Import the module
Import-Module "$PSScriptRoot\NIST800171Compliance" -Force

Write-Host "[1] Checking Windows Security Policy via secedit..." -ForegroundColor Yellow
Write-Host ""

try {
    $policy = Get-WindowsSecurityPolicy -Verbose

    Write-Host "Raw SystemAccess Section:" -ForegroundColor Green
    $policy.SystemAccess | Format-Table -AutoSize

    Write-Host "`nParsed Password Policies:" -ForegroundColor Green
    $policy.PasswordPolicies | Format-List

    Write-Host "`nParsed Account Lockout Policies:" -ForegroundColor Green
    $policy.AccountLockoutPolicies | Format-List

} catch {
    Write-Error "Failed to get security policy: $_"
}

Write-Host "`n[2] Checking via net accounts..." -ForegroundColor Yellow
Write-Host ""
net accounts

Write-Host "`n[3] Checking registry for GPO-applied policies..." -ForegroundColor Yellow
Write-Host ""

# Check common GPO registry locations
$regPaths = @(
    @{
        Name = "Account Policies"
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    },
    @{
        Name = "Security Options"
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    }
)

foreach ($reg in $regPaths) {
    Write-Host "$($reg.Name): $($reg.Path)" -ForegroundColor Cyan
    if (Test-Path $reg.Path) {
        Get-ItemProperty $reg.Path -ErrorAction SilentlyContinue | Format-List
    } else {
        Write-Host "  Path not found" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "[4] Checking if system is domain-joined..." -ForegroundColor Yellow
Write-Host ""

$computerSystem = Get-WmiObject -Class Win32_ComputerSystem
Write-Host "Domain: $($computerSystem.Domain)"
Write-Host "Part of Domain: $($computerSystem.PartOfDomain)"

if ($computerSystem.PartOfDomain) {
    Write-Host "`nNote: Domain-joined systems receive policies from Group Policy." -ForegroundColor Yellow
    Write-Host "Run 'gpresult /h gpreport.html' to see applied GPOs." -ForegroundColor Yellow
}

Write-Host "`n[5] Exporting raw secedit output for inspection..." -ForegroundColor Yellow
Write-Host ""

$tempCfg = "$env:TEMP\secedit_debug_$(Get-Date -Format 'yyyyMMddHHmmss').cfg"
secedit /export /cfg $tempCfg /quiet

if (Test-Path $tempCfg) {
    Write-Host "Raw secedit export saved to: $tempCfg" -ForegroundColor Green
    Write-Host "`n[System Access] Section:" -ForegroundColor Cyan
    Get-Content $tempCfg | Select-String -Pattern "^\[System Access\]" -Context 0,20

    Write-Host "`nKey Values:" -ForegroundColor Cyan
    Get-Content $tempCfg | Select-String -Pattern "(MinimumPasswordLength|PasswordComplexity|LockoutBadCount|LockoutDuration|ResetLockoutCount)"

    Write-Host "`nFull file contents available at: $tempCfg" -ForegroundColor Yellow
} else {
    Write-Error "Failed to export secedit configuration"
}

Write-Host "`n=== Diagnostic Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "If policies show as 0 or not set, but you know they're configured:" -ForegroundColor Yellow
Write-Host "  1. Check Group Policy is applying: gpupdate /force" -ForegroundColor White
Write-Host "  2. Review GPO settings: gpresult /h gpreport.html" -ForegroundColor White
Write-Host "  3. Verify effective policy: Get-WindowsSecurityPolicy" -ForegroundColor White
Write-Host "  4. Check parse-secedit logic in module" -ForegroundColor White
