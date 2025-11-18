# Integrating Windows Policy Checks into osquery

**Problem**: osquery doesn't have native tables for Windows password and account lockout policies.

**Goal**: Make policy data available through osquery's standard query interface, backend-agnostic.

## Solutions Overview

| Solution | Complexity | Backend Support | Maintenance |
|----------|-----------|-----------------|-------------|
| 1. Custom Extension Table | High | All backends | Low (compile once) |
| 2. File-Based Pattern | Low | All backends | Medium (OS dependency) |
| 3. ATC (Auto Table Construction) | Medium | osquery 4.6+ | Medium |

---

## Solution 1: Custom osquery Extension (Recommended)

Create a native osquery extension that exposes Windows policies as queryable tables.

### Architecture

```
osquery → Load Extension → windows_account_policy table → Query/Log
                         → windows_password_policy table
```

### Extension Tables

**Table: `windows_account_policy`**
```sql
SELECT * FROM windows_account_policy;
```

| Column | Type | Description |
|--------|------|-------------|
| lockout_threshold | INTEGER | Failed logon attempts before lockout (0 = disabled) |
| lockout_duration | INTEGER | Lockout duration in minutes (-1 = manual unlock) |
| lockout_window | INTEGER | Observation window in minutes |
| force_logoff | INTEGER | Force logoff when hours expire (bool) |

**Table: `windows_password_policy`**
```sql
SELECT * FROM windows_password_policy;
```

| Column | Type | Description |
|--------|------|-------------|
| min_password_length | INTEGER | Minimum password length |
| password_complexity | INTEGER | Complexity enabled (1) or disabled (0) |
| min_password_age | INTEGER | Minimum password age in days |
| max_password_age | INTEGER | Maximum password age in days |
| password_history | INTEGER | Number of passwords remembered |
| reversible_encryption | INTEGER | Store passwords with reversible encryption (bool) |

### Implementation

See `extensions/windows_policy/` directory for full C++ implementation.

**Quick Build:**
```bash
# Clone osquery
git clone https://github.com/osquery/osquery.git
cd osquery

# Copy extension
cp -r ../extensions/windows_policy ./external/extension_windows_policy/

# Build
cmake -B build -S . -DOSQUERY_BUILD_EXTENSIONS=ON
cmake --build build --target windows_policy_extension

# Output: build/external/extension_windows_policy/windows_policy_extension.ext.exe
```

**Deployment:**

1. **Copy to osquery directory:**
   ```powershell
   Copy-Item windows_policy_extension.ext.exe "C:\Program Files\osquery\extensions\"
   ```

2. **Configure osquery.flags:**
   ```
   --extensions_autoload=C:\Program Files\osquery\extensions\windows_policy_extension.ext.exe
   --extensions_timeout=10
   --extensions_interval=3
   ```

3. **Verify loaded:**
   ```sql
   SELECT * FROM osquery_extensions;
   SELECT * FROM windows_account_policy;
   SELECT * FROM windows_password_policy;
   ```

**Query Examples:**

```sql
-- Check if account lockout is configured
SELECT
  CASE
    WHEN lockout_threshold = 0 THEN 'FAIL'
    WHEN lockout_threshold > 10 THEN 'WARN'
    ELSE 'PASS'
  END AS status,
  lockout_threshold,
  lockout_duration
FROM windows_account_policy;

-- Check password policy compliance
SELECT
  CASE
    WHEN min_password_length < 8 THEN 'FAIL'
    WHEN min_password_length < 14 THEN 'WARN'
    ELSE 'PASS'
  END AS length_status,
  CASE
    WHEN password_complexity = 0 THEN 'FAIL'
    ELSE 'PASS'
  END AS complexity_status,
  min_password_length,
  password_complexity
FROM windows_password_policy;
```

**Add to NIST Packs:**

Update `packs/ac_access_control.conf`:

```json
{
  "queries": {
    "ac_account_lockout": {
      "query": "SELECT * FROM windows_account_policy WHERE lockout_threshold > 0;",
      "interval": 3600,
      "description": "NIST 3.1.8 - Account lockout policy",
      "value": "Verify account lockout is configured"
    }
  }
}
```

Update `packs/ia_identification_authentication.conf`:

```json
{
  "queries": {
    "ia_password_policy": {
      "query": "SELECT * FROM windows_password_policy WHERE min_password_length >= 8 AND password_complexity = 1;",
      "interval": 3600,
      "description": "NIST 3.5.7 - Password complexity policy",
      "value": "Verify password policy meets requirements"
    }
  }
}
```

---

## Solution 2: File-Based Pattern (Works Today)

Use Windows Task Scheduler + osquery's `file` table to parse secedit output.

### Architecture

```
Task Scheduler → secedit export → Parse to JSON → osquery file table → Query/Log
```

### Implementation

**Step 1: Create secedit export script**

