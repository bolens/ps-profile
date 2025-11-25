<#
# 06-oh-my-posh.ps1

Idempotent initialization for oh-my-posh prompt framework.

This fragment checks for the `oh-my-posh` command and runs the same
initialization that used to live in the main profile. It is quiet and
idempotent.
#>

try {
    # Define lazy initializer for oh-my-posh to keep profile startup fast.
    # The prompt proxy function calls Initialize-OhMyPosh on first prompt draw,
    # deferring initialization until actually needed.
    if (-not (Test-Path Function:Initialize-OhMyPosh -ErrorAction SilentlyContinue)) {
        <#
        .SYNOPSIS
            Initializes oh-my-posh prompt framework lazily.
        .DESCRIPTION
            Checks for oh-my-posh command availability and initializes the prompt
            framework by running the shell init script. This is called lazily to
            avoid slowing down profile startup.
        #>
        function Initialize-OhMyPosh {
            try {
                if ($null -ne (Get-Variable -Name 'OhMyPoshInitialized' -Scope Global -ErrorAction SilentlyContinue)) { return }

                $ohCmd = Get-Command oh-my-posh -ErrorAction SilentlyContinue
                if (-not $ohCmd) { return }

                # oh-my-posh generates a shell init script via `init pwsh --print`.
                # We write it to a temp file and dot-source it (instead of using Invoke-Expression)
                # to satisfy PSScriptAnalyzer security rules and allow proper error handling.
                $temp = [System.IO.Path]::GetTempFileName() + '.ps1'
                try {
                    # Execute oh-my-posh init command and capture output
                    $initOutput = & $ohCmd.Source init pwsh --print 2>&1
                    $exitCode = $LASTEXITCODE
                    
                    if ($exitCode -ne 0) {
                        throw "oh-my-posh init command failed with exit code $exitCode"
                    }
                    
                    # Validate that we received output
                    if (-not $initOutput -or ($initOutput | Measure-Object).Count -eq 0) {
                        throw "oh-my-posh init command produced no output"
                    }
                    
                    # Write init script to temp file
                    try {
                        $initOutput | Out-File -FilePath $temp -Encoding UTF8 -ErrorAction Stop
                    }
                    catch {
                        throw "Failed to write oh-my-posh init script to temp file: $($_.Exception.Message)"
                    }
                    
                    # Execute the init script
                    if (Test-Path $temp -ErrorAction SilentlyContinue) {
                        try {
                            . $temp
                        }
                        catch {
                            throw "Failed to execute oh-my-posh init script: $($_.Exception.Message)"
                        }
                    }
                    else {
                        throw "Temp file was not created: $temp"
                    }
                }
                finally {
                    # Always clean up temp file, even if initialization fails
                    if (Test-Path $temp -ErrorAction SilentlyContinue) {
                        try {
                            Remove-Item $temp -Force -ErrorAction Stop
                        }
                        catch {
                            if ($env:PS_PROFILE_DEBUG) {
                                Write-Warning "Failed to clean up temp file '$temp': $($_.Exception.Message)"
                            }
                        }
                    }
                }
                Set-Variable -Name 'OhMyPoshInitialized' -Value $true -Scope Global -Force
                if ($env:PS_PROFILE_DEBUG) { Write-Verbose "oh-my-posh initialized via $($ohCmd.Source)" }
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Initialize-OhMyPosh failed: $($_.Exception.Message)" }
            }
        }
    }

    # Only install proxy prompt if no Prompt function exists (don't override existing configuration)
    if (Get-Command -Name prompt -CommandType Function -ErrorAction SilentlyContinue) {
        return
    }
    
    # If Starship is available, let it handle prompt initialization (loaded by 23-starship.ps1)
    # Starship and oh-my-posh are mutually exclusive prompt frameworks
    if (Test-HasCommand starship) {
        if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship detected, skipping oh-my-posh proxy prompt" -ForegroundColor Cyan }
        return
    }

    # Create proxy prompt function that lazy-loads oh-my-posh on first invocation.
    # After initialization, delegates to the real prompt function registered by oh-my-posh.
    # Uses ScriptBlock comparison to detect when oh-my-posh has registered its own prompt.
    <#
    .SYNOPSIS
        PowerShell prompt function with lazy oh-my-posh initialization.
    .DESCRIPTION
        This prompt function initializes oh-my-posh on first invocation and then
        delegates to the real prompt function registered by oh-my-posh. Falls back
        to a minimal prompt if initialization fails.
    #>
    function prompt {
        $ohInit = $false
        try { $ohInit = $null -ne (Get-Variable -Name 'OhMyPoshInitialized' -Scope Global -ErrorAction SilentlyContinue) } catch { $ohInit = $false }
        if (-not $ohInit) { Initialize-OhMyPosh }

        # Initialize Starship if available (some themes may depend on it)
        if (Get-Command -Name Initialize-Starship -ErrorAction SilentlyContinue) {
            try { 
                & Initialize-Starship 
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: 06-oh-my-posh (Initialize-Starship)" -Category 'Fragment'
                    }
                    else {
                        Write-Verbose "Failed to initialize Starship from oh-my-posh fragment: $($_.Exception.Message)"
                    }
                }
            }
        }

        # Check if oh-my-posh registered a new Prompt function and delegate to it
        # Compare ScriptBlocks to detect when oh-my-posh has replaced our proxy
        $cmd = Get-Command -Name prompt -CommandType Function -ErrorAction SilentlyContinue
        try {
            if ($cmd -and $cmd.ScriptBlock -and $cmd.ScriptBlock -ne $function:Prompt.ScriptBlock) {
                return & $cmd.ScriptBlock
            }
        }
        catch {
            # If delegation fails, fall back to minimal prompt (don't break interactive session)
            if ($env:PS_PROFILE_DEBUG) {
                Write-Verbose "Failed to invoke registered prompt function: $($_.Exception.Message)"
            }
        }

        # Fallback: minimal prompt if oh-my-posh initialization failed or no prompt was registered
        $user = $env:USERNAME
        $hostName = $env:COMPUTERNAME
        $cwd = (Get-Location).Path
        return "$user@$hostName $cwd > "
    }

}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "oh-my-posh fragment failed: $($_.Exception.Message)" }
}
