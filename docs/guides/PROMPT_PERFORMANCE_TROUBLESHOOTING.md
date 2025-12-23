# Prompt Performance Troubleshooting

## Problem: Slow Prompt (100+ seconds)

If you're seeing messages like:

```
🐌 Slow command: prompt took 105.34s
```

This indicates your prompt function is taking over 100 seconds to execute, which severely impacts your shell experience.

## Common Causes

### 1. Starship Git Module in Large Repository

**Symptom:** Prompt is slow, especially in git repositories.

**Cause:** Starship's `git_branch` or `git_status` modules can be extremely slow in large repositories or repositories with many files.

**Solution:**

#### Option A: Disable Git in Starship (Recommended)

Edit your `starship.toml` (usually at `~/.config/starship.toml` or `$env:STARSHIP_CONFIG`):

```toml
[git_branch]
disabled = true

[git_status]
disabled = true

[git_commit]
disabled = true
```

Or disable all git modules at once:

```toml
[git_branch]
disabled = true

[git_status]
disabled = true

[git_commit]
disabled = true

[git_state]
disabled = true

[git_metrics]
disabled = true
```

#### Option B: Optimize Git Module

If you want to keep git information but make it faster:

```toml
[git_status]
disabled = false
# Only show when there are changes (faster)
conflicted_count.enabled = true
ahead_count.enabled = true
behind_count.enabled = true
# Disable slow operations
untracked_count.enabled = false  # This can be slow
stashed_count.enabled = false
```

#### Option C: Use Git Aliases with Timeout

Add to your profile or `starship.toml`:

```toml
[git_status]
# Add timeout to prevent hanging
command_timeout = 1000  # milliseconds
```

### 2. Network Timeouts

**Symptom:** Prompt hangs, especially when offline or on slow networks.

**Cause:** Starship modules that make network requests (AWS, Azure, etc.) can timeout.

**Solution:**

Disable network-dependent modules in `starship.toml`:

```toml
[aws]
disabled = true

[azure]
disabled = true

[gcloud]
disabled = true
```

### 3. Slow Filesystem Operations

**Symptom:** Prompt is slow in certain directories.

**Cause:** Starship modules that scan directories or check file types can be slow on network drives or slow filesystems.

**Solution:**

Disable filesystem-heavy modules:

```toml
[package]
disabled = true  # Scans for package.json, Cargo.toml, etc.

[rust]
disabled = true

[nodejs]
disabled = true

[python]
disabled = true
```

### 4. Too Many Modules Enabled

**Symptom:** Prompt is generally slow everywhere.

**Cause:** Too many Starship modules enabled, each adding overhead.

**Solution:**

Use a minimal Starship configuration. Create `~/.config/starship-minimal.toml`:

```toml
# Minimal fast prompt
format = """
$username\
$hostname\
$directory\
$character
"""

[username]
style_user = "green bold"
style_root = "red bold"

[hostname]
ssh_only = false
format = "@[$hostname]($style) "
trim_at = "."

[directory]
truncation_length = 3
truncate_to_repo = true

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"
```

Then set:

```powershell
$env:STARSHIP_CONFIG = "$HOME\.config\starship-minimal.toml"
```

## Quick Diagnosis

### Step 1: Identify Which Module is Slow

Enable Starship debug mode:

```powershell
$env:STARSHIP_LOG = "trace"
```

Run a command and check the output. Look for modules taking a long time.

### Step 2: Test with Minimal Prompt

Temporarily disable Starship to test if it's the cause:

```powershell
# In your profile or .profile-fragments.json
{
  "disabled": ["23-starship"]
}
```

Or set environment variable:

```powershell
$env:STARSHIP_DISABLE = "1"
```

### Step 3: Check Git Repository Size

If git is the issue, check repository size:

```powershell
# Count files in git repo
git ls-files | Measure-Object -Line

# Check if .git directory is large
Get-ChildItem .git -Recurse | Measure-Object -Property Length -Sum
```

Large repositories (>10,000 files) often cause slow git operations.

## Performance Optimizations

### 1. Use Git Status Cache

Starship can use git status caching. Add to `starship.toml`:

```toml
[git_status]
# Use git status cache (requires git-status-cache tool)
# See: https://starship.rs/config/#git-status
```

### 2. Disable Performance Insights Wrapper

If the performance insights wrapper is adding overhead, you can disable it:

```powershell
# In .profile-fragments.json
{
  "disabled": ["73-performance-insights"]
}
```

### 3. Use Smart Prompt Fallback

The profile includes a `SmartPrompt` that's much faster than Starship. To use it:

```powershell
# Disable Starship
{
  "disabled": ["23-starship"]
}

# SmartPrompt will be used automatically as fallback
```

## Environment-Specific Solutions

### For CI/CD Environments

Use minimal profile:

```powershell
$env:PS_PROFILE_ENVIRONMENT = "minimal"
```

Configure in `.profile-fragments.json`:

```json
{
  "environments": {
    "minimal": ["00-bootstrap", "01-env"]
  }
}
```

### For Large Git Repositories

1. **Disable git in prompt** (see above)
2. **Use git aliases** for common operations
3. **Consider git worktrees** to split large repos

### For Network Drives

1. **Disable directory scanning modules**
2. **Use local config** instead of network config
3. **Cache Starship config** locally

## Testing Prompt Performance

Measure prompt execution time:

```powershell
# Measure prompt execution
$sw = [System.Diagnostics.Stopwatch]::StartNew()
prompt
$sw.Stop()
Write-Host "Prompt took: $($sw.Elapsed.TotalMilliseconds)ms"
```

A good prompt should execute in < 100ms. If it's > 1000ms, optimization is needed.

## Recommended Configuration

For best performance, use this minimal `starship.toml`:

```toml
# Fast, minimal prompt
format = """
$username\
$hostname\
$directory\
$git_branch\
$character
"""

[username]
style_user = "green bold"
style_root = "red bold"

[hostname]
ssh_only = false
format = "@[$hostname]($style) "

[directory]
truncation_length = 2
truncate_to_repo = true
format = "in [$path]($style) "

[git_branch]
# Only show branch name, no status (much faster)
format = "on [$symbol$branch(:$remote_branch)]($style) "
symbol = ""

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"
```

## Additional Resources

- [Starship Performance Guide](https://starship.rs/advanced-config/#performance)
- [Starship Configuration](https://starship.rs/config/)
- Profile performance diagnostics: `pwsh -NoProfile -File scripts/utils/performance/diagnose-profile-performance.ps1`