`C:\Scripts\Export-SecurityPolicy.ps1`:
```powershell
#Requires -RunAsAdministrator

$exportPath = "C:\ProgramData\osquery\security_policy.json"
$tempCfg = "$env:TEMP\secpol_export.cfg"

# Export using secedit
secedit /export /cfg $tempCfg /quiet

# Parse output
$policy = @{
    account_lockout = @{
        lockout_threshold = 0
        lockout_duration = 0
        lockout_window = 0
    }
    password_policy = @{
        min_password_length = 0
        password_complexity = 0
        min_password_age = 0
        max_password_age = 0
        password_history = 0
    }
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
}

# Parse secedit output
Get-Content $tempCfg | ForEach-Object {
    if ($_ -match '^LockoutBadCount\s*=\s*(\d+)') {
        $policy.account_lockout.lockout_threshold = [int]$matches[1]
    }
    elseif ($_ -match '^LockoutDuration\s*=\s*(-?\d+)') {
        $policy.account_lockout.lockout_duration = [int]$matches[1]
    }
    elseif ($_ -match '^ResetLockoutCount\s*=\s*(\d+)') {
        $policy.account_lockout.lockout_window = [int]$matches[1]
    }
    elseif ($_ -match '^MinimumPasswordLength\s*=\s*(\d+)') {
        $policy.password_policy.min_password_length = [int]$matches[1]
    }
    elseif ($_ -match '^PasswordComplexity\s*=\s*(\d+)') {
        $policy.password_policy.password_complexity = [int]$matches[1]
    }
    elseif ($_ -match '^MinimumPasswordAge\s*=\s*(\d+)') {
        $policy.password_policy.min_password_age = [int]$matches[1]
    }
    elseif ($_ -match '^MaximumPasswordAge\s*=\s*(\d+)') {
        $policy.password_policy.max_password_age = [int]$matches[1]
    }
    elseif ($_ -match '^PasswordHistorySize\s*=\s*(\d+)') {
        $policy.password_policy.password_history = [int]$matches[1]
    }
}

# Export as JSON
$policy | ConvertTo-Json -Depth 3 | Set-Content -Path $exportPath -Encoding UTF8

# Cleanup
Remove-Item $tempCfg -Force -ErrorAction SilentlyContinue
```

**Step 2: Schedule the export**

```powershell
# Create scheduled task to run every hour
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File C:\Scripts\Export-SecurityPolicy.ps1"

$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "Export Security Policy for osquery" `
    -Action $action -Trigger $trigger -Principal $principal `
    -Description "Exports Windows security policy to JSON for osquery consumption"
```

**Step 3: Query via osquery**

Add to `packs/ac_access_control.conf`:

```json
{
  "queries": {
    "ac_account_lockout_policy": {
      "query": "SELECT JSON_EXTRACT(data, '$.account_lockout.lockout_threshold') AS lockout_threshold, JSON_EXTRACT(data, '$.account_lockout.lockout_duration') AS lockout_duration, JSON_EXTRACT(data, '$.timestamp') AS last_updated FROM (SELECT file.data AS data FROM file WHERE path = 'C:\\ProgramData\\osquery\\security_policy.json');",
      "interval": 3600,
      "description": "NIST 3.1.8 - Account lockout policy via exported file",
      "value": "Verify account lockout configuration"
    },
    "ia_password_policy_export": {
      "query": "SELECT JSON_EXTRACT(data, '$.password_policy.min_password_length') AS min_length, JSON_EXTRACT(data, '$.password_policy.password_complexity') AS complexity, JSON_EXTRACT(data, '$.timestamp') AS last_updated FROM (SELECT file.data AS data FROM file WHERE path = 'C:\\ProgramData\\osquery\\security_policy.json');",
      "interval": 3600,
      "description": "NIST 3.5.7 - Password policy via exported file",
      "value": "Verify password complexity requirements"
    }
  }
}
```

**Pros:**
- ✅ Works with stock osquery (no compilation)
- ✅ Backend-agnostic
- ✅ Can be deployed via GPO

**Cons:**
- ⚠️ Depends on scheduled task
- ⚠️ 1-hour lag vs real-time
- ⚠️ More moving parts

---

## Solution 3: ATC (Auto Table Construction) - Experimental

osquery 4.6+ supports ATC (Automatic Table Construction) via `yara` or custom scripts.

**Note:** This is less mature and may not work reliably on Windows.

### Configuration

Add to `osquery.conf`:

```json
{
  "auto_table_construction": {
    "windows_policy_check": {
      "query": "SELECT * FROM powershell WHERE script_text LIKE '%secedit%';",
      "path": "C:\\Scripts\\policy-check.ps1",
      "columns": ["lockout_threshold", "lockout_duration", "min_password_length", "password_complexity"]
    }
  }
}
```

This is experimental and not recommended for production.

---

## Comparison & Recommendation

### For Production: Solution 1 (Custom Extension)

**Why:**
- Native osquery table (clean queries)
- Real-time data (no scheduled tasks)
- Works with all backends (Fleet, osctrl, standalone)
- One-time compilation effort
- Low maintenance

**Implementation timeline:** 1-2 days for development + testing

### For Quick Deployment: Solution 2 (File-Based)

**Why:**
- Works immediately with stock osquery
- No C++ development required
- Can be deployed via Group Policy
- Acceptable for hourly compliance checks

**Implementation timeline:** 2-4 hours

---

## Next Steps

**Choose your path:**

1. **Extension Route (Recommended):**
   - I'll create the C++ extension code
   - Build instructions for Windows
   - Deployment guide for Fleet/osctrl
   - Updated query packs

2. **File-Based Route (Quick Win):**
   - I'll create the PowerShell export script
   - Task Scheduler deployment guide
   - Updated query packs with JSON extraction
   - Testing instructions

Which would you like me to implement?
