# ===============================================
# 53-go.ps1
# Go programming language helpers (guarded)
# ===============================================

<#
Register Go helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# Go run wrapper - run Go programs
if (-not (Test-Path Function:go-run -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:go-run -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand go) { go run @a } else { Write-Warning 'Go not found' } } -Force | Out-Null
}

# Go build wrapper - compile Go programs
if (-not (Test-Path Function:go-build -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:go-build -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand go) { go build @a } else { Write-Warning 'Go not found' } } -Force | Out-Null
}

# Go module management - manage Go modules
if (-not (Test-Path Function:go-mod -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:go-mod -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand go) { go mod @a } else { Write-Warning 'Go not found' } } -Force | Out-Null
}

# Go test runner - run Go tests
if (-not (Test-Path Function:go-test -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:go-test -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand go) { go test @a } else { Write-Warning 'Go not found' } } -Force | Out-Null
}
