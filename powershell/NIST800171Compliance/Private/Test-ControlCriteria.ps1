function Test-ControlCriteria {
    <#
    .SYNOPSIS
        Tests compliance criteria for a specific NIST control.

    .DESCRIPTION
        Evaluates control compliance by checking osquery results and/or
        Windows security policies against expected criteria.

    .PARAMETER Control
        Control object from mappings file.

    .PARAMETER OsqueryData
        Parsed osquery results hashtable.

    .PARAMETER SecurityPolicy
        Windows security policy object from secedit.

    .PARAMETER IncludeEvidence
        Include raw evidence in output.

    .OUTPUTS
        PSCustomObject with control assessment result
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Control,

        [Parameter()]
        [hashtable]$OsqueryData,

        [Parameter()]
        [PSCustomObject]$SecurityPolicy,

        [Parameter()]
        [switch]$IncludeEvidence
    )

    $assessment = [PSCustomObject]@{
        ControlId = $Control.control_id
        ControlTitle = $Control.control_title
        ControlFamily = $Control.control_family
        AutomationLevel = $Control.automation_level
        Status = "NotAssessed"
        Severity = "Medium"
        Findings = @()
        Recommendations = @()
        Evidence = $null
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    try {
        # Check if this is a SAM policy-based control (password/lockout)
        if ($Control.control_id -eq "3.1.8") {
            # Account Lockout Policy
            $assessment.Status = Test-AccountLockoutPolicy -SecurityPolicy $SecurityPolicy -Assessment $assessment -OsqueryData $OsqueryData
        }
        elseif ($Control.control_id -eq "3.5.7") {
            # Password Complexity Policy
            $assessment.Status = Test-PasswordPolicy -SecurityPolicy $SecurityPolicy -Assessment $assessment -OsqueryData $OsqueryData
        }
        elseif ($Control.queries) {
            # osquery-based controls
            if ($null -eq $OsqueryData) {
                $assessment.Status = "NotAssessed"
                $assessment.Findings += "osquery results not available"
                return $assessment
            }

            $assessment.Status = Test-OsqueryControl -Control $Control -OsqueryData $OsqueryData -Assessment $assessment
        }
        else {
            $assessment.Status = "NotAssessed"
            $assessment.Findings += "No automated assessment criteria defined"
        }

        # Add evidence if requested
        if ($IncludeEvidence) {
            $evidence = @{}

            # Include relevant osquery results
            if ($Control.queries) {
                foreach ($query in $Control.queries) {
                    $queryName = $query.query_name
                    if ($OsqueryData.ContainsKey($queryName)) {
                        $evidence[$queryName] = $OsqueryData[$queryName].Results
                    }
                }
            }

            # Include relevant security policy settings
            # Prefer JSON file data from osquery if available, fall back to local SecurityPolicy
            if ($Control.control_id -eq "3.1.8") {
                if ($OsqueryData -and $OsqueryData.ContainsKey('ac_lockout_policy_file') -and $OsqueryData['ac_lockout_policy_file'].Results) {
                    # Use osquery JSON file data
                    $jsonData = $OsqueryData['ac_lockout_policy_file'].Results[0]
                    $evidence['AccountLockoutPolicy'] = [PSCustomObject]@{
                        LockoutBadCount = $jsonData.lockout_threshold
                        LockoutDuration = $jsonData.lockout_duration
                        LockoutWindow = $jsonData.lockout_window
                        IsCompliant = $jsonData.compliant
                        LastCheck = $jsonData.last_check
                        Source = "JSON export file"
                    }
                } elseif ($SecurityPolicy) {
                    # Fall back to local secedit
                    $evidence['AccountLockoutPolicy'] = $SecurityPolicy.AccountLockoutPolicies
                }
            }
            elseif ($Control.control_id -eq "3.5.7") {
                if ($OsqueryData -and $OsqueryData.ContainsKey('ia_password_policy_file') -and $OsqueryData['ia_password_policy_file'].Results) {
                    # Use osquery JSON file data
                    $jsonData = $OsqueryData['ia_password_policy_file'].Results[0]
                    $evidence['PasswordPolicy'] = [PSCustomObject]@{
                        MinimumPasswordLength = $jsonData.min_length
                        PasswordComplexity = $jsonData.complexity_enabled
                        MinimumPasswordAge = $jsonData.min_age
                        MaximumPasswordAge = $jsonData.max_age
                        PasswordHistorySize = $jsonData.history_count
                        LengthOk = $jsonData.length_ok
                        ComplexityOk = $jsonData.complexity_ok
                        LastCheck = $jsonData.last_check
                        Source = "JSON export file"
                    }
                } elseif ($SecurityPolicy) {
                    # Fall back to local secedit
                    $evidence['PasswordPolicy'] = $SecurityPolicy.PasswordPolicies
                }
            }

            $assessment.Evidence = $evidence
        }

        return $assessment
    }
    catch {
        Write-Warning "Error assessing control $($Control.control_id): $_"
        $assessment.Status = "Error"
        $assessment.Findings += "Assessment error: $_"
        return $assessment
    }
}

