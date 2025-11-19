# Simplified Architecture Proposal

## Current Problem
- PowerShell module has its own secedit parsing
- Scripts have duplicate secedit parsing
- They don't share data

## Proposed Solution

### Single Data Source
`Export-SecurityPolicy.ps1` runs (via scheduled task OR manually) and creates:
```
C:\ProgramData\osquery\nist_compliance_data.json
```

This file contains:
- Password policies (from secedit)
- Account lockout policies (from secedit)
- osquery results (from osqueryd.results.log)
- Compliance assessments

### PowerShell Module Simplifies

**OLD (complex):**
```powershell
Get-NISTCompliance
  └─> Get-WindowsSecurityPolicy (runs secedit)
  └─> Parse-OsqueryResults (parses logs)
  └─> Test-ControlCriteria (assesses compliance)
```

**NEW (simple):**
```powershell
Get-NISTCompliance
  └─> Read JSON file (already has everything)
  └─> Display results
```

### Benefits
✅ No duplicate code
✅ PowerShell module becomes thin wrapper
✅ Same data for local and central monitoring
✅ Can run offline (reads cached JSON)

## Coverage Expansion

We need to map all 110 controls. Strategy:

### Tier 1: Fully Automated (osquery can check)
- 3.1.x - Access Control (users, groups, sessions)
- 3.3.x - Audit & Accountability (audit policies)
- 3.4.x - Configuration Management (software inventory)
- 3.13.x - System Communications (firewall, ports)
- 3.14.x - System Integrity (patches, antivirus)

**Estimate: 30-40 controls fully automated**

### Tier 2: Partially Automated (osquery collects evidence)
- 3.5.x - Identification & Authentication (some policies)
- 3.6.x - Incident Response (logs exist)
- 3.7.x - Maintenance (scheduled tasks)

**Estimate: 20-30 controls partially automated**

### Tier 3: Manual Only (policy/process)
- 3.2.x - Awareness & Training
- 3.9.x - Personnel Security
- 3.10.x - Physical Protection
- 3.11.x - Risk Assessment
- 3.12.x - Security Assessment

**Estimate: 40-50 controls manual**

## Implementation Plan

### Phase 1: Consolidate Current Code (1 day)
1. Simplify PowerShell module to read JSON
2. Remove deprecated queries from packs
3. Test both local and osquery paths

### Phase 2: Expand Coverage (2-3 days)
1. Map all remaining automatable controls
2. Create additional osquery pack queries
3. Update compliance assessment logic

### Phase 3: Documentation (1 day)
1. Consolidate docs into single guide
2. Coverage matrix showing automation level
3. Quick start for local vs central use

## Questions

1. Should we keep the PowerShell module but simplify it to read the JSON file?
2. How aggressive should we be on coverage expansion?
3. Do you want a detailed coverage matrix of all 110 controls?
