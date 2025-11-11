# ===============================================
# 54-modern-cli.ps1
# Modern CLI tools helpers (guarded)
# ===============================================

<#
Register modern CLI tools helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# bat - cat clone with syntax highlighting and Git integration
if (-not (Test-Path Function:bat -ErrorAction SilentlyContinue)) {
    # Use Get-Command to check for external bat command specifically
    Set-Item -Path Function:bat -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command bat -CommandType Application -ErrorAction SilentlyContinue) { & (Get-Command bat -CommandType Application) @a } else { Write-Warning 'bat not found' } } -Force | Out-Null
}

# fd - find files and directories
if (-not (Test-Path Function:fd -ErrorAction SilentlyContinue)) {
    # Use Get-Command to check for external fd command specifically
    Set-Item -Path Function:fd -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command fd -CommandType Application -ErrorAction SilentlyContinue) { & (Get-Command fd -CommandType Application) @a } else { Write-Warning 'fd not found' } } -Force | Out-Null
}

# http - command-line HTTP client
if (-not (Test-Path Function:http -ErrorAction SilentlyContinue)) {
    # Use Get-Command to check for external http command specifically
    Set-Item -Path Function:http -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command http -CommandType Application -ErrorAction SilentlyContinue) { & (Get-Command http -CommandType Application) @a } else { Write-Warning 'httpie (http) not found' } } -Force | Out-Null
}

# zoxide - smarter cd command
if (-not (Test-Path Function:zoxide -ErrorAction SilentlyContinue)) {
    # Use Get-Command to check for external zoxide command specifically
    Set-Item -Path Function:zoxide -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue) { & (Get-Command zoxide -CommandType Application) @a } else { Write-Warning 'zoxide not found' } } -Force | Out-Null
}

# delta - syntax-highlighting pager for git
if (-not (Test-Path Function:delta -ErrorAction SilentlyContinue)) {
    # Use Get-Command to check for external delta command specifically
    Set-Item -Path Function:delta -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command delta -CommandType Application -ErrorAction SilentlyContinue) { & (Get-Command delta -CommandType Application) @a } else { Write-Warning 'delta not found' } } -Force | Out-Null
}

# tldr - simplified man pages
if (-not (Test-Path Function:tldr -ErrorAction SilentlyContinue)) {
    # Use Get-Command to check for external tldr command specifically
    Set-Item -Path Function:tldr -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command tldr -CommandType Application -ErrorAction SilentlyContinue) { & (Get-Command tldr -CommandType Application) @a } else { Write-Warning 'tldr not found' } } -Force | Out-Null
}

# procs - modern replacement for ps
if (-not (Test-Path Function:procs -ErrorAction SilentlyContinue)) {
    # Use Get-Command to check for external procs command specifically
    Set-Item -Path Function:procs -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command procs -CommandType Application -ErrorAction SilentlyContinue) { & (Get-Command procs -CommandType Application) @a } else { Write-Warning 'procs not found' } } -Force | Out-Null
}

# dust - more intuitive du command
if (-not (Test-Path Function:dust -ErrorAction SilentlyContinue)) {
    # Use Get-Command to check for external dust command specifically
    Set-Item -Path Function:dust -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command dust -CommandType Application -ErrorAction SilentlyContinue) { & (Get-Command dust -CommandType Application) @a } else { Write-Warning 'dust not found' } } -Force | Out-Null
}
