# Refactoring & Expansion Plan

## Goals
1. ✅ Keep local testing (PowerShell module)
2. ✅ Keep central monitoring (osquery integration)
3. 🔧 Eliminate duplicate code
4. 📈 Expand from 10 to 60+ controls
5. 📝 Simplify documentation

---

## Phase 1: Quick Wins (2 hours)

### 1.1 Remove Deprecated Queries
**Files to modify:**
- `packs/ac_access_control.conf` - Remove `ac_lockout_threshold`
- `packs/ia_identification_authentication.conf` - Remove `ia_password_policy`

**Benefit:** Cleaner osquery logs, less confusion

### 1.2 Consolidate Documentation
**Merge these files:**
- QUICKSTART.md → README.md (section)
- docs/osquery_windows_policy_integration.md → README.md (section)

**Keep:**
- README.md (single source of truth)
- docs/osquery_install_windows.md (detailed installation)
- CLAUDE.md (dev guidelines)

**Benefit:** One place to learn how to use the project

---

## Phase 2: Consolidate Code (4 hours)

### 2.1 Create Shared Data Contract

**New file:** `scripts/Invoke-ComplianceDataCollection.ps1`

This replaces both:
- PowerShell module's secedit parsing
- Export-SecurityPolicy.ps1

**Function:**
```powershell
function Invoke-ComplianceDataCollection {
    param(
        [string]$OutputPath = "C:\ProgramData\osquery\nist_compliance_data.json"
    )

    # 1. Export secedit policies
    $policies = Export-SeceditPolicies

    # 2. Parse osquery results (if available)
    $osqueryData = Get-OsqueryResults

    # 3. Assess compliance for all controls
    $assessments = Test-AllControls -Policies $policies -OsqueryData $osqueryData

    # 4. Write JSON
    @{
        policies = $policies
        osquery_data = $osqueryData
        assessments = $assessments
        metadata = @{
            timestamp = Get-Date -Format "o"
            hostname = $env:COMPUTERNAME
            version = "2.0"
        }
    } | ConvertTo-Json -Depth 10 | Set-Content $OutputPath
}
```

### 2.2 Simplify PowerShell Module

**Get-NISTCompliance becomes:**
```powershell
function Get-NISTCompliance {
    [CmdletBinding()]
    param(
        [string]$DataPath = "C:\ProgramData\osquery\nist_compliance_data.json",
        [switch]$Refresh  # Force re-collection
    )

    if ($Refresh -or -not (Test-Path $DataPath)) {
        # Collect fresh data
        Invoke-ComplianceDataCollection -OutputPath $DataPath
    }

    # Read and return
    Get-Content $DataPath | ConvertFrom-Json
}
```

**Benefit:**
- PowerShell module becomes ~200 lines instead of 1,200
- Single source of truth for data collection
- Same data for local and central use

---

## Phase 3: Coverage Expansion (8 hours)

### 3.1 Audit Current Coverage

**Current: 10 controls mapped**

| Control Family | Mapped | Total | % |
|----------------|--------|-------|---|
| 3.1 Access Control | 2 | 22 | 9% |
| 3.3 Audit & Accountability | 1 | 9 | 11% |
| 3.4 Configuration Management | 1 | 9 | 11% |
| 3.5 Identification & Authentication | 1 | 11 | 9% |
| 3.13 System Communications | 1 | 16 | 6% |
| 3.14 System Integrity | 3 | 13 | 23% |
| **Other families** | 0 | 30 | 0% |

### 3.2 Priority Expansion

**Highest ROI - Fully Automated:**

1. **3.1 Access Control (add 8 controls)**
   - 3.1.2 - Limit system access to transaction types
   - 3.1.3 - Control CUI flow
   - 3.1.6 - Use non-privileged accounts
   - 3.1.7 - Prevent non-privileged users from executing privileged functions
   - 3.1.12 - Monitor and control remote access sessions
   - 3.1.13 - Employ cryptographic mechanisms (RDP, HTTPS)
   - 3.1.16 - Wireless access protection
   - 3.1.20 - Control connection of mobile devices

2. **3.4 Configuration Management (add 5 controls)**
   - 3.4.2 - Establish/maintain baseline configurations
   - 3.4.3 - Track, review, approve system component changes
   - 3.4.6 - Employ least functionality principle
   - 3.4.7 - Restrict/disable/prevent unnecessary functions
   - 3.4.9 - Control and monitor user-installed software

3. **3.13 System Communications (add 6 controls)**
   - 3.13.2 - Employ architectural designs
   - 3.13.5 - Implement subnetworks for publicly accessible components
   - 3.13.6 - Deny network communications by default
   - 3.13.8 - Implement cryptographic mechanisms
   - 3.13.10 - Establish/manage cryptographic keys
   - 3.13.11 - Employ FIPS-validated cryptography

