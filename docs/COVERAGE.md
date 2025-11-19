# NIST SP 800-171 Rev 2 Control Coverage Matrix

**Last Updated**: 2025-11-19
**Current Coverage**: 10/110 controls (9%)
**Target Coverage**: 28/110 controls (25%)

## Summary Statistics

| Automation Level | Current | Target | Ultimate Goal |
|------------------|---------|--------|---------------|
| **Fully Automated** | 2 | 8 | 20-25 |
| **Partially Automated** | 8 | 20 | 40-50 |
| **Manual Only** | 0 | 0 | 40-45 |
| **Not Implemented** | 100 | 82 | 0 |
| **TOTAL** | 10 | 28 | 110 |

**Coverage**: 9% → 25% → 100%

---

## 3.1 ACCESS CONTROL (22 controls)

| ID | Title | Automation | osquery Tables | Status | Priority |
|----|-------|------------|----------------|--------|----------|
| 3.1.1 | Limit system access to authorized users | ⚠️ Partial | users, groups, logged_in_users | ✅ **Implemented** | - |
| 3.1.2 | Limit system access to transaction types | ⚠️ Partial | processes, listening_ports | 🎯 **Target** | HIGH |
| 3.1.3 | Control flow of CUI | ⚠️ Partial | shares, file | 🎯 **Target** | MEDIUM |
| 3.1.4 | Separate duties of individuals | ❌ Manual | N/A - Policy | ⬜ Not Planned | - |
| 3.1.5 | Employ least privilege | ⚠️ Partial | users, user_groups | ✅ **Implemented** | - |
| 3.1.6 | Use non-privileged accounts | ⚠️ Partial | users, processes | 🎯 **Target** | HIGH |
| 3.1.7 | Prevent non-privileged execution of privileged functions | ⚠️ Partial | registry (UAC), processes | 🎯 **Target** | HIGH |
| 3.1.8 | Limit unsuccessful logon attempts | ✅ Full | secedit export | ✅ **Implemented** | - |
| 3.1.9 | Provide privacy/security notices | ❌ Manual | N/A - Policy | ⬜ Not Planned | - |
| 3.1.10 | Use session lock with pattern-hiding displays | ⚠️ Partial | registry | 🎯 **Target** | MEDIUM |
| 3.1.11 | Terminate session after inactivity | ⚠️ Partial | registry, group_policy | 🎯 **Target** | MEDIUM |
| 3.1.12 | Monitor/control remote access sessions | ⚠️ Partial | logged_in_users, process_open_sockets | 🎯 **Target** | HIGH |
| 3.1.13 | Employ cryptographic mechanisms | ⚠️ Partial | registry (TLS), services | 🎯 **Target** | MEDIUM |
| 3.1.14 | Control portable storage | ⚠️ Partial | registry, usb_devices | ⬜ Future | - |
| 3.1.15 | Control mobile code | ❌ Manual | N/A - Policy | ⬜ Not Planned | - |
| 3.1.16 | Control wireless access | ⚠️ Partial | interface_addresses, wifi_networks | ⬜ Future | - |
| 3.1.17 | Protect wireless access | ⚠️ Partial | wifi_status, wifi_survey | ⬜ Future | - |
| 3.1.18 | Control connection of mobile devices | ⚠️ Partial | usb_devices, device_file | ⬜ Future | - |
| 3.1.19 | Encrypt CUI on mobile devices | ❌ Manual | N/A - Policy | ⬜ Not Planned | - |
| 3.1.20 | Verify/control remote access | ⚠️ Partial | services (RDP), registry | 🎯 **Target** | MEDIUM |
| 3.1.21 | Encrypt CUI at rest | ⚠️ Partial | bitlocker_info, disk_encryption | ⬜ Future | - |
| 3.1.22 | Control publicly accessible system CUI | ❌ Manual | N/A - Manual review | ⬜ Not Planned | - |

**Current**: 2/22 (9%)
**Target**: 9/22 (41%)

---

## 3.2 AWARENESS AND TRAINING (3 controls)

