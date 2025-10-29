# ===============================================
# 54-modern-cli.ps1
# Modern CLI tools helpers (guarded)
# ===============================================

<#
Register modern CLI tools helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# bat - cat clone with syntax highlighting and Git integration
if (-not (Test-Path Function:bat -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:bat -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command bat -ErrorAction SilentlyContinue) { bat @a } else { Write-Warning 'bat not found' } } -Force | Out-Null
}

# fd - find files and directories
if (-not (Test-Path Function:fd -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:fd -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command fd -ErrorAction SilentlyContinue) { fd @a } else { Write-Warning 'fd not found' } } -Force | Out-Null
}

# http - command-line HTTP client
if (-not (Test-Path Function:http -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:http -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command http -ErrorAction SilentlyContinue) { http @a } else { Write-Warning 'httpie (http) not found' } } -Force | Out-Null
}

# zoxide - smarter cd command
if (-not (Test-Path Function:zoxide -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:zoxide -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command zoxide -ErrorAction SilentlyContinue) { zoxide @a } else { Write-Warning 'zoxide not found' } } -Force | Out-Null
}

# delta - syntax-highlighting pager for git
if (-not (Test-Path Function:delta -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:delta -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command delta -ErrorAction SilentlyContinue) { delta @a } else { Write-Warning 'delta not found' } } -Force | Out-Null
}

# tldr - simplified man pages
if (-not (Test-Path Function:tldr -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:tldr -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command tldr -ErrorAction SilentlyContinue) { tldr @a } else { Write-Warning 'tldr not found' } } -Force | Out-Null
}

# procs - modern replacement for ps
if (-not (Test-Path Function:procs -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:procs -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command procs -ErrorAction SilentlyContinue) { procs @a } else { Write-Warning 'procs not found' } } -Force | Out-Null
}

# dust - more intuitive du command
if (-not (Test-Path Function:dust -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:dust -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Get-Command dust -ErrorAction SilentlyContinue) { dust @a } else { Write-Warning 'dust not found' } } -Force | Out-Null
}
