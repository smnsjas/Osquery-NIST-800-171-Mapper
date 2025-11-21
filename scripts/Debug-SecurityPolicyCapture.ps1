#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Diagnoses why security policy data may not be captured correctly.

.DESCRIPTION
    Tests Get-WindowsSecurityPolicy and Export-SecurityPolicy.ps1 to identify
    why password and lockout policies might not be appearing in compliance reports.
#>

[CmdletBinding()]
param()

Write-Host "Security Policy Diagnostic Tool" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check if running as admin
Write-Host "[1/5] Checking Administrator privileges..." -ForegroundColor Yellow
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "  ✓ Running as Administrator" -ForegroundColor Green
} else {
    Write-Host "  ✗ NOT running as Administrator" -ForegroundColor Red
    Write-Host "    → Re-run PowerShell as Administrator" -ForegroundColor Yellow
    exit 1
}

# Test 2: Check if secedit.exe exists
Write-Host "[2/5] Checking secedit.exe availability..." -ForegroundColor Yellow
$seceditPath = "$env:SystemRoot\System32\secedit.exe"
if (Test-Path $seceditPath) {
    Write-Host "  ✓ secedit.exe found: $seceditPath" -ForegroundColor Green
} else {
    Write-Host "  ✗ secedit.exe not found" -ForegroundColor Red
    exit 1
}

# Test 3: Try running secedit manually
Write-Host "[3/5] Testing secedit export..." -ForegroundColor Yellow
$tempCfg = "$env:TEMP\secpol_test.cfg"
try {
    $result = & secedit.exe /export /cfg $tempCfg /quiet 2>&1
    
    if (Test-Path $tempCfg) {
        Write-Host "  ✓ secedit export successful" -ForegroundColor Green
        $content = Get-Content $tempCfg -Encoding Unicode
        
        # Check for key settings
        $hasLockout = $content | Where-Object { $_ -match 'LockoutBadCount' }
        $hasPassword = $content | Where-Object { $_ -match 'MinimumPasswordLength' }
        
        if ($hasLockout) {
            Write-Host "    ✓ Lockout policy found in export" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Lockout policy NOT found" -ForegroundColor Yellow
        }
        
        if ($hasPassword) {
            Write-Host "    ✓ Password policy found in export" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Password policy NOT found" -ForegroundColor Yellow
        }
        
        Remove-Item $tempCfg -Force
    } else {
        Write-Host "  ✗ secedit export failed" -ForegroundColor Red
        Write-Host "    Output: $result" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  ✗ secedit error: $_" -ForegroundColor Red
}

# Test 4: Try Get-WindowsSecurityPolicy
Write-Host "[4/5] Testing Get-WindowsSecurityPolicy..." -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\..\powershell\NIST800171Compliance\NIST800171Compliance.psd1" -Force
    
    $policy = Get-WindowsSecurityPolicy -Verbose
    
    if ($policy) {
        Write-Host "  ✓ Get-WindowsSecurityPolicy succeeded" -ForegroundColor Green
        
        Write-Host "    Password Policy:" -ForegroundColor Cyan
        Write-Host "      Min Length: $($policy.PasswordPolicies.MinimumPasswordLength)" -ForegroundColor White
        Write-Host "      Complexity: $($policy.PasswordPolicies.PasswordComplexity)" -ForegroundColor White
        
        Write-Host "    Lockout Policy:" -ForegroundColor Cyan
        Write-Host "      Bad Count: $($policy.AccountLockoutPolicies.LockoutBadCount)" -ForegroundColor White
        Write-Host "      Duration: $($policy.AccountLockoutPolicies.LockoutDuration)" -ForegroundColor White
    } else {
        Write-Host "  ✗ Get-WindowsSecurityPolicy returned null" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ✗ Get-WindowsSecurityPolicy failed: $_" -ForegroundColor Red
}

# Test 5: Check for Export-SecurityPolicy scheduled task
Write-Host "[5/5] Checking scheduled task..." -ForegroundColor Yellow
$task = Get-ScheduledTask -TaskName "Export Security Policy for osquery" -ErrorAction SilentlyContinue

if ($task) {
    Write-Host "  ✓ Scheduled task exists" -ForegroundColor Green
    Write-Host "    State: $($task.State)" -ForegroundColor Cyan
    
    # Check if JSON file exists
    $jsonFile = "C:\ProgramData\osquery\security_policy.json"
    if (Test-Path $jsonFile) {
        Write-Host "  ✓ JSON export file exists: $jsonFile" -ForegroundColor Green
        $json = Get-Content $jsonFile | ConvertFrom-Json
        Write-Host "    Timestamp: $($json.metadata.timestamp)" -ForegroundColor Cyan
        Write-Host "    Lockout Threshold: $($json.account_lockout.lockout_threshold)" -ForegroundColor Cyan
        Write-Host "    Min Password Length: $($json.password_policy.min_password_length)" -ForegroundColor Cyan
    } else {
        Write-Host "  ✗ JSON export file not found" -ForegroundColor Yellow
        Write-Host "    → Run: .\Install-SecurityPolicyExport.ps1" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✗ Scheduled task not installed" -ForegroundColor Yellow
    Write-Host "    → Run: .\Install-SecurityPolicyExport.ps1" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Diagnosis Complete" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