| ID | Title | Automation | osquery Tables | Status | Priority |
|----|-------|------------|----------------|--------|----------|
| 3.2.1 | Ensure managers/users are trained | ❌ Manual | N/A - HR/Training records | ⬜ Not Planned | - |
| 3.2.2 | Provide security awareness training | ❌ Manual | N/A - HR/Training records | ⬜ Not Planned | - |
| 3.2.3 | Provide role-based security training | ❌ Manual | N/A - HR/Training records | ⬜ Not Planned | - |

**Current**: 0/3 (0%)
**Target**: 0/3 (0%) - All manual

---

## 3.3 AUDIT AND ACCOUNTABILITY (9 controls)

| ID | Title | Automation | osquery Tables | Status | Priority |
|----|-------|------------|----------------|--------|----------|
| 3.3.1 | Create/retain audit logs | ⚠️ Partial | windows_eventlog, registry | ✅ **Implemented** | - |
| 3.3.2 | Ensure actions can be traced to users | ⚠️ Partial | windows_eventlog (audit config) | 🎯 **Target** | HIGH |
| 3.3.3 | Review/update logged events | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.3.4 | Alert on audit processing failures | ⚠️ Partial | windows_eventlog (audit failures) | ⬜ Future | - |
| 3.3.5 | Correlate audit records | ❌ Manual | N/A - SIEM function | ⬜ Not Planned | - |
| 3.3.6 | Provide audit reduction/report generation | ❌ Manual | N/A - SIEM function | ⬜ Not Planned | - |
| 3.3.7 | Provide audit protection | ⚠️ Partial | file (permissions), registry | ⬜ Future | - |
| 3.3.8 | Limit audit management to subset of users | ⚠️ Partial | user_groups (Event Log Readers) | ⬜ Future | - |
| 3.3.9 | Protect audit info from unauthorized access | ❌ Manual | N/A - Policy | ⬜ Not Planned | - |

**Current**: 1/9 (11%)
**Target**: 2/9 (22%)

---

## 3.4 CONFIGURATION MANAGEMENT (9 controls)

| ID | Title | Automation | osquery Tables | Status | Priority |
|----|-------|------------|----------------|--------|----------|
| 3.4.1 | Establish/maintain baseline configurations | ⚠️ Partial | programs, services, startup_items | ✅ **Implemented** | - |
| 3.4.2 | Establish/maintain baseline configurations | ⚠️ Partial | programs, registry, services | 🎯 **Target** | HIGH |
| 3.4.3 | Track/review/approve changes | ❌ Manual | N/A - Change management | ⬜ Not Planned | - |
| 3.4.4 | Analyze security impact before changes | ❌ Manual | N/A - Change management | ⬜ Not Planned | - |
| 3.4.5 | Define/document/approve/enforce physical/logical access restrictions | ❌ Manual | N/A - Policy | ⬜ Not Planned | - |
| 3.4.6 | Employ least functionality | ⚠️ Partial | services, programs, windows_optional_features | 🎯 **Target** | MEDIUM |
| 3.4.7 | Restrict/disable/prevent unnecessary functions | ⚠️ Partial | services, scheduled_tasks | 🎯 **Target** | MEDIUM |
| 3.4.8 | Apply deny-by-exception policy | ❌ Manual | N/A - Policy | ⬜ Not Planned | - |
| 3.4.9 | Control/monitor user-installed software | ⚠️ Partial | programs, AppLocker | 🎯 **Target** | HIGH |

**Current**: 1/9 (11%)
**Target**: 5/9 (56%)

---

## 3.5 IDENTIFICATION AND AUTHENTICATION (11 controls)

