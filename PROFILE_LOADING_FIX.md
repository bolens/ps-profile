# Profile Loading Fix - Debug Output

## Problem

The profile was not showing any debug output, even at debug level 3, making it difficult to diagnose loading issues.

## Root Cause

The profile had early exit checks (for NoProfile detection and non-interactive hosts) that occurred BEFORE any debug output could be displayed. Additionally, debug output was only shown if `PS_PROFILE_DEBUG` environment variable was set.

## Changes Made

### 1. Early Debug Setup

- Moved debug level parsing to the very beginning of the profile (before any checks)
- Added initial startup logging that shows immediately when the profile starts

### 2. Early Exit Logging

- Added debug logging to the `PSCommandPath` empty check (NoProfile detection)
- Added debug logging to the non-interactive host check
- Added confirmation message when host check passes

### 3. Diagnostic Tools

- Created `scripts/utils/debug/diagnose-profile-loading.ps1` - comprehensive diagnostic script
- Created `scripts/utils/debug/test-profile-loading.ps1` - test script for profile loading

## How to Use Debug Mode

### Enable Debug Mode

Set the `PS_PROFILE_DEBUG` environment variable:

```powershell
# Level 1: Basic debug (minimal output)
$env:PS_PROFILE_DEBUG = '1'

# Level 2: Verbose debug (detailed output)
$env:PS_PROFILE_DEBUG = '2'

# Level 3: Maximum debug (all output including stack traces)
$env:PS_PROFILE_DEBUG = '3'
```

### Make Debug Mode Persistent

To make debug mode persistent across sessions, add it to your PowerShell profile or set it as a system environment variable:

**Option 1: Add to profile (temporary)**

```powershell
# Add to the top of Microsoft.PowerShell_profile.ps1 (before other code)
$env:PS_PROFILE_DEBUG = '3'
```

**Option 2: Set as user environment variable (persistent)**

```powershell
[System.Environment]::SetEnvironmentVariable('PS_PROFILE_DEBUG', '3', 'User')
```

**Option 3: Set for current session only**

```powershell
$env:PS_PROFILE_DEBUG = '3'
# Then reload profile
. $PROFILE
```

### Run Diagnostics

```powershell
# Run comprehensive diagnostics
pwsh -NoProfile -File scripts\utils\debug\diagnose-profile-loading.ps1

# Test profile loading with debug
pwsh -NoProfile -File scripts\utils\debug\test-profile-loading.ps1
```

## What You'll See With Debug Enabled

### Level 1 (Basic)

- Profile startup detection
- Debug mode confirmation
- Early exit warnings
- Fragment loading batches (every 10 fragments)

### Level 2 (Verbose)

- All Level 1 output
- Individual fragment loading messages
- Module loading details
- Host check confirmation

### Level 3 (Maximum)

- All Level 2 output
- Stack traces on errors
- Detailed exception information
- Function call tracing

## Example Output

With `PS_PROFILE_DEBUG=3`, you should see:

```
[profile] Profile startup detected - PSCommandPath: C:\Users\bolen\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
[profile] Debug mode enabled (level 3)
[profile] Host check passed - continuing with profile loading
Loading profile fragment: 00-bootstrap.ps1
Loading profile fragment: 01-env.ps1
...
```

## Troubleshooting

### Profile Still Not Loading?

1. **Check if debug is enabled**: Run `$env:PS_PROFILE_DEBUG` - should show a number (1-3)
2. **Run diagnostics**: `pwsh -NoProfile -File scripts\utils\debug\diagnose-profile-loading.ps1`
3. **Check for syntax errors**: The profile was syntax-checked and is valid
4. **Verify profile path**: Should be `C:\Users\bolen\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`

### No Output Even With Debug?

- Ensure `PS_PROFILE_DEBUG` is set BEFORE the profile loads
- Try setting it in the profile itself (at the very top)
- Check if you're using `-NoProfile` flag (which prevents profile loading)

### Profile Loads But Functions Missing?

- Check fragment loading messages in debug output
- Verify fragments are not disabled in configuration
- Check for errors in fragment loading (shown in red with debug enabled)

## Why Logs Only Show on Manual Reload

**Issue**: Console output (debug messages) may not appear during initial PowerShell startup, even though file-based logging works.

**Root Cause**: During initial PowerShell startup:

- **Environment variable not set**: `PS_PROFILE_DEBUG` is a session variable that may not be set during initial startup (unless set as a system/user environment variable)
- **Output streams may be buffered or redirected**: The console may not be fully initialized when the profile runs
- **Write-Output limitations**: `Write-Output` writes to the output stream, which can be suppressed during startup

**Solution**: The profile now uses `Write-Host` instead of `Write-Output` for debug messages:

- `Write-Host` writes directly to the console, bypassing output stream buffering
- More reliable during initial startup
- Falls back to `Write-Output` if `Write-Host` fails (non-interactive hosts)

**To See Debug Output on Initial Startup**:

1. **Set `PS_PROFILE_DEBUG` as a persistent environment variable** (recommended):

   ```powershell
   [System.Environment]::SetEnvironmentVariable('PS_PROFILE_DEBUG', '2', 'User')
   ```

   This ensures debug mode is enabled for all new PowerShell sessions.

2. **Or set it in your profile** (before other code):

   ```powershell
   # At the very top of Microsoft.PowerShell_profile.ps1
   $env:PS_PROFILE_DEBUG = '2'  # Level 2 shows fragment pre-registration messages
   ```

3. **Check the log file** (always works):
   ```powershell
   Get-Content $env:TEMP\powershell-profile-load.log -Tail 50
   ```

**Note**: File-based logging always works (writes to disk), so you can always check the log file even if console output doesn't appear. The fragment pre-registration messages (`[fragment-registry.pre-register-all] USING PROCESSOR MODULE`) require `PS_PROFILE_DEBUG=2` or higher to appear.

## File-Based Logging (For Hanging Issues)

If the profile hangs and you see no output at all, the profile now writes to a log file that you can check:

**Log file location:** `$env:TEMP\powershell-profile-load.log`

### Check the Log

```powershell
# View the log
pwsh -NoProfile -File scripts\utils\debug\check-profile-log.ps1

# Or manually view it
Get-Content $env:TEMP\powershell-profile-load.log -Tail 50
```

The log file will show exactly where the profile execution stopped, helping identify what's causing the hang.

### Clear the Log

```powershell
Remove-Item $env:TEMP\powershell-profile-load.log -ErrorAction SilentlyContinue
```

## Next Steps

1. **If profile hangs:**

   - Check the log file: `Get-Content $env:TEMP\powershell-profile-load.log -Tail 50`
   - This will show the last checkpoint before the hang
   - Share the last few log entries to diagnose the issue

2. **If profile loads but no output:**

   - Set `PS_PROFILE_DEBUG = '3'` to see full debug output
   - Reload your profile: `. $PROFILE`
   - Check the output for any errors or early exits

3. **Run diagnostics:**
   - `pwsh -NoProfile -File scripts\utils\debug\diagnose-profile-loading.ps1`
   - `pwsh -NoProfile -File scripts\utils\debug\test-profile-loading.ps1`