function Test-AccountLockoutPolicy {
    param($SecurityPolicy, $Assessment, $OsqueryData)

    # Try to get lockout data from osquery JSON file first, then SecurityPolicy
    $lockoutThreshold = $null
    $lockoutDuration = $null

    if ($OsqueryData -and $OsqueryData.ContainsKey('ac_lockout_policy_file') -and $OsqueryData['ac_lockout_policy_file'].Results) {
        $jsonData = $OsqueryData['ac_lockout_policy_file'].Results[0]
        $lockoutThreshold = $jsonData.lockout_threshold
        $lockoutDuration = $jsonData.lockout_duration
    } elseif ($SecurityPolicy -and $SecurityPolicy.AccountLockoutPolicies) {
        $lockoutThreshold = $SecurityPolicy.AccountLockoutPolicies.LockoutBadCount
        $lockoutDuration = $SecurityPolicy.AccountLockoutPolicies.LockoutDuration
    }

    if ($null -eq $lockoutThreshold) {
        $Assessment.Findings += "Security policy not available - ensure Export-SecurityPolicy.ps1 scheduled task is running"
        $Assessment.Recommendations += "Install scheduled task: .\scripts\Install-SecurityPolicyExport.ps1"
        return "NotAssessed"
    }

    # NIST recommends 3-5 failed attempts, we'll check for <= 10
    if ($lockoutThreshold -eq 0) {
        $Assessment.Findings += "Account lockout is not configured (LockoutBadCount = 0 or not set)"
        $Assessment.Severity = "High"
        $Assessment.Recommendations += "Configure account lockout: Set-LocalSecurityPolicy -LockoutBadCount 5 -LockoutDuration 30 -ResetLockoutCount 30"
        return "Fail"
    }

    if ($lockoutThreshold -gt 10) {
        $Assessment.Findings += "Account lockout threshold too high: $lockoutThreshold (should be <= 10, recommend 3-5)"
        $Assessment.Severity = "Medium"
        $Assessment.Recommendations += "Reduce lockout threshold to 5 failed attempts"
        return "Fail"
    }

    $Assessment.Findings += "Account lockout configured: $lockoutThreshold failed attempts, $lockoutDuration minutes duration"
    return "Pass"
}

function Test-PasswordPolicy {
    param($SecurityPolicy, $Assessment, $OsqueryData)

    # Try to get password data from osquery JSON file first, then SecurityPolicy
    $minLength = $null
    $complexity = $null

    if ($OsqueryData -and $OsqueryData.ContainsKey('ia_password_policy_file') -and $OsqueryData['ia_password_policy_file'].Results) {
        $jsonData = $OsqueryData['ia_password_policy_file'].Results[0]
        $minLength = $jsonData.min_length
        $complexity = $jsonData.complexity_enabled
    } elseif ($SecurityPolicy -and $SecurityPolicy.PasswordPolicies) {
        $minLength = $SecurityPolicy.PasswordPolicies.MinimumPasswordLength
        $complexity = $SecurityPolicy.PasswordPolicies.PasswordComplexity
    }

    if ($null -eq $minLength) {
        $Assessment.Findings += "Security policy not available - ensure Export-SecurityPolicy.ps1 scheduled task is running"
        $Assessment.Recommendations += "Install scheduled task: .\scripts\Install-SecurityPolicyExport.ps1"
        return "NotAssessed"
    }

    $passed = $true

    # Check minimum length (NIST recommends >= 14, minimum 8)
    if ($minLength -lt 8) {
        $Assessment.Findings += "Password minimum length insufficient: $minLength (should be >= 8, recommend 14+)"
        $Assessment.Severity = "High"
        $Assessment.Recommendations += "Increase minimum password length to 14 characters"
        $passed = $false
    }
    elseif ($minLength -lt 14) {
        $Assessment.Findings += "Password minimum length below recommended: $minLength (recommend 14+)"
        $Assessment.Severity = "Medium"
        $Assessment.Recommendations += "Consider increasing minimum password length to 14 characters per NIST SP 800-63B"
        $passed = $false
    }

    # Check complexity (1 = enabled, 0 = disabled)
    if ($null -eq $complexity -or $complexity -eq 0) {
        $Assessment.Findings += "Password complexity not enabled"
        $Assessment.Severity = "High"
        $Assessment.Recommendations += "Enable password complexity requirements"
        $passed = $false
    }

    if ($passed) {
        $Assessment.Findings += "Password policy configured: $minLength character minimum, complexity enabled"
        return "Pass"
    }

    return "Fail"
}

function Test-OsqueryControl {
    param($Control, $OsqueryData, $Assessment)

    # Check if all required queries have results
    $allQueriesFound = $true
    $findings = @()

    foreach ($query in $Control.queries) {
        $queryName = $query.query_name

        if (-not $OsqueryData.ContainsKey($queryName)) {
            $allQueriesFound = $false
            $findings += "Query '$queryName' results not found in osquery data"
        }
        else {
            $resultCount = $OsqueryData[$queryName].Results.Count
            $findings += "Query '$queryName' returned $resultCount result(s)"
        }
    }

    if (-not $allQueriesFound) {
        $Assessment.Findings += $findings
        return "Inconclusive"
    }

    # For now, we'll mark as Inconclusive since full logic requires business context
    # In a production system, you'd implement specific pass/fail logic per control
    $Assessment.Findings += $findings
    $Assessment.Findings += "Manual review required - compare results against organizational baselines"
    $Assessment.Recommendations += "Review query results and compare against approved configurations"

    return "Inconclusive"
}