| ID | Title | Automation | osquery Tables | Status | Priority |
|----|-------|------------|----------------|--------|----------|
| 3.5.1 | Identify system users/processes | ⚠️ Partial | users, processes | 🎯 **Target** | MEDIUM |
| 3.5.2 | Authenticate users/processes | ⚠️ Partial | registry (auth mechanisms) | ⬜ Future | - |
| 3.5.3 | Use multifactor authentication | ⚠️ Partial | registry, credential_guard_status | ⬜ Future | - |
| 3.5.4 | Employ replay-resistant authentication | ❌ Manual | N/A - Infrastructure | ⬜ Not Planned | - |
| 3.5.5 | Prevent reuse of identifiers | ❌ Manual | N/A - Identity management | ⬜ Not Planned | - |
| 3.5.6 | Disable identifiers after inactivity | ⚠️ Partial | users (last_login) | ⬜ Future | - |
| 3.5.7 | Enforce minimum password complexity | ✅ Full | secedit export | ✅ **Implemented** | - |
| 3.5.8 | Prohibit password reuse | ⚠️ Partial | secedit export (history) | ⬜ Future | - |
| 3.5.9 | Allow temporary password use for one logon | ❌ Manual | N/A - Identity management | ⬜ Not Planned | - |
| 3.5.10 | Store/transmit encrypted passwords | ⚠️ Partial | registry (reversible encryption) | ⬜ Future | - |
| 3.5.11 | Obscure feedback of authentication info | ❌ Manual | N/A - Default behavior | ⬜ Not Planned | - |

**Current**: 1/11 (9%)
**Target**: 2/11 (18%)

---

## 3.6 INCIDENT RESPONSE (3 controls)

| ID | Title | Automation | osquery Tables | Status | Priority |
|----|-------|------------|----------------|--------|----------|
| 3.6.1 | Establish incident handling capability | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.6.2 | Track/document/report incidents | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.6.3 | Test incident response capability | ❌ Manual | N/A - Process | ⬜ Not Planned | - |

**Current**: 0/3 (0%)
**Target**: 0/3 (0%) - All manual

---

## 3.7 MAINTENANCE (6 controls)

| ID | Title | Automation | osquery Tables | Status | Priority |
|----|-------|------------|----------------|--------|----------|
| 3.7.1 | Perform maintenance with approved/controlled tools | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.7.2 | Effectively control maintenance tools | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.7.3 | Ensure equipment removed for maintenance is sanitized | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.7.4 | Check media with malicious code before use | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.7.5 | Require multifactor authentication for remote maintenance | ⚠️ Partial | registry (RDP settings) | ⬜ Future | - |
| 3.7.6 | Supervise maintenance activities | ❌ Manual | N/A - Process | ⬜ Not Planned | - |

**Current**: 0/6 (0%)
**Target**: 0/6 (0%)

---

## 3.8 MEDIA PROTECTION (9 controls)

| ID | Title | Automation | osquery Tables | Status | Priority |
|----|-------|------------|----------------|--------|----------|
| 3.8.1 | Protect from unauthorized access/use | ❌ Manual | N/A - Physical/Policy | ⬜ Not Planned | - |
| 3.8.2 | Limit access to CUI on system media | ❌ Manual | N/A - Policy | ⬜ Not Planned | - |
| 3.8.3 | Mark media with CUI distribution limitations | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.8.4 | Control media distribution/access | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.8.5 | Control media during transport | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.8.6 | Sanitize/destroy media | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.8.7 | Control use of removable media on system components | ⚠️ Partial | usb_devices, registry | ⬜ Future | - |
| 3.8.8 | Prohibit use of portable storage when alternative exists | ❌ Manual | N/A - Policy | ⬜ Not Planned | - |
| 3.8.9 | Protect backups | ❌ Manual | N/A - Process | ⬜ Not Planned | - |

**Current**: 0/9 (0%)
**Target**: 0/9 (0%)

---

## 3.9 PERSONNEL SECURITY (3 controls)

| ID | Title | Automation | osquery Tables | Status | Priority |
|----|-------|------------|----------------|--------|----------|
| 3.9.1 | Screen individuals prior to authorizing access | ❌ Manual | N/A - HR process | ⬜ Not Planned | - |
| 3.9.2 | Ensure positions are risk-designated | ❌ Manual | N/A - HR process | ⬜ Not Planned | - |
| 3.9.3 | Ensure screening criteria are satisfied | ❌ Manual | N/A - HR process | ⬜ Not Planned | - |

**Current**: 0/3 (0%)
**Target**: 0/3 (0%) - All manual

---

## 3.10 PHYSICAL PROTECTION (6 controls)

