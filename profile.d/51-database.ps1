# ===============================================
# 51-database.ps1
# Database tools helpers (guarded)
# ===============================================

<#
Register database tools helpers lazily. Avoid expensive Get-Command probes at dot-source.
#>

# PostgreSQL client - connect to PostgreSQL databases
if (-not (Test-Path Function:psql -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:psql -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand psql) { psql @a } else { Write-Warning 'psql (PostgreSQL) not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:psql -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if ($null -ne (Get-Command psql -ErrorAction SilentlyContinue)) { psql @a } else { Write-Warning 'psql (PostgreSQL) not found' } } -Force | Out-Null
  }
}

# MySQL client - connect to MySQL databases
if (-not (Test-Path Function:mysql -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:mysql -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand mysql) { mysql @a } else { Write-Warning 'mysql not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:mysql -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if ($null -ne (Get-Command mysql -ErrorAction SilentlyContinue)) { mysql @a } else { Write-Warning 'mysql not found' } } -Force | Out-Null
  }
}

# MongoDB shell - interact with MongoDB databases
if (-not (Test-Path Function:mongosh -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:mongosh -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand mongosh) { mongosh @a } else { Write-Warning 'mongosh (MongoDB) not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:mongosh -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if ($null -ne (Get-Command mongosh -ErrorAction SilentlyContinue)) { mongosh @a } else { Write-Warning 'mongosh (MongoDB) not found' } } -Force | Out-Null
  }
}

# Redis CLI - command-line interface for Redis
if (-not (Test-Path Function:redis-cli -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:redis-cli -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand redis-cli) { redis-cli @a } else { Write-Warning 'redis-cli not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:redis-cli -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if ($null -ne (Get-Command redis-cli -ErrorAction SilentlyContinue)) { redis-cli @a } else { Write-Warning 'redis-cli not found' } } -Force | Out-Null
  }
}

# SQLite CLI - command-line interface for SQLite databases
if (-not (Test-Path Function:sqlite3 -ErrorAction SilentlyContinue)) {
  if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
    Set-Item -Path Function:sqlite3 -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if (Test-CachedCommand sqlite3) { sqlite3 @a } else { Write-Warning 'sqlite3 not found' } } -Force | Out-Null
  } else {
    Set-Item -Path Function:sqlite3 -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) if ($null -ne (Get-Command sqlite3 -ErrorAction SilentlyContinue)) { sqlite3 @a } else { Write-Warning 'sqlite3 not found' } } -Force | Out-Null
  }
}
