# ===============================================
# 56-database.ps1
# Database tools helpers (guarded)
# ===============================================

<#
Register database tools helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# PostgreSQL client - connect to PostgreSQL databases
if (-not (Test-Path Function:psql -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:psql -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand psql) { psql @a } else { Write-Warning 'psql not found' } } -Force | Out-Null
}

# MySQL client - connect to MySQL databases
if (-not (Test-Path Function:mysql -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:mysql -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand mysql) { mysql @a } else { Write-Warning 'mysql not found' } } -Force | Out-Null
}

# MongoDB shell - interact with MongoDB databases
if (-not (Test-Path Function:mongosh -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:mongosh -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand mongosh) { mongosh @a } else { Write-Warning 'mongosh not found' } } -Force | Out-Null
}

# Redis CLI - command-line interface for Redis
if (-not (Test-Path Function:redis-cli -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:redis-cli -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand redis-cli) { redis-cli @a } else { Write-Warning 'redis-cli not found' } } -Force | Out-Null
}

# SQLite CLI - command-line interface for SQLite databases
if (-not (Test-Path Function:sqlite3 -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:sqlite3 -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-HasCommand sqlite3) { sqlite3 @a } else { Write-Warning 'sqlite3 not found' } } -Force | Out-Null
}