| ID | Title | Automation | osquery Tables | Status | Priority |
|----|-------|------------|----------------|--------|----------|
| 3.10.1 | Limit physical access | ❌ Manual | N/A - Physical | ⬜ Not Planned | - |
| 3.10.2 | Protect/monitor physical facility | ❌ Manual | N/A - Physical | ⬜ Not Planned | - |
| 3.10.3 | Escort visitors | ❌ Manual | N/A - Physical | ⬜ Not Planned | - |
| 3.10.4 | Maintain audit logs of physical access | ❌ Manual | N/A - Physical | ⬜ Not Planned | - |
| 3.10.5 | Control/manage physical access devices | ❌ Manual | N/A - Physical | ⬜ Not Planned | - |
| 3.10.6 | Enforce safeguarding measures for CUI | ❌ Manual | N/A - Physical | ⬜ Not Planned | - |

**Current**: 0/6 (0%)
**Target**: 0/6 (0%) - All manual

---

## 3.11 RISK ASSESSMENT (4 controls)

| ID | Title | Automation | osquery Tables | Status | Priority |
|----|-------|------------|----------------|--------|----------|
| 3.11.1 | Periodically assess risk | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.11.2 | Scan for vulnerabilities | ⚠️ Partial | patches, programs (vulnerable versions) | 🎯 **Target** | HIGH |
| 3.11.3 | Remediate vulnerabilities | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.11.4 | Update when new vulnerabilities identified | ❌ Manual | N/A - Process | ⬜ Not Planned | - |

**Current**: 0/4 (0%)
**Target**: 1/4 (25%)

---

## 3.12 SECURITY ASSESSMENT (4 controls)

| ID | Title | Automation | osquery Tables | Status | Priority |
|----|-------|------------|----------------|--------|----------|
| 3.12.1 | Periodically assess security controls | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.12.2 | Develop/implement remediation plans | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.12.3 | Monitor ongoing security control assessments | ❌ Manual | N/A - Process | ⬜ Not Planned | - |
| 3.12.4 | Develop/implement plans of action | ❌ Manual | N/A - Process | ⬜ Not Planned | - |

**Current**: 0/4 (0%)
**Target**: 0/4 (0%) - All manual

---

## 3.13 SYSTEM AND COMMUNICATIONS PROTECTION (16 controls)

| ID | Title | Automation | osquery Tables | Status | Priority |
|----|-------|------------|----------------|--------|----------|
| 3.13.1 | Monitor/control communications at boundaries | ⚠️ Partial | windows_firewall, listening_ports | ✅ **Implemented** | - |
| 3.13.2 | Employ architectural designs | ❌ Manual | N/A - Architecture | ⬜ Not Planned | - |
| 3.13.3 | Separate user/system functionality | ⚠️ Partial | services, processes | ⬜ Future | - |
| 3.13.4 | Prevent unauthorized information transfer | ❌ Manual | N/A - DLP | ⬜ Not Planned | - |
| 3.13.5 | Implement subnetworks | ⚠️ Partial | interface_addresses, routes | ⬜ Future | - |
| 3.13.6 | Deny network communications by default | ⚠️ Partial | windows_firewall_rules | ⬜ Future | - |
| 3.13.7 | Prevent remote devices from simultaneous connections | ❌ Manual | N/A - Network infrastructure | ⬜ Not Planned | - |
| 3.13.8 | Implement cryptographic mechanisms | ⚠️ Partial | certificates, tls_settings | 🎯 **Target** | MEDIUM |
| 3.13.9 | Terminate network connections | ⚠️ Partial | registry (idle timeout) | ⬜ Future | - |
| 3.13.10 | Establish/manage cryptographic keys | ⚠️ Partial | certificates | ⬜ Future | - |
| 3.13.11 | Employ FIPS-validated cryptography | ⚠️ Partial | registry (FIPS mode) | ⬜ Future | - |
| 3.13.12 | Prohibit remote activation | ❌ Manual | N/A - Network infrastructure | ⬜ Not Planned | - |
| 3.13.13 | Control/monitor use of mobile code | ❌ Manual | N/A - Policy | ⬜ Not Planned | - |
| 3.13.14 | Control/monitor use of VoIP | ❌ Manual | N/A - Network infrastructure | ⬜ Not Planned | - |
| 3.13.15 | Protect authenticity of communications | ❌ Manual | N/A - Network infrastructure | ⬜ Not Planned | - |
| 3.13.16 | Protect confidentiality of CUI | ⚠️ Partial | bitlocker_info, efs_info | ⬜ Future | - |

