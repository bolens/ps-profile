<#
# 06-oh-my-posh.ps1

Idempotent initialization for oh-my-posh prompt framework.

This fragment checks for the `oh-my-posh` command and runs the same
initialization that used to live in the main profile. It is quiet and
idempotent.
#>

try {
    # If oh-my-posh isn't present, do nothing. If it is present, avoid
    # initializing it at profile-load time (which can be slow) and instead
    # lazily initialize on the first prompt draw. This keeps startup snappy
    # while preserving identical prompt behavior for users who rely on
    # oh-my-posh.
    if ($null -ne (Get-Variable -Name 'OhMyPoshInitialized' -Scope Global -ErrorAction SilentlyContinue)) { return }

    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) { return }

    # Don't override an existing Prompt function defined elsewhere; only
    # install our lazy proxy when no Prompt is present.
    if (Get-Command -Name prompt -CommandType Function -ErrorAction SilentlyContinue) {
        # A Prompt function already exists; let the existing configuration win.
        return
    }

    # oh-my-posh initialization function
    function Initialize-OhMyPosh {
        try {
            # oh-my-posh prints a shell init script; write it to a temp file and
            # dot-source that file to avoid using Invoke-Expression (PSScriptAnalyzer flag).
            $temp = [System.IO.Path]::GetTempFileName() + '.ps1'
            try {
                $null = oh-my-posh init pwsh --print 2>$null | Out-File -FilePath $temp -Encoding UTF8
                if (Test-Path $temp) { .$temp }
            }
            finally {
                if (Test-Path $temp) { Remove-Item $temp -Force -ErrorAction SilentlyContinue }
            }
            Set-Variable -Name 'OhMyPoshInitialized' -Value $true -Scope Global -Force
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Initialize-OhMyPosh failed: $($_.Exception.Message)" }
        }
    }

    # Proxy prompt: on first invocation initialize oh-my-posh, then invoke the
    # real prompt function that oh-my-posh registers. Comparison uses the
    # ScriptBlock object to avoid simple textual recursion.
    function prompt {
        $ohInit = $false
        try { $ohInit = $null -ne (Get-Variable -Name 'OhMyPoshInitialized' -Scope Global -ErrorAction SilentlyContinue) } catch { $ohInit = $false }
        if (-not $ohInit) { Initialize-OhMyPosh }

        # If starship lazy-initializer is defined, invoke it so themes that
        # rely on starship can register their prompt elements before we
        # attempt to hand off to the real Prompt.
        if (Get-Command -Name Initialize-Starship -ErrorAction SilentlyContinue) {
            try { & Initialize-Starship } catch {}
        }

        # After initialization, see if a new Prompt function exists and call it.
        $cmd = Get-Command -Name prompt -CommandType Function -ErrorAction SilentlyContinue
        try {
            if ($cmd -and $cmd.ScriptBlock -and $cmd.ScriptBlock -ne $function:Prompt.ScriptBlock) {
                return & $cmd.ScriptBlock
            }
        }
        catch {
            # If invoking the registered prompt fails for any reason, fall back to a
            # minimal prompt string. We swallow exceptions to keep interactive flow.
        }

        # Fallback minimal prompt
        $user = $env:USERNAME
        $hostName = $env:COMPUTERNAME
        $cwd = (Get-Location).Path
        return "$user@$hostName $cwd > "
    }

}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "oh-my-posh fragment failed: $($_.Exception.Message)" }
}








