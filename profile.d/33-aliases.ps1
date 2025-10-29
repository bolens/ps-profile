<#
# 33-aliases.ps1

Register user aliases and small interactive helper functions in an
idempotent, non-destructive way.
#>

try {
    if ($null -ne (Get-Variable -Name 'AliasesLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    # Alias registration is done on-demand to keep dot-source cheap.
    # We expose Enable-Aliases which will create the function/alias
    # definitions when called. This keeps startup fast and preserves
    # behavior for interactive use when the user asks for aliases.

    if (-not (Test-Path 'Function:Enable-Aliases')) {
        # Instrumentation: measure how long function registration takes and append to a CSV
        try {
            $instrumentDir = Join-Path $PSScriptRoot '..\scripts\data'
            $instrumentPath = Join-Path $instrumentDir 'alias-instrument.csv'
            if (-not (Test-Path $instrumentDir)) { New-Item -ItemType Directory -Path $instrumentDir -Force | Out-Null }
            if (-not (Test-Path $instrumentPath)) { 'Timestamp,Event,Ms' | Out-File -FilePath $instrumentPath -Encoding utf8 }
        }
        catch {
            # Fall back to no-op if workspace layout is different
            $instrumentPath = $null
        }

        # Optional per-step timings (enable by setting PS_PROFILE_DEBUG_TIMINGS=1)
        $testStart = [datetime]::UtcNow
        $exists = Test-Path 'Function:Enable-Aliases'
        $testMs = ([datetime]::UtcNow - $testStart).TotalMilliseconds

        if (-not $exists) {
            $createStart = [datetime]::UtcNow
            New-Item -Path 'Function:Enable-Aliases' -Value {
                param()
                try {
                    if (-not (Get-Variable -Name 'AliasesLoaded' -Scope Global -ErrorAction SilentlyContinue)) {
                        if (-not (Test-Path Function:ll -ErrorAction SilentlyContinue) -and -not (Test-Path Alias:ll -ErrorAction SilentlyContinue)) {
                            # List directory contents - enhanced ls
                            Set-Item -Path Function:ll -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) Get-ChildItem @a } -Force | Out-Null
                        }
                        if (-not (Test-Path Function:la -ErrorAction SilentlyContinue) -and -not (Test-Path Alias:la -ErrorAction SilentlyContinue)) {
                            # List all directory contents - enhanced ls -a
                            Set-Item -Path Function:la -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) Get-ChildItem -Force @a } -Force | Out-Null
                        }
                        if (-not (Test-Path Function:Show-Path -ErrorAction SilentlyContinue) -and -not (Test-Path Alias:Show-Path -ErrorAction SilentlyContinue)) {
                            # Show PATH entries as an array
                            Set-Item -Path Function:Show-Path -Value { $env:Path -split ';' | Where-Object { $_ } } -Force | Out-Null
                        }
                        Set-Variable -Name 'AliasesLoaded' -Value $true -Scope Global -Force
                    }
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Enable-Aliases failed: $($_.Exception.Message)" }
                }
            } -Force | Out-Null
            $createMs = ([datetime]::UtcNow - $createStart).TotalMilliseconds
        }
        else {
            $createMs = 0
        }
        if ($instrumentPath) {
            try { Add-Content -Path $instrumentPath -Value ("{0},{1},{2}" -f (Get-Date -Format o), 'Enable-Aliases:Create', [math]::Round($createMs, 2)) -Encoding utf8 } catch {}
            if ($env:PS_PROFILE_DEBUG_TIMINGS -eq '1') {
                try { Add-Content -Path $instrumentPath -Value ("{0},{1},{2}" -f (Get-Date -Format o), 'Enable-Aliases:TestPath', [math]::Round($testMs, 2)) -Encoding utf8 } catch {}
            }
        }
    }

    # Optionally auto-enable aliases in interactive sessions when explicitly requested
    if ($env:PS_PROFILE_AUTOENABLE_ALIASES -eq '1') { Enable-Aliases }

    Set-Variable -Name 'AliasesLoaded' -Value $true -Scope Global -Force
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Aliases fragment failed: $($_.Exception.Message)" }
}