**Current**: 1/16 (6%)
**Target**: 2/16 (13%)

---

## 3.14 SYSTEM AND INFORMATION INTEGRITY (13 controls)

| ID | Title | Automation | osquery Tables | Status | Priority |
|----|-------|------------|----------------|--------|----------|
| 3.14.1 | Identify/report/correct flaws in timely manner | ⚠️ Partial | patches, windows_update_history | ✅ **Implemented** | - |
| 3.14.2 | Provide protection from malicious code | ⚠️ Partial | windows_security_products, services | ✅ **Implemented** | - |
| 3.14.3 | Monitor for unusual activity | ⚠️ Partial | processes, process_open_sockets | 🎯 **Target** | MEDIUM |
| 3.14.4 | Update malicious code protection | ⚠️ Partial | windows_security_products (signatures) | ⬜ Future | - |
| 3.14.5 | Perform periodic scans | ⚠️ Partial | scheduled_tasks (Defender scans) | ⬜ Future | - |
| 3.14.6 | Monitor communications for attacks | ⚠️ Partial | process_open_sockets, logged_in_users | ✅ **Implemented** | - |
| 3.14.7 | Identify unauthorized use | ⚠️ Partial | windows_eventlog (failed logins) | 🎯 **Target** | HIGH |
| 3.14.8 | Perform spam protection | ❌ Manual | N/A - Email infrastructure | ⬜ Not Planned | - |
| 3.14.9 | Inform users of actions | ❌ Manual | N/A - Awareness program | ⬜ Not Planned | - |
| 3.14.10 | Perform user input validity checking | ❌ Manual | N/A - Application development | ⬜ Not Planned | - |
| 3.14.11 | Manage/protect system error messages | ❌ Manual | N/A - Application development | ⬜ Not Planned | - |
| 3.14.12 | Protect memory from code execution | ⚠️ Partial | registry (DEP/ASLR) | ⬜ Future | - |
| 3.14.13 | Perform information input validation | ❌ Manual | N/A - Application development | ⬜ Not Planned | - |

**Current**: 3/13 (23%)
**Target**: 5/13 (38%)

---

## Legend

### Automation Levels
- ✅ **Fully Automated**: Technical evidence collected and pass/fail determined programmatically
- ⚠️ **Partially Automated**: Evidence collected via osquery, requires manual interpretation or baseline comparison
- ❌ **Manual Only**: Cannot be assessed via endpoint telemetry (policy, process, physical, HR)

### Status
- ✅ **Implemented**: Query exists and working
- 🎯 **Target**: Planned for 25% coverage milestone
- ⬜ **Not Planned**: Future enhancement or not automatable

### Priority (for target controls)
- **HIGH**: Critical security control, high ROI
- **MEDIUM**: Important but less critical
- **LOW**: Nice to have

---

## Coverage Roadmap

### Phase 1: Current (9%)
**Controls**: 10/110
**Focus**: Password/lockout policies, basic endpoint visibility

### Phase 2: Target 25%
**Controls**: 28/110
**Focus**: Core access control, configuration management, system integrity
**Timeline**: 1-2 weeks

### Phase 3: Mature 50%
**Controls**: 55/110
**Focus**: Comprehensive automated + partial coverage
**Timeline**: 4-6 weeks

### Phase 4: Complete
**Controls**: 110/110
**Focus**: All controls documented (automated, partial, or manual)
**Timeline**: 8-12 weeks

---

## Transparency Statement

**What this tool CAN do:**
- Automatically check password and account lockout policies (3.1.8, 3.5.7)
- Collect endpoint telemetry for access control, config management, patching, antivirus
- Provide evidence for manual review and baseline comparison
- Integrate with Fleet/osctrl/SIEM for centralized monitoring

**What this tool CANNOT do:**
- Assess physical security controls (3.10.x)
- Evaluate HR processes (3.2.x, 3.9.x)
- Determine organizational policies (risk assessment, incident response)
- Replace security assessments or audits
- Make business decisions about what's "authorized" or "approved"

**This is a COMPLIANCE MONITORING TOOL, not a compliance certification tool.**