4. **3.14 System Integrity (add 5 controls)**
   - 3.14.3 - Monitor communications for unusual activity
   - 3.14.4 - Update malicious code protection
   - 3.14.5 - Perform periodic system scans
   - 3.14.7 - Identify unauthorized use
   - 3.14.9 - User notification of security awareness

**Target: 30 additional controls = 40 total (36% coverage)**

### 3.3 osquery Tables Needed

**New queries to add:**

| osquery Table | NIST Controls | Query Purpose |
|--------------|---------------|---------------|
| `processes` | 3.1.2, 3.1.7 | Running processes, privilege levels |
| `startup_items` | 3.4.9 | Auto-start programs |
| `programs` | 3.4.2, 3.4.9 | Installed software inventory |
| `interface_addresses` | 3.13.5 | Network interfaces |
| `certificates` | 3.13.8, 3.13.10 | SSL/TLS certificates |
| `windows_eventlog` | 3.14.7 | Security event monitoring |
| `scheduled_tasks` | 3.4.7 | Scheduled tasks inventory |
| `shares` | 3.1.3 | Network shares |

---

## Phase 4: Testing Strategy

### 4.1 Local Testing Workflow

```powershell
# 1. Install on test system
.\scripts\Install-SecurityPolicyExport.ps1

# 2. Force data collection
Get-NISTCompliance -Refresh

# 3. Generate report
Get-NISTCompliance | Export-NISTReport -Format Console

# 4. Verify JSON file exists
Get-Content C:\ProgramData\osquery\nist_compliance_data.json | ConvertFrom-Json
```

### 4.2 osquery Integration Testing

```powershell
# 1. Deploy packs
Copy-Item packs\*.conf "C:\Program Files\osquery\packs\"

# 2. Update osquery.conf
# (add packs)

# 3. Restart osquery
Restart-Service osqueryd

# 4. Query the data
osqueryi "SELECT * FROM file WHERE path = 'C:\\ProgramData\\osquery\\nist_compliance_data.json';"

# 5. Check in Fleet/osctrl
# (verify data appears)
```

---

## Phase 5: Documentation Update

### 5.1 New Structure

```
README.md
├─ Overview
├─ Quick Start (local testing)
├─ osquery Integration (Fleet/osctrl)
├─ Control Coverage Matrix
└─ Troubleshooting

docs/
├─ osquery_install_windows.md (detailed setup)
├─ control_coverage.md (all 110 controls, automation level)
└─ development.md (for contributors)

CLAUDE.md (unchanged - dev guidelines)
```

### 5.2 Coverage Matrix

Create `docs/control_coverage.md`:

```markdown
# NIST 800-171 Rev 2 Control Coverage

## Summary
- Total Controls: 110
- Fully Automated: 40 (36%)
- Partially Automated: 25 (23%)
- Manual Only: 45 (41%)

## 3.1 Access Control (22 controls)

| Control | Title | Automation | osquery Tables | Status |
|---------|-------|------------|----------------|--------|
| 3.1.1 | Limit system access | ✅ Fully | users, groups, logged_in_users | ✅ Implemented |
| 3.1.2 | Transaction types | ✅ Fully | processes, registry | 🔄 Planned |
| 3.1.3 | Control CUI flow | ⚠️ Partial | shares, processes | 🔄 Planned |
...
```

---

## Timeline

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| 1. Quick Wins | 2 hours | Clean packs, consolidated docs |
| 2. Consolidate Code | 4 hours | Shared data collection, thin module |
| 3. Coverage Expansion | 8 hours | 30 additional controls |
| 4. Testing | 2 hours | Verified local + osquery paths |
| 5. Documentation | 2 hours | Coverage matrix, updated README |
| **Total** | **18 hours** | **Production-ready, 40 controls** |

---

## Decision Points

### Option A: Aggressive Refactoring
- Remove all duplication NOW
- Simplify PowerShell module to read JSON
- Expand coverage to 40+ controls
- Timeline: 18 hours

### Option B: Conservative Approach
- Keep current architecture
- Just remove deprecated queries
- Expand coverage incrementally
- Timeline: 10 hours (less risk)

### Option C: Coverage First
- Keep current code as-is
- Focus only on expanding control coverage
- Defer refactoring
- Timeline: 8 hours (fastest to value)

---

## My Recommendation

**Option A (Aggressive Refactoring)** because:

1. You want **simplicity** (stated goal)
2. You need **local testing** (confirmed)
3. Current duplication is **technical debt**
4. Expansion is **easier** with clean architecture

**Next Steps:**
1. Get approval for Option A
2. Start with Phase 1 (quick wins)
3. Test locally on your system
4. Proceed with remaining phases

Should I start with Phase 1 (remove deprecated queries)?
